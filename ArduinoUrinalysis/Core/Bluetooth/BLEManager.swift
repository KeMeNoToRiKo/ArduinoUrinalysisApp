//
//  BLEManager.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/13/26.
//

import Foundation
import CoreBluetooth
import Combine






// ========================================
// MARK: - BLE MANAGER
// ========================================
final class BLEManager: NSObject, ObservableObject {
    
    @Published var connectionState: BLEConnectionState = .unknown
    @Published var discoveredPeripherals: [DiscoveredPeripheral] = []
    @Published var isScanning: Bool = false
    
    private var centralManager: CBCentralManager!
    private(set) var connectedPeripheral: CBPeripheral?
    
    var exposedPeripheral: CBPeripheral? {
        connectedPeripheral
    }
    private var pendingScan: Bool = false
    
    // This will allow us to filter devices to easily find arduino
    private let scanOptions: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: false]
    
    override init() {
        super.init()
        centralManager = CBCentralManager(
            delegate: self,
            queue: .main,
            options: [CBCentralManagerOptionShowPowerAlertKey: true]
        )
    }
    
    // MARK: - APIS
    
    func startScanning() {
        print("[BLE] startScanning called — central state: \(centralManager.state.rawValue)")
        switch centralManager.state {
        case .poweredOn:
            performScan()
        case .unknown, .resetting:
            pendingScan = true
            connectionState = .scanning
        case .poweredOff:
            connectionState = .poweredOff
        case .unauthorized:
            connectionState = .unauthorized
        case .unsupported:
            connectionState = .unsupported
        @unknown default:
            pendingScan = true
        }
    }
    
    func stopScanning() {
        pendingScan = false
        guard isScanning else { return }
        centralManager.stopScan()
        isScanning = false
        if case .scanning = connectionState { connectionState = .idle }
    }
    
    func connect(to discovered: DiscoveredPeripheral) {
        stopScanning()
        connectionState = .connecting
        connectedPeripheral = discovered.peripheral
        centralManager.connect(discovered.peripheral, options: nil)
    }
    
    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    var isConnected: Bool {
        if case .connected = connectionState { return true }
        return false
    }
    
    var connectedName: String? {
        if case .connected(let name) = connectionState { return name }
        return nil
    }
    
    // MARK: - PRIVATE FUNC
    private func performScan() {
        print("[BLE] >>> Start scanning")
        discoveredPeripherals = []
        isScanning = true
        connectionState = .scanning
        centralManager.scanForPeripherals(withServices: nil, options: scanOptions)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) { [weak self] in guard let self, self.isScanning else { return }
            print("[BLE] >>> Stopped scanning after 5s - found\(self.discoveredPeripherals.count) devices")
            self.stopScanning()
        }
    }
    
    /// Resolve the best available name from peripheral and advertisement data.
    /// Arduino BLE puts the name in CBAdvertisementDataLocalNameKey on the scan response,
    /// which arrives as a separate (duplicate) advertisement packet.
    private func resolveName(peripheral: CBPeripheral, advertisementData: [String: Any]) -> String? {
        if let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String,
            !localName.isEmpty {
            return localName
        }
        if let name = peripheral.name, !name.isEmpty {
            return name
        }
        return nil
    }
    
}


// MARK: - DELEGATES

// This function updates the BLE State
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(
        _ central: CBCentralManager
    ) {
        print("[BLE] centralManagerDidUpdateState: \(central.state.rawValue)")
        switch central.state {
        case .poweredOn:
            if pendingScan {
                pendingScan = false
                performScan()
            } else {
                if case .unknown = connectionState { connectionState = .idle }
                if case .poweredOff = connectionState { connectionState = .idle }
            }
        case .poweredOff:
            isScanning = false
            pendingScan = false
            connectionState = .poweredOff
        case .unauthorized:
            connectionState = .unauthorized
        case .unsupported:
            connectionState = .unsupported
        case .resetting, .unknown:
            break
        @unknown default:
            break
        }

    }
    
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let rssiValue = RSSI.intValue
        let resolvedName = resolveName(peripheral: peripheral, advertisementData: advertisementData)
        print("[BLE] didDiscover — uuid: \(peripheral.identifier), name: \(resolvedName ?? "nil"), rssi: \(rssiValue), advData keys: \(advertisementData.keys.joined(separator: ", "))")

        // Ignore implausibly weak signals (too far or noise)
        guard rssiValue < 0 && rssiValue > -100 else { return }


        if let index = discoveredPeripherals.firstIndex(where: { $0.id == peripheral.identifier }) {
            // Device already in list — update RSSI and name if we now have one
            discoveredPeripherals[index].rssi = rssiValue
            if let name = resolvedName, ((discoveredPeripherals[index].name?.hasPrefix("Unknown")) != nil) {
                discoveredPeripherals[index].name = name
            }
        } else {
            // New device — add it even if nameless (shows as "Unknown Device")
            // so the Arduino isn't silently dropped on the first unnamed packet
            let displayName = resolvedName ?? "Unknown Device (\(peripheral.identifier.uuidString.prefix(8)))"
            let discovered = DiscoveredPeripheral(
                id: peripheral.identifier,
                peripheral: peripheral,
                name: displayName,
                rssi: rssiValue
            )
            discoveredPeripherals.append(discovered)
        }

        // Re-sort by signal strength
        discoveredPeripherals.sort { $0.rssi > $1.rssi }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionState = .connected(peripheralName: peripheral.name ?? "Arduino Device")
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionState = .disconnected
        connectedPeripheral = nil
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionState = .disconnected
        connectedPeripheral = nil
    }
}

