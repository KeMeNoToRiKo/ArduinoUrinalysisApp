//
//  BLEConnectionState.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/13/26.
//


// MARK: - BLE CONNECTION STATE
enum BLEConnectionState: Equatable{
    case unknown
    case idle
    case scanning
    case connecting
    case connected(peripheralName: String)
    case disconnected
    case poweredOff
    case unauthorized
    case unsupported

    static func == (lhs: BLEConnectionState, rhs: BLEConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown), (.idle, .idle), (.scanning, .scanning),
             (.connecting, .connecting), (.disconnected, .disconnected),
             (.poweredOff, .poweredOff), (.unauthorized, .unauthorized),
             (.unsupported, .unsupported): return true
        case (.connected(let a), .connected(let b)): return a == b
        default: return false
        }
    }
}
