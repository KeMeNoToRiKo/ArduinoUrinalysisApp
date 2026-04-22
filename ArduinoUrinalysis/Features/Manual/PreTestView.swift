//
//  PreTestView.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/21/26.
//

import SwiftUI

// MARK: - PreTestView (shown before starting urinalysis)

struct PreTestView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("manualDoNotShowAgain") private var manualDoNotShowAgain: Bool = false

    /// Called when the user taps "Begin Urinalysis".
    var onProceed: () -> Void

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    headerSection

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(UrinalysisProtocolStep.all) { step in
                                stepCard(step)
                            }

                            warningBanner
                                .padding(.top, 4)

                            doNotShowToggle
                                .padding(.top, 4)

                            Spacer()
                            
                            // Spacer pushes the button below the fold —
                            // user must scroll down to reach it.
                            //Spacer(minLength: geo.size.height * 0.28)

                            beginButton

                            Color.clear.frame(height: 36)
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 18)
                        .padding(.bottom, 8)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.38, blue: 0.82),
                    Color(red: 0.02, green: 0.66, blue: 0.86)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 140, height: 140)
                .offset(x: 160, y: 10)

            VStack(alignment: .leading, spacing: 3) {
                Text("Pre-Test Protocol")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text("Complete all 5 steps before starting")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.80))
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 16)
        }
        .frame(minHeight: 110)
    }

    // MARK: - Step Card

    private func stepCard(_ step: UrinalysisProtocolStep) -> some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(step.bgColor)
                        .frame(width: 52, height: 52)
                    Image(systemName: step.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(step.iconColor)
                }
                if step.id < UrinalysisProtocolStep.all.count {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 1.5, height: 20)
                        .padding(.top, 4)
                }
            }
            .frame(width: 60)

            VStack(alignment: .leading, spacing: 5) {
                Text("Step \(step.id)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(step.iconColor)
                    .textCase(.uppercase)
                    .kerning(0.4)
                Text(step.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(.label))
                Text(step.description)
                    .font(.system(size: 13))
                    .foregroundColor(Color(.secondaryLabel))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            .padding(.leading, 4)
            .padding(.top, 6)
            .padding(.bottom, step.id < UrinalysisProtocolStep.all.count ? 8 : 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, step.id < UrinalysisProtocolStep.all.count ? 0 : 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 5, x: 0, y: 2)
    }

    // MARK: - Warning Banner

    private var warningBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.75, green: 0.50, blue: 0.00))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text("Important")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 0.60, green: 0.38, blue: 0.00))
                Text("Place the device on a stable, flat surface. Ensure the lid is fully closed and no direct light reaches the sensor before pressing Start.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.45, green: 0.30, blue: 0.00))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 1.0, green: 0.94, blue: 0.76))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(red: 0.92, green: 0.78, blue: 0.30).opacity(0.6), lineWidth: 1)
        )
    }

    // MARK: - Don't Show Again Toggle

    private var doNotShowToggle: some View {
        HStack(spacing: 12) {
            Image(systemName: "eye.slash")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(.secondaryLabel))

            VStack(alignment: .leading, spacing: 1) {
                Text("Don't show this again")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.label))
                Text("You can always view it from your profile")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.secondaryLabel))
            }

            Spacer()

            Toggle("", isOn: $manualDoNotShowAgain)
                .labelsHidden()
                .tint(Color(red: 0.12, green: 0.38, blue: 0.82))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }

    // MARK: - Begin Button

    private var beginButton: some View {
        Button {
            dismiss()
            onProceed()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("Begin Urinalysis")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 22)
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
            .shadow(color: Color(red: 0.12, green: 0.38, blue: 0.82).opacity(0.35), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    PreTestView(onProceed: {})
        .environmentObject(BLEManager())
        .environmentObject(SensorDataManager())
}
