//
//  MainMenuView.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 2/12/26.
//

import SwiftUI

struct MainMenuView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("loggedInUsername") private var loggedInUsername: String = ""
    @AppStorage("manualDoNotShowAgain") private var manualDoNotShowAgain: Bool = false
    @EnvironmentObject var bleManager: BLEManager
    @EnvironmentObject var sensorData: SensorDataManager

    @State private var showConnectDevice = false
    @State private var showPreTest = false          // pre-test checklist (shown first unless opted out)
    @State private var showUrinalysisFlow = false   // UrinalysisFlowView — waiting → analyzing → results
    @State private var showManual = false
    @State private var headerAppeared = false
    @State private var contentAppeared = false
    @State private var bleBannerPressed = false

    private var lastHydration: String { sensorData.latestReading?.hydrationDisplay ?? "--" }
    private var lastPH: String        { sensorData.latestReading?.phDisplay ?? "--" }
    private var lastTDS: String       { sensorData.latestReading?.tdsDisplay ?? "--" }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default:      return "Good night"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                    .opacity(headerAppeared ? 1 : 0)
                    .offset(y: headerAppeared ? 0 : -12)

                VStack(spacing: 16) {
                    bleStatusBanner
                    simToggleRow
                    statsRow
                    Divider().padding(.vertical, 4)
                    primaryActionCard
                    secondaryActionsRow
                    tipCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)

        // ── Sheets / covers ──────────────────────────────────────────────────

        // Bluetooth device picker
        .sheet(isPresented: $showConnectDevice) {
            ConnectDeviceView()
        }

        // Pre-test protocol checklist (shown unless the user opted out).
        // onProceed dismisses the checklist and opens the flow.
        .fullScreenCover(isPresented: $showPreTest) {
            PreTestView(onProceed: {
                showUrinalysisFlow = true
            })
        }

        // The full test lifecycle: waiting → analyzing → results.
        // This is the ONLY entry point into the urinalysis pipeline.
        .fullScreenCover(isPresented: $showUrinalysisFlow) {
            UrinalysisFlowView()
        }

        // Read-only manual opened from the profile menu
        .fullScreenCover(isPresented: $showManual) {
            ManualView()
        }

        .onAppear {
            if sensorData.simulatedMode { sensorData.startSimulation() }
            withAnimation(.easeOut(duration: 0.45)) { headerAppeared = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.15)) { contentAppeared = true }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.40, blue: 0.82),
                    Color(red: 0.02, green: 0.65, blue: 0.80)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 260, height: 260)
                .offset(x: 110, y: -30)

            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 160, height: 160)
                .offset(x: -80, y: 20)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(greeting)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                            .textCase(.uppercase)
                            .kerning(0.8)
                        Text(loggedInUsername.isEmpty ? "User" : loggedInUsername)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        profileMenuButton

                        CircleHeaderButton(icon: "rectangle.portrait.and.arrow.right") {
                            bleManager.disconnect()
                            loggedInUsername = ""
                            isLoggedIn = false
                        }
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 22)
                .padding(.bottom, 22)
            }
            .padding(.bottom, 25)
        }
        .frame(height: 170)
    }

    // MARK: - Profile Menu Button

    private var profileMenuButton: some View {
        Menu {
            Button {
                showManual = true
            } label: {
                Label("View Manual", systemImage: "list.clipboard.fill")
            }

            Divider()

            Button(role: .destructive) {
                bleManager.disconnect()
                loggedInUsername = ""
                isLoggedIn = false
            } label: {
                Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            Image(systemName: "person.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.18))
                .clipShape(Circle())
        }
    }

    // MARK: - BLE Status Banner

    @ViewBuilder
    private var bleStatusBanner: some View {
        if bleManager.isConnected {
            connectedBLEBanner
        } else {
            disconnectedBLEBanner
        }
    }

    private var connectedBLEBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(red: 0.45, green: 1.0, blue: 0.60))
                        .frame(width: 6, height: 6)
                    Text("Connected")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                Text(bleManager.connectedName ?? "Arduino Device")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.80))
            }

            Spacer()

            Button {
                bleManager.disconnect()
            } label: {
                Text("Disconnect")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.90))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.52, blue: 0.25),
                    Color(red: 0.10, green: 0.68, blue: 0.40)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color(red: 0.08, green: 0.52, blue: 0.25).opacity(0.35), radius: 10, x: 0, y: 4)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.96).combined(with: .opacity),
            removal:   .scale(scale: 0.96).combined(with: .opacity)
        ))
    }

    private var disconnectedBLEBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 42, height: 42)
                Image(systemName: "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(.systemGray))
                    .scaleEffect(bleBannerPressed ? 0.80 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: bleBannerPressed)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("No device connected")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.label))
                Text("Tap to pair your Arduino sensor")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.secondaryLabel))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
                .offset(x: bleBannerPressed ? 3 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.4), value: bleBannerPressed)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(bleBannerPressed ? 0.02 : 0.06),
                radius: bleBannerPressed ? 3 : 8, x: 0, y: bleBannerPressed ? 1 : 2)
        .scaleEffect(bleBannerPressed ? 0.975 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: bleBannerPressed)
        .onLongPressGesture(minimumDuration: 0.0, pressing: { pressing in
            bleBannerPressed = pressing
        }, perform: {
            showConnectDevice = true
        })
        .transition(.asymmetric(
            insertion: .scale(scale: 0.96).combined(with: .opacity),
            removal:   .scale(scale: 0.96).combined(with: .opacity)
        ))
    }

    // MARK: - Sim Toggle Row

    private var simToggleRow: some View {
        HStack(spacing: 10) {
            Image(systemName: sensorData.simulatedMode ? "waveform" : "dot.radiowaves.left.and.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(sensorData.simulatedMode ? .orange : .blue)
                .frame(width: 20)

            Text(sensorData.simulatedMode ? "Demo mode" : "Live sensor data")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(.secondaryLabel))

            Text("·")
                .foregroundColor(Color(.tertiaryLabel))

            Text(sensorData.statusMessage)
                .font(.system(size: 12))
                .foregroundColor(Color(.tertiaryLabel))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Toggle("", isOn: Binding(
                get: { sensorData.simulatedMode },
                set: { enabled in
                    enabled ? sensorData.startSimulation() : sensorData.stopSimulation()
                }
            ))
            .labelsHidden()
            .tint(.orange)
            .scaleEffect(0.85)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            sensorData.simulatedMode
                ? Color.orange.opacity(0.07)
                : Color.blue.opacity(0.06)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.2), value: sensorData.simulatedMode)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            MetricCard(
                icon: "drop.fill",
                iconColor: Color(red: 0.16, green: 0.50, blue: 0.95),
                iconBg: Color(red: 0.16, green: 0.50, blue: 0.95).opacity(0.12),
                label: "Hydration",
                value: lastHydration
            )
            MetricCard(
                icon: "waveform.path.ecg",
                iconColor: Color(red: 0.18, green: 0.72, blue: 0.48),
                iconBg: Color(red: 0.18, green: 0.72, blue: 0.48).opacity(0.12),
                label: "pH Level",
                value: lastPH
            )
            MetricCard(
                icon: "atom",
                iconColor: Color(red: 0.96, green: 0.55, blue: 0.14),
                iconBg: Color(red: 0.96, green: 0.55, blue: 0.14).opacity(0.12),
                label: "TDS",
                value: lastTDS
            )
        }
    }

    // MARK: - Primary Action Card

    private var primaryActionCard: some View {
        Button {
            if manualDoNotShowAgain {
                // Skip the checklist — go straight to the flow
                showUrinalysisFlow = true
            } else {
                // Show the pre-test checklist first;
                // its onProceed callback opens showUrinalysisFlow
                showPreTest = true
            }
        } label: {
            HStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 64, height: 64)
                    Image(systemName: "flask.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Urinalysis")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("Begin a new hydration test")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.42, blue: 0.85),
                        Color(red: 0.04, green: 0.62, blue: 0.82)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color(red: 0.10, green: 0.40, blue: 0.82).opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Secondary Actions Row

    private var secondaryActionsRow: some View {
        SecondaryActionCard(
            icon: "clock.arrow.circlepath",
            iconColor: Color(red: 0.16, green: 0.50, blue: 0.95),
            title: "History",
            subtitle: "Past results"
        ) {}
    }

    // MARK: - Tip Card

    private var tipCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.92, green: 0.60, blue: 0.10))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text("Pro tip")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.92, green: 0.60, blue: 0.10))
                    .textCase(.uppercase)
                    .kerning(0.5)
                Text("For best accuracy, collect a midstream urine sample in a clean, dry container before testing.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.10, green: 0.30, blue: 0.60))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.90, green: 0.95, blue: 1.0))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Subcomponents

private struct CircleHeaderButton: View {
    let icon: String
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(pressed ? 0.32 : 0.18))
                .clipShape(Circle())
                .scaleEffect(pressed ? 0.88 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.5), value: pressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false }
        )
    }
}

struct MetricCard: View {
    let icon: String
    let iconColor: Color
    let iconBg: Color
    let label: String
    let value: String

    @State private var pressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconBg)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                    .scaleEffect(pressed ? 0.78 : 1.0)
                    .animation(.spring(response: 0.28, dampingFraction: 0.45), value: pressed)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(.label))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(pressed ? 0.02 : 0.05), radius: pressed ? 2 : 6, x: 0, y: pressed ? 0 : 2)
        .scaleEffect(pressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false }
        )
    }
}

private struct SecondaryActionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 46, height: 46)
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(.label))
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Color(.secondaryLabel))
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(ArrowSlideButtonStyle())
    }
}

// MARK: - Button Styles

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(
                color: .black.opacity(configuration.isPressed ? 0.04 : 0.0),
                radius: configuration.isPressed ? 2 : 0
            )
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

private struct ArrowSlideButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: configuration.isPressed)
            .offset(x: configuration.isPressed ? 1 : 0)
    }
}

// MARK: - Preview

#Preview {
    MainMenuView()
        .environmentObject(BLEManager())
        .environmentObject(SensorDataManager())
}
