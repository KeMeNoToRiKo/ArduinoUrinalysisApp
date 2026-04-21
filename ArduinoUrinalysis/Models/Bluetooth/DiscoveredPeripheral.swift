//
//  DiscoveredPeripheral.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/13/26.
//
import CoreBluetooth

// MARK: - Discovered Bluetooth Model
struct DiscoveredPeripheral: Identifiable {
    let id: UUID
    let peripheral: CBPeripheral
    var name: String?
    var rssi: Int
    
    var signalPercent: Int {
        let clamped = max(-100, min(-40, rssi))
        return Int(Double(clamped + 100) / 60.0 * 100)
    }

}
