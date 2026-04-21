//
//  ArduinoUrinalysisApp.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 2/12/26.
//

//
//  ArduinoUrinalysisApp.swift
//  ArduinoUrinalysis
//

import SwiftUI
import SwiftData

@main
struct ArduinoUrinalysisApp: App {
    @AppStorage("disclaimerAccepted") private var disclaimerAccepted: Bool = false
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @State private var splashFinished: Bool = false

    @StateObject private var bleManager = BLEManager()
    @StateObject private var sensorData = SensorDataManager()

    var body: some Scene {
        WindowGroup {
            
            if !splashFinished {
                SplashView(isFinished: $splashFinished)
                    .transition(.opacity)
            } else if !disclaimerAccepted {
                DisclaimerView()
                    .transition(.opacity)
            } else if isLoggedIn {
                MainMenuView()
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .environmentObject(bleManager)
        .environmentObject(sensorData)
        //.modelContainer(for: [UserEntity.self, TestResultEntity.self])
        // When BLE connects/disconnects, attach or detach the peripheral from SensorDataManager
        
        
        .onChange(of: bleManager.connectionState) { _, newState in
            switch newState {
            case .connected:
                if let peripheral = bleManager.exposedPeripheral {
                    sensorData.attachPeripheral(peripheral)
                }
            case .disconnected, .idle:
                sensorData.detachPeripheral()
            default:
                break
         
            }
             
         
        }
         
    }
}
