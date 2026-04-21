//
//  SensorDataManager.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/13/26.
//



import Foundation
import Combine
import CoreBluetooth
import SwiftUI

// MARK: - JSON Payload Models

private struct ArduinoPayload: Decodable {
    let device: String
    let version: String
    let type: String
    let sensors: SensorBlock
}


private struct SensorBlock: Decodable {
    let temp_c: Double   // Changed from String
    let pH: Double       // Changed from String
    let tds_ppm: Double  // Changed from String
    let ec_us_cm: Double // Changed from String
    let color: ColorBlock
}

private struct ColorBlock: Decodable {
    let r: Int
    let g: Int
    let b: Int
    let hex: String
    let lux: Double      // Changed from String
    let cct: Int
}

// MARK: - UrinalysisReading (parsed, display-ready)

struct UrinalysisReading {
    let device: String
    let timestamp: Date

    let tempC: Double
    let pH: Double
    let tdsPPM: Double
    let ecUSCm: Double

    let colorR: Int
    let colorG: Int
    let colorB: Int
    let colorHex: String
    let lux: Double
    let cct: Int

    // MARK: Display strings
    var tempDisplay: String      { String(format: "%.1f°C", tempC) }
    var phDisplay: String        { String(format: "%.2f", pH) }
    var tdsDisplay: String       { "\(Int(tdsPPM)) ppm" }
    var ecDisplay: String        { String(format: "%.1f µS/cm", ecUSCm) }
    var luxDisplay: String       { String(format: "%.0f lx", lux) }
    var cctDisplay: String       { "\(cct) K" }
    var colorSwiftUI: Color      { Color(red: Double(colorR)/255, green: Double(colorG)/255, blue: Double(colorB)/255) }

    // MARK: Derived interpretations
    var hydrationPercent: Double {
        // Estimate hydration from TDS: lower TDS = better hydrated
        // Normal urine TDS: 200–1200 ppm. Map to 0–100% inversely.
        let clamped = max(200, min(1200, tdsPPM))
        return (1 - (clamped - 200) / 1000) * 100
    }
    var hydrationDisplay: String { "\(Int(hydrationPercent))%" }

    var hydrationStatus: String {
        switch hydrationPercent {
        case 75...:  return "Well Hydrated"
        case 50..<75: return "Mildly Dehydrated"
        default:     return "Dehydrated"
        }
    }

    var phStatus: String {
        switch pH {
        case ..<4.5: return "Very Acidic"
        case 4.5..<6.0: return "Acidic"
        case 6.0..<7.5: return "Normal"
        case 7.5..<8.5: return "Slightly Alkaline"
        default: return "Very Alkaline"
        }
    }

    // MARK: - Parse from raw JSON data
    static func from(data: Data) -> UrinalysisReading? {
        do {
            let payload = try JSONDecoder().decode(ArduinoPayload.self, from: data)
            let s = payload.sensors
            
            return UrinalysisReading(
                device:    payload.device,
                timestamp: Date(),
                tempC:     s.temp_c,      // No more Double() casting needed
                pH:        s.pH,
                tdsPPM:    s.tds_ppm,
                ecUSCm:    s.ec_us_cm,
                colorR:    s.color.r,
                colorG:    s.color.g,
                colorB:    s.color.b,
                colorHex:  s.color.hex,
                lux:       s.color.lux,
                cct:       s.color.cct
            )
        } catch {
            print("[Sensor] Decoding error: \(error)") // This will tell you exactly what failed
            return nil
        }
    }

    // MARK: - Simulated reading
    static func simulated() -> UrinalysisReading {
        let tds = Double.random(in: 200...900)
        let ph  = Double.random(in: 5.5...7.5)
        let ec  = tds * 2.0
        let r   = Int.random(in: 180...230)
        let g   = Int.random(in: 160...200)
        let b   = Int.random(in: 60...110)
        return UrinalysisReading(
            device:    "URINE-TEST-001",
            timestamp: Date(),
            tempC:     Double.random(in: 23...37),
            pH:        ph,
            tdsPPM:    tds,
            ecUSCm:    ec,
            colorR:    r,
            colorG:    g,
            colorB:    b,
            colorHex:  String(format: "#%02X%02X%02X", r, g, b),
            lux:       Double.random(in: 800...1600),
            cct:       Int.random(in: 2800...4000)
        )
    }
}

// MARK: - SensorDataManager

final class SensorDataManager: NSObject, ObservableObject {

    @Published var latestReading: UrinalysisReading? = nil
    @Published var isReceivingData: Bool = false
    @Published var simulatedMode: Bool = true
    @Published var statusMessage: String = "No data yet"
    /// Bumped on every successfully parsed BLE packet.
    /// UrinalysisFlowView watches this instead of latestReading?.timestamp
    /// so it always fires, even if sensor values are unchanged.
    @Published var lastBLEPacketDate: Date? = nil

    // The Arduino sends all sensor data as a single JSON blob on one characteristic.
    // Replace this UUID with the actual characteristic UUID from your Arduino sketch.
    static let dataCharacteristicUUID = CBUUID(string: "2A37")

    private var simulationTimer: Timer?
    private var peripheral: CBPeripheral?

    // Buffer for reassembling BLE packets that may be split across MTU boundaries
    private var receiveBuffer = Data()

    // MARK: - Simulated Mode

    func startSimulation() {
        simulatedMode = true
        isReceivingData = true
        statusMessage = "Simulated data active"
        simulationTimer?.invalidate()
        emitSimulated()
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.emitSimulated()
        }
    }

    func stopSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        isReceivingData = false
        statusMessage = "Simulation stopped"
    }

    private func emitSimulated() {
        DispatchQueue.main.async {
            self.latestReading = UrinalysisReading.simulated()
        }
    }

    // MARK: - BLE Mode

    func attachPeripheral(_ peripheral: CBPeripheral) {
        simulatedMode = false
        stopSimulation()
        self.peripheral = peripheral
        peripheral.delegate = self
        // Discover all services — we'll filter for our characteristic in the delegate
        peripheral.discoverServices(nil)
        statusMessage = "Discovering services…"
    }

    func detachPeripheral() {
        peripheral?.delegate = nil
        peripheral = nil
        receiveBuffer.removeAll()
        isReceivingData = false
        statusMessage = "Disconnected"
    }

    // MARK: - JSON parsing

    private func parseAndEmit(_ data: Data) {
        if let reading = UrinalysisReading.from(data: data) {
            DispatchQueue.main.async {
                self.latestReading = reading
                self.lastBLEPacketDate = reading.timestamp   // always a fresh Date()
                self.isReceivingData = true
                self.statusMessage = "Live data — \(reading.device)"
            }
        } else {
            let raw = String(data: data, encoding: .utf8) ?? "<binary>"
            print("[Sensor] JSON parse failed. Raw: \(raw)")
        }
    }
}

// MARK: - CBPeripheralDelegate

extension SensorDataManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            statusMessage = "Service discovery failed"
            return
        }
        print("[Sensor] Discovered \(peripheral.services?.count ?? 0) service(s):")
        peripheral.services?.forEach { service in
            print("[Sensor]   Service UUID: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else { return }
        print("[Sensor] Characteristics for service \(service.uuid):")
        service.characteristics?.forEach { characteristic in
            print("[Sensor]   Characteristic UUID: \(characteristic.uuid) | properties: \(characteristic.properties.rawValue)")
            // Subscribe to ALL notifiable characteristics so we catch the right one
            // regardless of UUID — remove this once the correct UUID is confirmed
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
                print("[Sensor]   -> subscribed to \(characteristic.uuid)")
            } else if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
                print("[Sensor]   -> reading \(characteristic.uuid)")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value else { return }

        print("[Sensor] Data received on characteristic: \(characteristic.uuid) — \(data.count) bytes")
        print("[Sensor] Raw string: \(String(data: data, encoding: .utf8) ?? "<non-utf8>")")

        receiveBuffer.append(data)

        if let raw = String(data: receiveBuffer, encoding: .utf8), raw.contains("}") {
            if let jsonData = extractJSON(from: receiveBuffer) {
                // Once we see data coming through, lock in this UUID as the data characteristic
                print("[Sensor] Valid JSON received on \(characteristic.uuid) — use this UUID in dataCharacteristicUUID")
                parseAndEmit(jsonData)
            }
            receiveBuffer.removeAll()
        }
    }

    /// Finds the first complete `{ ... }` block in the buffer.
    private func extractJSON(from data: Data) -> Data? {
        guard let str = String(data: data, encoding: .utf8) else { return nil }
        var depth = 0
        var start: String.Index? = nil
        for i in str.indices {
            if str[i] == "{" {
                if depth == 0 { start = i }
                depth += 1
            } else if str[i] == "}" {
                depth -= 1
                if depth == 0, let s = start {
                    let slice = String(str[s...i])
                    return slice.data(using: .utf8)
                }
            }
        }
        return nil
    }
}
