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

    /// Set to `true` when the Arduino (or simulation) signals that a test has started.
    /// WaitingForDeviceView watches this to advance the flow.
    @Published var testStarted: Bool = false

    /// Bumped on every successfully parsed BLE sensor-data packet.
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

    /// Called by WaitingForDeviceView in sim mode.
    /// Simulates the Arduino pressing the physical button and emitting a "test_started" packet.
    func simulateTestStart(after delay: TimeInterval = 2.5) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            self.testStarted = true
            self.statusMessage = "Test started (simulated)"
        }
    }

    /// Resets the testStarted flag — call this when returning to the main menu
    /// so the next test cycle works correctly.
    func resetTestStarted() {
        testStarted = false
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
        // First, check if this is a control packet (e.g. test_started) rather than sensor data.
        if let controlPayload = try? JSONDecoder().decode(ControlPayload.self, from: data) {
            if controlPayload.type == "test_started" {
                DispatchQueue.main.async {
                    self.testStarted = true
                    self.statusMessage = "Test started — \(controlPayload.device)"
                }
                print("[Sensor] Received test_started signal from \(controlPayload.device)")
                return
            }
        }

        // Otherwise try to decode it as a full sensor reading.
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

// MARK: - Minimal control-packet model
// The Arduino sends { "device": "...", "type": "test_started" } when the button is pressed.
private struct ControlPayload: Decodable {
    let device: String
    let type: String
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
