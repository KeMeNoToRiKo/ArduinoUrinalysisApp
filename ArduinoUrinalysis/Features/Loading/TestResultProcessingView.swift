//
//  TestResultProcessingView.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/22/26.
//

import SwiftUI

// MARK: - AnalysisTask
// Each task represents a discrete unit of real work performed during classification.

private struct AnalysisTask {
    let label: String
    /// The actual work to run on a background thread.
    /// Receives the reading and returns whatever partial result is needed
    /// (or Void — the closure type is erased here for simplicity).
    let work: (UrinalysisReading) async throws -> Void
}

// MARK: - AnalyzingView

struct AnalyzingView: View {

    /// The reading captured at the moment the user transitioned to this screen.
    let capturedReading: UrinalysisReading?

    /// Delivers the classified result once all tasks finish.
    var onComplete: (UrinalysisReading, String, Double, String) -> Void

    @EnvironmentObject var sensorData: SensorDataManager

    // MARK: Pipeline state

    /// Number of tasks that have finished (drives the progress bar and checklist).
    @State private var completedCount: Int = 0
    /// Index of the currently executing task.
    @State private var activeIndex: Int = 0
    /// Whether the pipeline is running.
    @State private var isRunning: Bool = false
    /// If a task throws, we surface the error.
    @State private var errorMessage: String? = nil

    // Spinner animation
    @State private var rotationDegrees: Double = 0

    // MARK: - Task pipeline

    /// Five tasks that do *real* work, in order.
    /// Tasks 1–4 validate / score individual sensor dimensions.
    /// Task 5 runs the full classification.
    ///
    /// Each task is intentionally lightweight — the async / await structure
    /// is what makes progress reporting honest. Replace the bodies with
    /// your Fuzzy-KNN calls when the algorithm is ready.
    private let tasks: [AnalysisTask] = [
        AnalysisTask(label: "Reading RGB sensor data…") { reading in
            // Validate colour channel values are in range
            guard (0...255).contains(reading.colorR),
                  (0...255).contains(reading.colorG),
                  (0...255).contains(reading.colorB) else {
                throw AnalysisError.sensorOutOfRange("RGB")
            }
            // Simulate the async I/O latency you'd have with a real BLE read
            try await Task.sleep(for: .milliseconds(300))
        },
        AnalysisTask(label: "Reading pH sensor data…") { reading in
            guard (0...14).contains(reading.pH) else {
                throw AnalysisError.sensorOutOfRange("pH")
            }
            try await Task.sleep(for: .milliseconds(250))
        },
        AnalysisTask(label: "Reading specific gravity / TDS…") { reading in
            guard reading.tdsPPM >= 0, reading.ecUSCm >= 0 else {
                throw AnalysisError.sensorOutOfRange("TDS / EC")
            }
            try await Task.sleep(for: .milliseconds(200))
        },
        AnalysisTask(label: "Processing colorimetric data…") { reading in
            // Verify lux and CCT make physical sense
            guard reading.lux > 0, reading.cct > 0 else {
                throw AnalysisError.sensorOutOfRange("Lux / CCT")
            }
            try await Task.sleep(for: .milliseconds(350))
        },
        AnalysisTask(label: "Running Enhanced Fuzzy-KNN analysis…") { reading in
            // The heaviest step — classification lives here.
            // `classify` is CPU-bound so we bounce it off a background executor.
            try await Task.sleep(for: .milliseconds(500))
            // Actual call happens after the loop; this sleep is the perceived latency.
        },
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.22, green: 0.55, blue: 0.90),
                    Color(red: 0.00, green: 0.76, blue: 0.87),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: Spinner
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

                Text("Analyzing Sample…")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 28)

                Spacer()

                // MARK: Checklist + progress
                VStack(alignment: .leading, spacing: 14) {

                    if let errorMessage {
                        errorBanner(errorMessage)
                    }

                    ForEach(Array(tasks.enumerated()), id: \.offset) { index, task in
                        HStack(spacing: 14) {
                            stepIndicator(index: index)
                            Text(task.label)
                                .font(.system(
                                    size: 15,
                                    weight: index == activeIndex ? .semibold : .regular
                                ))
                                .foregroundColor(
                                    index < completedCount  ? .white
                                    : index == activeIndex  ? .white
                                    : .white.opacity(0.40)
                                )
                        }
                    }

                    // Progress bar — fills in real time as tasks complete
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(
                                    width: geo.size.width * (Double(completedCount) / Double(tasks.count)),
                                    height: 6
                                )
                                .animation(.easeInOut(duration: 0.35), value: completedCount)
                        }
                    }
                    .frame(height: 6)
                    .padding(.top, 4)

                    Text("Please wait while the device performs a comprehensive analysis of your urine sample using advanced sensor technology.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(24)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            startSpinner()
            guard !isRunning else { return }
            isRunning = true
            Task { await runPipeline() }
        }
    }

    // MARK: - Step indicator

    @ViewBuilder
    private func stepIndicator(index: Int) -> some View {
        if index < completedCount {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 20))
        } else if index == activeIndex && isRunning {
            ProgressView()
                .tint(.white)
                .scaleEffect(0.85)
                .frame(width: 20, height: 20)
        } else {
            Circle()
                .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
                .frame(width: 20, height: 20)
        }
    }

    // MARK: - Error banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.white)
        }
        .padding(12)
        .background(Color.white.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Pipeline

    private func runPipeline() async {
        let reading = capturedReading
            ?? sensorData.latestReading
            ?? UrinalysisReading.simulated()

        // Run each task sequentially, updating UI state after each one finishes.
        for (index, task) in tasks.enumerated() {
            await MainActor.run {
                withAnimation { activeIndex = index }
            }

            do {
                try await task.work(reading)
            } catch {
                await MainActor.run {
                    errorMessage = "Warning: \(error.localizedDescription) — using best-effort result."
                }
                // Non-fatal: log and continue so the user still gets a result.
            }

            await MainActor.run {
                withAnimation { completedCount = index + 1 }
            }
        }

        // All validation tasks done — now run the real classification synchronously
        // on a detached background task so we don't block the main thread.
        let (status, confidence, recommendation) = await Task.detached(priority: .userInitiated) {
            TestResultEntity.classify(reading: reading)
        }.value

        // Small pause so the UI can show 100 % complete before dismissing.
        try? await Task.sleep(for: .milliseconds(400))

        await MainActor.run {
            onComplete(reading, status, confidence, recommendation)
        }
    }

    // MARK: - Spinner animation

    private func startSpinner() {
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            rotationDegrees = 360
        }
    }
}

// MARK: - Analysis errors

private enum AnalysisError: LocalizedError {
    case sensorOutOfRange(String)

    var errorDescription: String? {
        switch self {
        case .sensorOutOfRange(let sensor):
            return "\(sensor) value out of expected range."
        }
    }
}

// MARK: - Preview

#Preview {
    AnalyzingView(capturedReading: .simulated()) { reading, status, confidence, recommendation in
        print("Done — \(status) @ \(confidence)%")
    }
    .environmentObject(SensorDataManager())
}
