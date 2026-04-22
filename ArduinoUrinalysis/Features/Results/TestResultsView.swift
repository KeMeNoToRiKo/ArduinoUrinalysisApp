//
//  TestResultsView.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/13/26.
//

import SwiftUI
import SwiftData

struct TestResultsView: View {
    let result: TestResultEntity
    var onBackToDashboard: () -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - Advanced results gate
    /// `true`  → show the disclaimer sheet first
    /// `false` → do nothing yet
    @State private var showAdvancedDisclaimer: Bool = false
    /// Only becomes `true` after the user explicitly taps "I Understand" in the disclaimer
    @State private var showAdvancedSheet: Bool = false

    // MARK: - Derived helpers

    private var statusColor: Color {
        switch result.overallStatus {
        case "NORMAL":           return Color(red: 0.08, green: 0.62, blue: 0.30)
        case "MILD DEHYDRATION": return Color(red: 0.88, green: 0.60, blue: 0.00)
        default:                 return Color(red: 0.82, green: 0.18, blue: 0.18)
        }
    }

    private var statusGradient: [Color] {
        switch result.overallStatus {
        case "NORMAL":
            return [Color(red: 0.08, green: 0.52, blue: 0.25), Color(red: 0.10, green: 0.72, blue: 0.42)]
        case "MILD DEHYDRATION":
            return [Color(red: 0.80, green: 0.50, blue: 0.00), Color(red: 0.98, green: 0.72, blue: 0.08)]
        default:
            return [Color(red: 0.75, green: 0.10, blue: 0.10), Color(red: 0.96, green: 0.28, blue: 0.28)]
        }
    }

    private var statusIcon: String {
        switch result.overallStatus {
        case "NORMAL":           return "checkmark.circle.fill"
        case "MILD DEHYDRATION": return "exclamationmark.circle.fill"
        default:                 return "xmark.circle.fill"
        }
    }

    private var specificGravity: Double {
        1.0 + (result.tdsPPM / 1_000_000) * 640_000
    }
    private var sgFormatted: String { String(format: "%.3f", specificGravity) }

    private var phOK: Bool  { result.pH >= 4.5 && result.pH <= 8.0 }
    private var sgOK: Bool  { specificGravity >= 1.005 && specificGravity <= 1.030 }
    private var tdsOK: Bool { result.tdsPPM >= 200 && result.tdsPPM <= 800 }
    private var ecOK: Bool  { result.ecUSCm >= 400 && result.ecUSCm <= 1600 }
    private var tmpOK: Bool { result.tempC >= 15 && result.tempC <= 40 }

    private var urineColorLabel: String {
        let brightness = (Double(result.colorR) + Double(result.colorG) + Double(result.colorB)) / (3.0 * 255)
        if brightness > 0.85 { return "Pale / Clear" }
        if brightness > 0.70 { return "Light Straw" }
        if brightness > 0.55 { return "Straw" }
        if brightness > 0.40 { return "Dark Yellow" }
        return "Amber / Brown"
    }

    private var colorHydrationNote: String {
        let brightness = (Double(result.colorR) + Double(result.colorG) + Double(result.colorB)) / (3.0 * 255)
        if brightness > 0.85 { return "Indicates excellent hydration" }
        if brightness > 0.70 { return "Indicates good hydration" }
        if brightness > 0.55 { return "Indicates adequate hydration" }
        if brightness > 0.40 { return "May indicate mild dehydration" }
        return "May indicate significant dehydration"
    }

    private var colorStatusOK: Bool {
        let brightness = (Double(result.colorR) + Double(result.colorG) + Double(result.colorB)) / (3.0 * 255)
        return brightness > 0.55
    }

    private var swatchColor: Color {
        Color(
            red:   Double(result.colorR) / 255,
            green: Double(result.colorG) / 255,
            blue:  Double(result.colorB) / 255
        )
    }

    private var timestampFormatted: String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f.string(from: result.timestamp)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        resultHeroCard
                            .padding(.top, 20)

                        hydrationGaugeCard

                        sensorStatusCard

                        colorStatusCard

                        recommendationCard

                        advancedResultsButton

                        actionButtons
                            .padding(.top, 4)
                            .padding(.bottom, 44)
                    }
                    .padding(.horizontal, 18)
                }
                .background(Color(.systemGroupedBackground))
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { onBackToDashboard() } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Dashboard")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if result.isSimulated {
                        Text("DEMO")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.22))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        // Step 1 — disclaimer sheet
        .sheet(isPresented: $showAdvancedDisclaimer) {
            AdvancedResultsDisclaimerSheet {
                // User tapped "I Understand" — close disclaimer, open advanced
                showAdvancedDisclaimer = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    showAdvancedSheet = true
                }
            } onCancel: {
                showAdvancedDisclaimer = false
            }
        }
        // Step 2 — actual advanced results sheet (only reachable after disclaimer)
        .sheet(isPresented: $showAdvancedSheet) {
            AdvancedResultsSheet(
                result: result,
                specificGravity: specificGravity,
                sgFormatted: sgFormatted,
                swatchColor: swatchColor,
                urineColorLabel: urineColorLabel
            )
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.22, green: 0.55, blue: 0.90),
                    Color(red: 0.00, green: 0.76, blue: 0.87)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 180, height: 180)
                .offset(x: 160, y: -10)

            VStack(alignment: .leading, spacing: 3) {
                Text("Test Results")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.75))
                    Text(timestampFormatted)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 18)
        }
        .frame(height: 200)
    }

    // MARK: - Result Hero Card

    private var resultHeroCard: some View {
        ZStack {
            LinearGradient(
                colors: statusGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))

            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 160, height: 160)
                .offset(x: 100, y: -40)
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 90, height: 90)
                .offset(x: -80, y: 40)

            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 70, height: 70)
                    Image(systemName: statusIcon)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(result.overallStatus)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("Hydration: \(Int(result.hydrationPercent))%")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.85))

                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                        Text(String(format: "%.1f%% confidence", result.algorithmConfidence))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Capsule())
                }

                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 22)
        }
        .shadow(color: statusGradient[0].opacity(0.40), radius: 14, x: 0, y: 6)
    }

    // MARK: - Hydration Gauge Card

    private var hydrationGaugeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                icon: "drop.fill",
                iconColor: Color(red: 0.16, green: 0.50, blue: 0.95),
                title: "Hydration Level"
            )

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: statusGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * CGFloat(min(result.hydrationPercent, 100)) / 100,
                            height: 12
                        )
                }
            }
            .frame(height: 12)

            HStack {
                Text("0%  ·  Dehydrated")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabel))
                Spacer()
                Text("\(Int(result.hydrationPercent))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(statusColor)
                Spacer()
                Text("Well Hydrated  ·  100%")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Sensor Status Card (status only — no raw values)

    private var sensorStatusCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(
                icon: "waveform.path.ecg.rectangle.fill",
                iconColor: Color(red: 0.22, green: 0.50, blue: 0.92),
                title: "Parameter Status"
            )
            .padding(.bottom, 14)

            statusRow(
                icon: "waveform.path.ecg",
                iconColor: Color(red: 0.22, green: 0.50, blue: 0.92),
                label: "pH",
                description: "Acid-base balance of urine",
                ok: phOK
            )
            rowDivider
            statusRow(
                icon: "scalemass.fill",
                iconColor: Color(red: 0.52, green: 0.34, blue: 0.88),
                label: "Specific Gravity",
                description: "Urine concentration level",
                ok: sgOK
            )
            rowDivider
            statusRow(
                icon: "atom",
                iconColor: Color(red: 0.96, green: 0.55, blue: 0.14),
                label: "TDS",
                description: "Total dissolved solids",
                ok: tdsOK
            )
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private var rowDivider: some View {
        Divider()
            .padding(.vertical, 10)
            .padding(.leading, 44)
    }

    private func statusRow(
        icon: String,
        iconColor: Color,
        label: String,
        description: String,
        ok: Bool
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.label))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(.secondaryLabel))
            }

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(ok
                        ? Color(red: 0.08, green: 0.62, blue: 0.30)
                        : Color(red: 0.88, green: 0.50, blue: 0.00))
                Text(ok ? "Normal" : "Abnormal")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(ok
                        ? Color(red: 0.08, green: 0.62, blue: 0.30)
                        : Color(red: 0.88, green: 0.50, blue: 0.00))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                (ok
                    ? Color(red: 0.08, green: 0.62, blue: 0.30)
                    : Color(red: 0.88, green: 0.50, blue: 0.00)
                ).opacity(0.10)
            )
            .clipShape(Capsule())
        }
    }

    // MARK: - Color Status Card (no raw sensor values)

    private var colorStatusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                icon: "paintpalette.fill",
                iconColor: Color(red: 0.82, green: 0.36, blue: 0.72),
                title: "Urine Color"
            )

            HStack(spacing: 16) {
                // Color swatch
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(swatchColor)
                        .frame(width: 64, height: 64)
                        .shadow(color: swatchColor.opacity(0.5), radius: 8, x: 0, y: 3)
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.separator), lineWidth: 0.5)
                        .frame(width: 64, height: 64)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(urineColorLabel)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(.label))
                    Text(colorHydrationNote)
                        .font(.system(size: 12))
                        .foregroundColor(Color(.secondaryLabel))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Status badge
                HStack(spacing: 5) {
                    Image(systemName: colorStatusOK
                          ? "checkmark.circle.fill"
                          : "exclamationmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(colorStatusOK
                            ? Color(red: 0.08, green: 0.62, blue: 0.30)
                            : Color(red: 0.88, green: 0.50, blue: 0.00))
                    Text(colorStatusOK ? "Normal" : "Abnormal")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(colorStatusOK
                            ? Color(red: 0.08, green: 0.62, blue: 0.30)
                            : Color(red: 0.88, green: 0.50, blue: 0.00))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    (colorStatusOK
                        ? Color(red: 0.08, green: 0.62, blue: 0.30)
                        : Color(red: 0.88, green: 0.50, blue: 0.00)
                    ).opacity(0.10)
                )
                .clipShape(Capsule())
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Recommendation Card

    private var recommendationCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.88, blue: 0.40).opacity(0.25))
                    .frame(width: 40, height: 40)
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.82, green: 0.56, blue: 0.00))
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("Recommendation")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.56, green: 0.36, blue: 0.00))
                Text(result.recommendation)
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.40, green: 0.26, blue: 0.00))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 1.0, green: 0.94, blue: 0.76))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.92, green: 0.78, blue: 0.30).opacity(0.6), lineWidth: 1)
        )
    }

    // MARK: - Advanced Results Button

    private var advancedResultsButton: some View {
        Button {
            showAdvancedDisclaimer = true
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.52, green: 0.34, blue: 0.88).opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "waveform.path.ecg.rectangle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.52, green: 0.34, blue: 0.88))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Advanced Results")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(red: 0.52, green: 0.34, blue: 0.88))
                    Text("Raw sensor values · For qualified professionals only")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.secondaryLabel))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0.52, green: 0.34, blue: 0.88))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color(red: 0.52, green: 0.34, blue: 0.88).opacity(0.30),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                onBackToDashboard()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back to Dashboard")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.38, blue: 0.82),
                            Color(red: 0.02, green: 0.66, blue: 0.86)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(
                    color: Color(red: 0.12, green: 0.38, blue: 0.82).opacity(0.30),
                    radius: 8, x: 0, y: 4
                )
            }
            .buttonStyle(ScaleButtonStyle())

            Button {
                // TODO: navigate to history
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 14, weight: .semibold))
                    Text("View History")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(Color(red: 0.12, green: 0.38, blue: 0.82))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            Color(red: 0.12, green: 0.38, blue: 0.82).opacity(0.5),
                            lineWidth: 1.5
                        )
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    // MARK: - Reusable section header

    private func sectionHeader(icon: String, iconColor: Color, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(iconColor)
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(.label))
        }
    }
}

// MARK: - AdvancedResultsDisclaimerSheet
// Shown BEFORE the user can access any raw sensor values.
// Intentionally difficult to dismiss — requires an explicit acknowledgement tap.

private struct AdvancedResultsDisclaimerSheet: View {
    var onAccept: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            // ── Red warning header ──────────────────────────────────────────
            ZStack {
                Color(red: 0.75, green: 0.08, blue: 0.08)
                    .ignoresSafeArea(edges: .top)

                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("PROFESSIONAL\nUSE ONLY")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .kerning(1.0)
                }
                .padding(.top, 36)
                .padding(.bottom, 28)
            }
            .frame(height: 220)

            // ── Body ────────────────────────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // Primary warning block
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(Color(red: 0.75, green: 0.08, blue: 0.08))
                                .font(.system(size: 16, weight: .bold))
                            Text("Do Not Self-Diagnose")
                                .font(.system(size: 17, weight: .heavy))
                                .foregroundColor(Color(red: 0.75, green: 0.08, blue: 0.08))
                        }
                        Text("The raw sensor values shown in Advanced Results are highly technical data. They are intended exclusively for qualified healthcare professionals — such as physicians, nurses, or licensed laboratory technicians — who are trained to interpret them within the full clinical context of a patient.")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.black))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                        
                    }
                    .padding(16)
                    .background(Color(red: 0.98, green: 0.92, blue: 0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(red: 0.75, green: 0.08, blue: 0.08).opacity(0.35), lineWidth: 1.5)
                    )

                    // Bullet list of risks
                    VStack(alignment: .leading, spacing: 12) {
                        riskBullet(
                            icon: "xmark.circle.fill",
                            color: Color(red: 0.82, green: 0.18, blue: 0.18),
                            text: "Interpreting these values without clinical training can lead to incorrect conclusions, unnecessary anxiety, or dangerous inaction."
                        )
                        riskBullet(
                            icon: "xmark.circle.fill",
                            color: Color(red: 0.82, green: 0.18, blue: 0.18),
                            text: "Abnormal readings do not automatically indicate disease. A trained professional must consider your full medical history, symptoms, and other test results before drawing any conclusion."
                        )
                        riskBullet(
                            icon: "xmark.circle.fill",
                            color: Color(red: 0.82, green: 0.18, blue: 0.18),
                            text: "This device is a screening tool only. It does not replace laboratory urinalysis, clinical examination, or professional medical judgment."
                        )
                    }

                    // "If you are not qualified" block
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 0.80, green: 0.45, blue: 0.00))
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("If you are not a qualified healthcare professional:")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(red: 0.60, green: 0.32, blue: 0.00))
                            Text("Please tap \"Go Back\" below. Share the overall results (Normal / Mild Dehydration / Dehydrated) with your doctor instead of attempting to interpret the raw values yourself.")
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.45, green: 0.24, blue: 0.00))
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(14)
                    .background(Color(red: 1.0, green: 0.94, blue: 0.76))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(red: 0.92, green: 0.78, blue: 0.30).opacity(0.6), lineWidth: 1)
                    )

                    // Acknowledgement button
                    Button(action: onAccept) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 15, weight: .bold))
                            Text("I Am a Qualified Professional — I Understand")
                                .font(.system(size: 14, weight: .bold))
                                .multilineTextAlignment(.center)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 12)
                        .background(Color(red: 0.52, green: 0.34, blue: 0.88))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(
                            color: Color(red: 0.52, green: 0.34, blue: 0.88).opacity(0.35),
                            radius: 8, x: 0, y: 4
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, 4)

                    // "Go back" link
                    Button(action: onCancel) {
                        Text("Go Back — I Don't Need This")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.secondaryLabel))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }

                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
    }

    private func riskBullet(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color(.label))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - AdvancedResultsSheet
// Raw sensor values — only reachable after the disclaimer is acknowledged.

private struct AdvancedResultsSheet: View {
    let result: TestResultEntity
    let specificGravity: Double
    let sgFormatted: String
    let swatchColor: Color
    let urineColorLabel: String

    @Environment(\.dismiss) private var dismiss

    private var phOK: Bool  { result.pH >= 4.5 && result.pH <= 8.0 }
    private var sgOK: Bool  { specificGravity >= 1.005 && specificGravity <= 1.030 }
    private var tdsOK: Bool { result.tdsPPM >= 200 && result.tdsPPM <= 800 }
    private var ecOK: Bool  { result.ecUSCm >= 400 && result.ecUSCm <= 1600 }
    private var tmpOK: Bool { result.tempC >= 15 && result.tempC <= 40 }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {

                    // Compact professional-only reminder
                    HStack(spacing: 10) {
                        Image(systemName: "staroflife.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.75, green: 0.08, blue: 0.08))
                        Text("These values are for qualified healthcare professionals only and must not be self-interpreted.")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(red: 0.60, green: 0.06, blue: 0.06))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.98, green: 0.92, blue: 0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.75, green: 0.08, blue: 0.08).opacity(0.30), lineWidth: 1)
                    )

                    // Raw sensor values card
                    VStack(alignment: .leading, spacing: 0) {
                        advSectionHeader(
                            icon: "waveform.path.ecg.rectangle.fill",
                            iconColor: Color(red: 0.22, green: 0.50, blue: 0.92),
                            title: "Raw Sensor Values"
                        )
                        .padding(.bottom, 14)

                        advSensorRow(
                            icon: "waveform.path.ecg",
                            iconColor: Color(red: 0.22, green: 0.50, blue: 0.92),
                            label: "pH Level",
                            value: String(format: "%.2f", result.pH),
                            unit: "",
                            reference: "4.5 – 8.0",
                            ok: phOK
                        )
                        advRowDivider
                        advSensorRow(
                            icon: "scalemass.fill",
                            iconColor: Color(red: 0.52, green: 0.34, blue: 0.88),
                            label: "Specific Gravity",
                            value: sgFormatted,
                            unit: "",
                            reference: "1.005 – 1.030",
                            ok: sgOK
                        )
                        advRowDivider
                        advSensorRow(
                            icon: "atom",
                            iconColor: Color(red: 0.96, green: 0.55, blue: 0.14),
                            label: "TDS",
                            value: String(format: "%.0f", result.tdsPPM),
                            unit: "ppm",
                            reference: "200 – 800 ppm",
                            ok: tdsOK
                        )
                        advRowDivider
                        advSensorRow(
                            icon: "bolt.fill",
                            iconColor: Color(red: 0.14, green: 0.64, blue: 0.42),
                            label: "Conductivity (EC)",
                            value: String(format: "%.0f", result.ecUSCm),
                            unit: "µS/cm",
                            reference: "400 – 1600 µS/cm",
                            ok: ecOK
                        )

                    }
                    .padding(18)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)

                    // Color detail card
                    VStack(alignment: .leading, spacing: 14) {
                        advSectionHeader(
                            icon: "paintpalette.fill",
                            iconColor: Color(red: 0.82, green: 0.36, blue: 0.72),
                            title: "Colorimetric Data"
                        )

                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(swatchColor)
                                    .frame(width: 56, height: 56)
                                    .shadow(color: swatchColor.opacity(0.5), radius: 6, x: 0, y: 2)
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.separator), lineWidth: 0.5)
                                    .frame(width: 56, height: 56)
                            }

                            VStack(alignment: .leading, spacing: 5) {
                                Text(urineColorLabel)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(.label))
                                Text(result.colorHex.uppercased())
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(.secondaryLabel))
                                HStack(spacing: 8) {
                                    colorChannel(label: "R", value: result.colorR, color: .red)
                                    colorChannel(label: "G", value: result.colorG, color: .green)
                                    colorChannel(label: "B", value: result.colorB, color: .blue)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 6) {
                                metricPill(
                                    icon: "sun.max.fill",
                                    value: String(format: "%.0f lx", result.lux),
                                    color: Color(red: 0.96, green: 0.75, blue: 0.10)
                                )
                                metricPill(
                                    icon: "thermometer.sun",
                                    value: "\(result.cct) K",
                                    color: Color(red: 0.60, green: 0.80, blue: 1.0)
                                )
                            }
                        }
                    }
                    .padding(18)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)

                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Advanced Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                }
            }
        }
    }

    // MARK: - Advanced sheet sub-views

    private func advSectionHeader(icon: String, iconColor: Color, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(iconColor)
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(.label))
        }
    }

    private var advRowDivider: some View {
        Divider()
            .padding(.vertical, 10)
            .padding(.leading, 44)
    }

    private func advSensorRow(
        icon: String,
        iconColor: Color,
        label: String,
        value: String,
        unit: String,
        reference: String,
        ok: Bool
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(Color(.secondaryLabel))
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(.label))
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(reference)
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabel))
                HStack(spacing: 4) {
                    Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(ok
                            ? Color(red: 0.08, green: 0.62, blue: 0.30)
                            : Color(red: 0.88, green: 0.50, blue: 0.00))
                    Text(ok ? "Normal" : "Abnormal")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ok
                            ? Color(red: 0.08, green: 0.62, blue: 0.30)
                            : Color(red: 0.88, green: 0.50, blue: 0.00))
                }
            }
        }
    }

    private func colorChannel(label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text("\(label):\(value)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(.secondaryLabel))
        }
    }

    private func metricPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(.label))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    let reading = UrinalysisReading.simulated()
    let dummyUser = UserEntity(email: "demo@test.com", username: "demo", passwordHash: "")
    let result = TestResultEntity.from(reading: reading, user: dummyUser, isSimulated: true)
    return TestResultsView(result: result, onBackToDashboard: {})
}
