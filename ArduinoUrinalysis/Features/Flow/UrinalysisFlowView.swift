//
//  UrinalysisFlowView.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/22/26.
//

import SwiftUI
import SwiftData

// MARK: - Flow steps

private enum FlowStep {
    case waiting       // WaitingForDeviceView — waiting for the physical button press
    case analyzing     // AnalyzingView        — running the sensor pipeline
    case results       // TestResultsView      — displaying the classified result
}

// MARK: - UrinalysisFlowView

/// Owns the three-step urinalysis lifecycle:
///   WaitingForDeviceView → AnalyzingView → TestResultsView
///
/// Persists the classified `TestResultEntity` to SwiftData once analysis
/// is complete, then exposes `onBackToDashboard` so the caller (MainMenuView)
/// can dismiss the full-screen cover.
struct UrinalysisFlowView: View {

    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("loggedInUsername") private var loggedInUsername: String = ""

    @EnvironmentObject var sensorData: SensorDataManager
    @EnvironmentObject var bleManager:  BLEManager

    @State private var step: FlowStep = .waiting

    /// Snapshot of the latest reading taken the moment analysis begins.
    @State private var capturedReading: UrinalysisReading? = nil

    /// The persisted entity — set after classify() + SwiftData insert.
    @State private var savedResult: TestResultEntity? = nil

    // MARK: - Body

    var body: some View {
        ZStack {
            switch step {

            case .waiting:
                WaitingForDeviceView(
                    onBegin: {
                        // Capture the reading now — before the analyzing screen shows —
                        // so we use the most recent live / simulated data point.
                        capturedReading = sensorData.latestReading
                        withAnimation(.easeInOut(duration: 0.3)) {
                            step = .analyzing
                        }
                    },
                    onCancel: {
                        dismiss()
                    }
                )
                .transition(.opacity)

            case .analyzing:
                AnalyzingView(capturedReading: capturedReading) { reading, status, confidence, recommendation in
                    // Persist to SwiftData on the main thread (modelContext is main-actor bound)
                    let entity = persistResult(
                        reading:        reading,
                        status:         status,
                        confidence:     confidence,
                        recommendation: recommendation
                    )
                    savedResult = entity
                    withAnimation(.easeInOut(duration: 0.3)) {
                        step = .results
                    }
                }
                .transition(.opacity)

            case .results:
                if let result = savedResult {
                    TestResultsView(result: result) {
                        dismiss()
                    }
                    .transition(.opacity)
                } else {
                    // Should never happen — safety fallback
                    Color(.systemGroupedBackground)
                        .overlay(
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)
                                Text("Result unavailable")
                                    .font(.headline)
                                Button("Back") { dismiss() }
                                    .buttonStyle(.borderedProminent)
                            }
                        )
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    // MARK: - Persistence

    /// Builds a `TestResultEntity` from the classified data, inserts it into
    /// SwiftData, and returns it. Falls back gracefully if the logged-in user
    /// cannot be found in the store (uses an ephemeral placeholder instead).
    @discardableResult
    private func persistResult(
        reading:        UrinalysisReading,
        status:         String,
        confidence:     Double,
        recommendation: String
    ) -> TestResultEntity {

        // Resolve the logged-in user so we can stamp the result with their UUID.
        let user: UserEntity = UserStore.findUser(
            byUsername: loggedInUsername,
            in: modelContext
        ) ?? UserEntity(
            email:        "unknown@local",
            username:     loggedInUsername.isEmpty ? "unknown" : loggedInUsername,
            passwordHash: ""
        )

        let entity = TestResultEntity(
            timestamp:           reading.timestamp,
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

        modelContext.insert(entity)
        try? modelContext.save()

        return entity
    }
}

// MARK: - Preview

#Preview {
    UrinalysisFlowView()
        .environmentObject(SensorDataManager())
        .environmentObject(BLEManager())
}
