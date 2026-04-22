//
//  ManualView.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/21/26.
//

import SwiftUI

// MARK: - Shared Step Model (used by ManualView and PreTestView)

struct UrinalysisProtocolStep: Identifiable {
    let id: Int
    let icon: String
    let iconColor: Color
    let bgColor: Color
    let title: String
    let description: String

    static let all: [UrinalysisProtocolStep] = [
        .init(id: 1,
              icon: "trash.slash.fill",
              iconColor: Color(red: 0.90, green: 0.30, blue: 0.25),
              bgColor: Color(red: 0.90, green: 0.30, blue: 0.25).opacity(0.10),
              title: "Clean the Collection Cup",
              description: "Use a sterile, dry collection cup — even trace residue can skew color and pH readings."),
        .init(id: 2,
              icon: "drop.halffull",
              iconColor: Color(red: 0.14, green: 0.64, blue: 0.42),
              bgColor: Color(red: 0.14, green: 0.64, blue: 0.42).opacity(0.10),
              title: "Collect a Midstream Sample",
              description: "Let the first and last portion pass, then collect the middle stream for the most accurate result."),
        .init(id: 3,
              icon: "tray.and.arrow.down.fill",
              iconColor: Color(red: 0.22, green: 0.50, blue: 0.92),
              bgColor: Color(red: 0.22, green: 0.50, blue: 0.92).opacity(0.10),
              title: "Place Sample in the Device",
              description: "Carefully pour the sample into the device chamber without spilling on the sensor window."),
        .init(id: 4,
              icon: "lock.fill",
              iconColor: Color(red: 0.82, green: 0.56, blue: 0.08),
              bgColor: Color(red: 0.82, green: 0.56, blue: 0.08).opacity(0.10),
              title: "Close the Lid Completely",
              description: "Ambient light interferes with the colorimetric sensor. Ensure the lid clicks fully shut."),
        .init(id: 5,
              icon: "hand.tap.fill",
              iconColor: Color(red: 0.52, green: 0.34, blue: 0.88),
              bgColor: Color(red: 0.52, green: 0.34, blue: 0.88).opacity(0.10),
              title: "Press Start on the Device",
              description: "Press the physical button on your Arduino to begin the analysis cycle. The app will receive data automatically."),
    ]
}

// MARK: - ManualView (read-only reference, opened from profile)

struct ManualView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(UrinalysisProtocolStep.all) { step in
                            stepCard(step)
                        }

                        warningBanner
                            .padding(.top, 4)

                        Color.clear.frame(height: 24)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 8)
                }
                .background(Color(.systemGroupedBackground))
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Close")
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
                Text("Reference guide for sample collection")
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
}

#Preview {
    ManualView()
}
