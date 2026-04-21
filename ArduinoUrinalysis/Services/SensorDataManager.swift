//
//  SensorDataManager.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/13/26.
//

import Foundation
import Combine
import CoreBluetooth

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
        simulatedMode = false
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
