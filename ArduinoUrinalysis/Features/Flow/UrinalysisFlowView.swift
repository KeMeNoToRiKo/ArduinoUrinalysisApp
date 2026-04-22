//
//  UrinalysisFlowView.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/22/26.
//

import SwiftUI
import SwiftData

// MARK: - Flow state

private enum FlowStage {
    case waiting       // WaitingForDeviceView — listening for test_started signal
    case analyzing     // AnalyzingView        — real async classification pipeline
    case done(TestResultEntity)  // Results screen (stub for now)
}

// MARK: - UrinalysisFlowView

/// Owns the full test lifecycle in a single full-screen cover:
///   WaitingForDeviceView  →  AnalyzingView  →  Results
///
/// `MainMenuView` presents this one view and never needs to manage
/// sub-navigation itself.
struct UrinalysisFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @EnvironmentObject var sensorData: SensorDataManager
    @EnvironmentObject var bleManager:  BLEManager

    @AppStorage("loggedInUsername") private var loggedInUsername: String = ""

    @State private var stage: FlowStage = .waiting

    var body: some View {
        ZStack {
            switch stage {

            // ── 1. Wait for the device button press (or sim signal) ──────────
            case .waiting:
                WaitingForDeviceView {
                    // Capture the freshest reading the moment the signal arrives.
                    // For simulated mode this is already populated by the timer;
                    // for live BLE it's the last packet received before button press.
                    let snapshot = sensorData.latestReading
                    withAnimation(.easeInOut(duration: 0.35)) {
                        stage = .analyzing
                    }
                    // Store the snapshot so AnalyzingView uses the exact same data
                    // even if the sensor keeps sending updates in the background.
                    capturedReadingForAnalysis = snapshot
                }
                .transition(.opacity)

            // ── 2. Run the real async classification pipeline ─────────────────
            case .analyzing:
                AnalyzingView(capturedReading: capturedReadingForAnalysis) { reading, status, confidence, recommendation in
                    // Build + persist the entity
                    let entity = buildEntity(
                        reading:        reading,
                        status:         status,
                        confidence:     confidence,
                        recommendation: recommendation
                    )
                    if let entity {
                        modelContext.insert(entity)
                        try? modelContext.save()
                        withAnimation(.easeInOut(duration: 0.35)) {
                            stage = .done(entity)
                        }
                    } else {
                        // No logged-in user found — bail out gracefully
                        dismiss()
                    }
                }
                .transition(.opacity)

            // ── 3. Results ────────────────────────────────────────────────────
            case .done(let entity):
                // TODO: Replace this stub with your real ResultsView(entity:)
                ResultsStubView(entity: entity) {
                    sensorData.resetTestStarted()
                    dismiss()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: stageID)
    }

    // MARK: - Helpers

    /// Holds the reading snapshot captured the moment test_started fires.
    @State private var capturedReadingForAnalysis: UrinalysisReading? = nil

    /// An Equatable proxy for `FlowStage` — needed to drive `.animation(value:)`.
    private var stageID: Int {
        switch stage {
        case .waiting:    return 0
        case .analyzing:  return 1
        case .done:       return 2
        }
    }

    private func buildEntity(
        reading:        UrinalysisReading,
        status:         String,
        confidence:     Double,
        recommendation: String
    ) -> TestResultEntity? {
        // Look up the current user so we can bind the result to them.
        let descriptor = FetchDescriptor<UserEntity>()
        guard let users = try? modelContext.fetch(descriptor),
              let user  = users.first(where: { $0.username == loggedInUsername })
        else { return nil }

        return TestResultEntity(
            userID:              user.id,
            username:            user.username,
            isSimulated:         sensorData.simulatedMode,
            tempC:               reading.tempC,
            pH:                  reading.pH,
            tdsPPM:              reading.tdsPPM,
            ecUSCm:              reading.ecUSCm,
            colorR:              reading.colorR,
            colorG:              reading.colorG,
            colorB:              reading.colorB,
            colorHex:            reading.colorHex,
            lux:                 reading.lux,
            cct:                 reading.cct,
            hydrationPercent:    reading.hydrationPercent,
            overallStatus:       status,
            algorithmConfidence: confidence,
            recommendation:      recommendation,
            deviceName:          reading.device
        )
    }
}

// MARK: - Results stub
// Replace this with your real results screen when it is ready.

private struct ResultsStubView: View {
    let entity: TestResultEntity
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.52, blue: 0.25), Color(red: 0.10, green: 0.68, blue: 0.40)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.white)

                VStack(spacing: 8) {
                    Text("Analysis Complete")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    if entity.isSimulated {
                        Label("Simulated test", systemImage: "waveform")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Capsule())
                    }
                }

                VStack(spacing: 10) {
                    resultRow(label: "Status",     value: entity.overallStatus)
                    resultRow(label: "Hydration",  value: "\(Int(entity.hydrationPercent))%")
                    resultRow(label: "pH",         value: String(format: "%.2f", entity.pH))
                    resultRow(label: "Confidence", value: String(format: "%.0f%%", entity.algorithmConfidence))
                }
                .padding(20)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 32)

                Text(entity.recommendation)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button(action: onDismiss) {
                    Text("Done")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.08, green: 0.52, blue: 0.25))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }

    private func resultRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview

#Preview {
    UrinalysisFlowView()
        .environmentObject(SensorDataManager())
        .environmentObject(BLEManager())
}
