//
//  ConnectDeviceView.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/12/26.
//

import SwiftUI

struct ConnectDeviceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var bleManager: BLEManager

    @State private var appearedIDs: Set<UUID> = []
    @State private var connectedCheckScale: CGFloat = 0.4
    @State private var connectedCheckOpacity: Double = 0
    @State private var connectedRingScale: CGFloat = 0.6
    @State private var connectedRingOpacity: Double = 0

    var body: some View {
        // VStack layout: header sits above the ScrollView as a sibling, not a floating
        // overlay. This gives the ScrollView the full remaining height and, crucially,
        // lets the user start a scroll drag anywhere in the list area.
        VStack(spacing: 0) {
            headerSection

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    scanButton

                    switch bleManager.connectionState {
                    case .poweredOff:
                        warningCard(
                            icon: "antenna.radiowaves.left.and.right.slash",
                            color: .orange,
                            title: "Bluetooth is Off",
                            message: "Enable Bluetooth in Settings or Control Center to scan for devices."
                        )
                    case .unauthorized:
                        warningCard(
                            icon: "hand.raised.slash.fill",
                            color: .red,
                            title: "Permission Required",
                            message: "Allow Bluetooth access in Settings → Privacy → Bluetooth."
                        )
                    case .unsupported:
                        warningCard(
                            icon: "exclamationmark.triangle.fill",
                            color: .red,
                            title: "Not Supported",
                            message: "This device doesn't support Bluetooth Low Energy."
                        )
                    case .connected:
                        connectedBanner
                    case .connecting:
                        connectingBanner
                    default:
                        deviceSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .onChange(of: bleManager.discoveredPeripherals.count) { _, _ in
                animateNewDevices()
            }
            .onChange(of: bleManager.connectionState) { _, newState in
                if case .connected = newState { animateConnected() }
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack(alignment: .bottom) {
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
                .fill(Color.white.opacity(0.07))
                .frame(width: 200, height: 200)
                .offset(x: 120, y: -10)
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 130, height: 130)
                .offset(x: -90, y: 30)

            HStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Image(systemName: bleManager.isConnected
                          ? "checkmark.circle.fill"
                          : "antenna.radiowaves.left.and.right")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .contentTransition(.symbolEffect(.replace))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Connect Device")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text(bleManager.isConnected
                         ? "Connected to \(bleManager.connectedName ?? "Arduino Device")"
                         : "Find your Arduino sensor via Bluetooth")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                        .animation(.easeInOut(duration: 0.25), value: bleManager.isConnected)
                }

                Spacer()

                Button("Done") { dismiss() }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 22)
            .padding(.top, 56)
            .padding(.bottom, 18)
        }
        .frame(height: 190)
    }

    // MARK: - Scan Button

    private var scanButton: some View {
        Button {
            if bleManager.isScanning {
                bleManager.stopScanning()
            } else {
                appearedIDs.removeAll()
                bleManager.startScanning()
            }
        } label: {
            HStack(spacing: 10) {
                if bleManager.isScanning {
                    ProgressView().tint(.white).scaleEffect(0.9)
                    Text("Scanning…").font(.system(size: 16, weight: .bold))
                } else {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 15, weight: .bold))
                    Text("Scan for Devices").font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        bleManager.isScanning
                            ? Color(red: 0.13, green: 0.32, blue: 0.70).opacity(0.75)
                            : Color(red: 0.13, green: 0.32, blue: 0.70)
                    )
            )
            .shadow(color: Color.blue.opacity(0.25), radius: 6, x: 0, y: 3)
            .animation(.easeInOut(duration: 0.2), value: bleManager.isScanning)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Device Section

    @ViewBuilder
    private var deviceSection: some View {
        if bleManager.discoveredPeripherals.isEmpty {
            if bleManager.isScanning { scanningEmptyState } else { instructionsCard }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Available Devices")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(.label))
                    Spacer()
                    Text("\(bleManager.discoveredPeripherals.count) found")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
                .padding(.top, 4)

                ForEach(Array(bleManager.discoveredPeripherals.enumerated()), id: \.element.id) { _, device in
                    DeviceRow(device: device) {
                        bleManager.connect(to: device)
                    }
                    .opacity(appearedIDs.contains(device.id) ? 1 : 0)
                    .offset(y: appearedIDs.contains(device.id) ? 0 : 14)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: bleManager.discoveredPeripherals.count)
        }
    }

    // MARK: - Scanning Empty State

    private var scanningEmptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.blue.opacity(0.08)).frame(width: 72, height: 72)
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
            }
            VStack(spacing: 6) {
                Text("Looking for devices…")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(.label))
                Text("Make sure your Arduino is powered on and nearby.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    // MARK: - Instructions Card

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "list.number")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.13, green: 0.32, blue: 0.70))
                Text("How to connect")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(red: 0.13, green: 0.32, blue: 0.70))
            }

            let steps: [(String, String)] = [
                ("power", "Power on your Arduino device"),
                ("iphone.and.arrow.forward", "Enable Bluetooth on this phone"),
                ("antenna.radiowaves.left.and.right", "Tap \"Scan for Devices\" above"),
                ("hand.tap", "Select your device from the list")
            ]

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.13, green: 0.32, blue: 0.70).opacity(0.12))
                            .frame(width: 30, height: 30)
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 0.13, green: 0.32, blue: 0.70))
                    }
                    Text(step.1)
                        .font(.system(size: 14))
                        .foregroundColor(Color(.label))
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.87, green: 0.93, blue: 1.0))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Connecting Banner

    private var connectingBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.blue.opacity(0.1)).frame(width: 44, height: 44)
                ProgressView().tint(.blue).scaleEffect(0.9)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Connecting…")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(.label))
                Text("Establishing Bluetooth connection")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.secondaryLabel))
            }
            Spacer()
        }
        .padding(16)
        .background(Color.blue.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Connected Banner

    private var connectedBanner: some View {
        VStack(spacing: 12) {
            // Main card
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.56, blue: 0.26),
                        Color(red: 0.10, green: 0.72, blue: 0.42)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // Decorative blobs
                Circle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 140, height: 140)
                    .offset(x: 90, y: -30)
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 80, height: 80)
                    .offset(x: -70, y: 40)

                VStack(spacing: 18) {
                    // Animated checkmark + ripple
                    ZStack {
                        // Outer ripple ring
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 2)
                            .frame(width: 88, height: 88)
                            .scaleEffect(connectedRingScale)
                            .opacity(connectedRingOpacity)

                        // Icon background
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 72, height: 72)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundColor(.white)
                            .scaleEffect(connectedCheckScale)
                            .opacity(connectedCheckOpacity)
                    }

                    // Status text
                    VStack(spacing: 4) {
                        Text("Successfully Connected")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Text(bleManager.connectedName ?? "Arduino Device")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }

                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 1)
                        .padding(.horizontal, 4)

                    // Status row
                    HStack(spacing: 0) {
                        statusPill(icon: "dot.radiowaves.right", label: "BLE Active")
                        Spacer()
                        statusPill(icon: "bolt.fill", label: "Ready to Test")
                        Spacer()
                        statusPill(icon: "lock.shield.fill", label: "Secure")
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
            .shadow(
                color: Color(red: 0.08, green: 0.56, blue: 0.26).opacity(0.40),
                radius: 18, x: 0, y: 8
            )

            // Action buttons row
            HStack(spacing: 10) {
                // Disconnect
                Button {
                    bleManager.disconnect()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Disconnect")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Color(.secondaryLabel))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                // Done
                Button { dismiss() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                        Text("Done")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.08, green: 0.56, blue: 0.26), Color(red: 0.10, green: 0.72, blue: 0.42)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.green.opacity(0.30), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    // Small pill used in the connected card
    private func statusPill(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.15))
        .clipShape(Capsule())
    }

    // MARK: - Warning Card

    private func warningCard(icon: String, color: Color, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: icon).font(.system(size: 18)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(Color(.label))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Connected card entrance animation

    private func animateConnected() {
        connectedCheckScale = 0.4
        connectedCheckOpacity = 0
        connectedRingScale = 0.6
        connectedRingOpacity = 0

        withAnimation(.spring(response: 0.45, dampingFraction: 0.58).delay(0.05)) {
            connectedCheckScale = 1.0
            connectedCheckOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
            connectedRingScale = 1.5
            connectedRingOpacity = 0
        }
    }

    // MARK: - Staggered appear animation

    private func animateNewDevices() {
        for (index, device) in bleManager.discoveredPeripherals.enumerated() {
            guard !appearedIDs.contains(device.id) else { continue }
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.06) {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                    _ = appearedIDs.insert(device.id)
                }
            }
        }
    }
}

// MARK: - Device Row

struct DeviceRow: View {
    let device: DiscoveredPeripheral
    let onConnect: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(signalColor.opacity(0.2), lineWidth: 3)
                    .frame(width: 46, height: 46)
                Circle()
                    .trim(from: 0, to: CGFloat(device.signalPercent) / 100)
                    .stroke(signalColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 46, height: 46)
                    .rotationEffect(.degrees(-90))
                Image(systemName: "dot.radiowaves.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(signalColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(device.name ?? "Unknown Device")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Circle().fill(signalColor).frame(width: 6, height: 6)
                    Text("\(device.signalPercent)% signal")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.secondaryLabel))
                }
            }

            Spacer()

            Button(action: onConnect) {
                Text("Connect")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Color(red: 0.13, green: 0.32, blue: 0.70))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private var signalColor: Color {
        switch device.signalPercent {
        case 65...: return .green
        case 35...: return .orange
        default:    return .red
        }
    }
}

#Preview {
    ConnectDeviceView()
        .environmentObject(BLEManager())
}
