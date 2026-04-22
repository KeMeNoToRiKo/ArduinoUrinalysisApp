//
//  WaitingForDeviceView.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/13/26.
//

import SwiftUI

struct WaitingForDeviceView: View {
    /// Called once the device (or simulation) signals that the test has started.
    var onBegin: () -> Void

    @EnvironmentObject var sensorData: SensorDataManager
    @EnvironmentObject var bleManager: BLEManager

    @State private var rotationDegrees: Double = 0
    @State private var dotOpacities: [Double] = [1, 1, 1]
    @State private var didScheduleSimStart = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.22, green: 0.55, blue: 0.90),
                    Color(red: 0.00, green: 0.76, blue: 0.87)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 36) {
                Spacer()

                // MARK: - Spinning circle
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 180, height: 180)
                        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)

                    Circle()
                        .trim(from: 0.0, to: 0.25)
                        .stroke(
                            Color(red: 0.22, green: 0.45, blue: 0.85),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(rotationDegrees))
                }

                // MARK: - Text
                VStack(spacing: 12) {
                    Text("Waiting for Device\nInitialization...")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(sensorData.simulatedMode
                         ? "Simulated mode — press button to start…"
                         : "Press the physical button on the device to begin")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Animated dots
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .opacity(dotOpacities[i])
                    }
                }

                Spacer()

                // Info card
                Text(sensorData.simulatedMode
                     ? "The simulation will automatically send a test-started signal after a short delay, just like pressing the physical button on the device."
                     : "Make sure your Arduino device is connected via Bluetooth, then press the physical start button on the device.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(20)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
            }
        }
        .onAppear {
            // Reset the flag so it fires fresh each test session
            sensorData.resetTestStarted()

            startRotation()
            animateDots()

            // In simulated mode, ask SensorDataManager to fake the button press.
            // In live BLE mode, the Arduino itself sends { "type": "test_started" }.
            if sensorData.simulatedMode && !didScheduleSimStart {
                didScheduleSimStart = true
                sensorData.simulateTestStart(after: 2.5)
            }
        }
        // Watch for the testStarted flag — works for both BLE and sim mode
        .onChange(of: sensorData.testStarted) { _, started in
            if started {
                onBegin()
            }
        }
    }

    // MARK: - Animations

    private func startRotation() {
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            rotationDegrees = 360
        }
    }

    private func animateDots() {
        for i in 0..<3 {
            withAnimation(
                Animation.easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                    .delay(Double(i) * 0.2)
            ) {
                dotOpacities[i] = 0.25
            }
        }
    }
}

#Preview {
    WaitingForDeviceView(onBegin: {})
        .environmentObject(SensorDataManager())
        .environmentObject(BLEManager())
}
