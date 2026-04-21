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
    @EnvironmentObject var bleManager: BLEManager
    @EnvironmentObject var sensorData: SensorDataManager

    @State private var showConnectDevice = false
    @State private var showUrinalysisFlow = false
    @State private var connectButtonPressed = false

    private var lastHydration: String { sensorData.latestReading?.hydrationDisplay ?? "--" }
    private var lastPH: String        { sensorData.latestReading?.phDisplay ?? "--" }
    private var lastSG: String        { sensorData.latestReading?.tdsDisplay ?? "--" }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good Morning,"
        case 12..<17: return "Good Afternoon,"
        case 17..<21: return "Good Evening,"
        default:      return "Good Night,"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection

                VStack(spacing: 20) {
                    simToggleBanner
                    statCards
                    startUrinalysisCard
                    viewHistoryCard
                    tipBanner
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 32)
                .background(Color(.systemGroupedBackground))
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $showConnectDevice) {
            //ConnectDeviceView()
                //.environmentObject(bleManager)
        }
        .fullScreenCover(isPresented: $showUrinalysisFlow) {
            //UrinalysisFlowView()
                //.environmentObject(bleManager)
                //.environmentObject(sensorData)
        }
        .onAppear {
            if sensorData.simulatedMode {
                sensorData.startSimulation()
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.22, green: 0.55, blue: 0.90),
                    Color(red: 0.00, green: 0.76, blue: 0.87)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(HeaderClipShape())
            .frame(height: 240)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                        Text(loggedInUsername.isEmpty ? "User" : loggedInUsername)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        headerIconButton(icon: "person.circle")

                        Button {
                            bleManager.disconnect()
                            loggedInUsername = ""
                            isLoggedIn = false
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 20)

                // Reactive BLE banner
                bluetoothBanner
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .scaleEffect(connectButtonPressed ? 0.96 : 1.0)
                    .onTapGesture {
                        if !bleManager.isConnected {
                            withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) {
                                connectButtonPressed = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    connectButtonPressed = false
                                }
                                showConnectDevice = true
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: bleManager.isConnected)
            }
        }
    }

    private func headerIconButton(icon: String) -> some View {
        Button { } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - BLE Banner (reacts to BLEManager state)
    @ViewBuilder
    private var bluetoothBanner: some View {
        if bleManager.isConnected {
            // Connected state — green banner (Image 3)
            HStack(spacing: 14) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Connected to \(bleManager.connectedName ?? "Arduino Device")")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Device ready for testing")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                }

                Spacer()

                // Disconnect
                Button {
                    bleManager.disconnect()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(red: 0.18, green: 0.50, blue: 0.18))
            .clipShape(RoundedRectangle(cornerRadius: 14))

        } else {
            // Disconnected state — blue banner (Image 1 / default)
            HStack(spacing: 14) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("No device connected")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Tap to connect a device to start testing")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Simulation Toggle Banner
    private var simToggleBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: sensorData.simulatedMode ? "play.circle.fill" : "antenna.radiowaves.left.and.right")
                .foregroundColor(sensorData.simulatedMode ? .orange : .blue)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text(sensorData.simulatedMode ? "Simulated Data Mode" : "Live BLE Data")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.label))
                Text(sensorData.statusMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { sensorData.simulatedMode },
                set: { enabled in
                    if enabled {
                        sensorData.startSimulation()
                    } else {
                        sensorData.stopSimulation()
                    }
                }
            ))
            .labelsHidden()
            .tint(.orange)
        }
        .padding(14)
        .background(
            sensorData.simulatedMode
                ? Color.orange.opacity(0.08)
                : Color.blue.opacity(0.08)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .animation(.easeInOut(duration: 0.2), value: sensorData.simulatedMode)
    }

    // MARK: - Stat Cards
    private var statCards: some View {
        HStack(spacing: 12) {
            StatCard(icon: "drop.halffull",      iconColor: .blue,   label: "Hydration",  value: lastHydration)
            StatCard(icon: "waveform.path.ecg",  iconColor: .green,  label: "pH",         value: lastPH)
            StatCard(icon: "atom",               iconColor: .orange, label: "TDS",        value: lastSG)
        }
    }

    // MARK: - Start Urinalysis Card
    private var startUrinalysisCard: some View {
        Button {
            showUrinalysisFlow = true
        } label: {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.16, green: 0.44, blue: 0.82),
                        Color(red: 0.22, green: 0.60, blue: 0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(alignment: .leading, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 64, height: 64)
                        Image(systemName: "flask.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }

                    Text("Start Urinalysis")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)

                    HStack {
                        Text("Begin a new hydration test")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - View History Card
    private var viewHistoryCard: some View {
        Button { } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 52, height: 52)
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("View History")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(.label))
                    Text("Access past test results")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(18)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tip Banner
    private var tipBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.orange)
                .font(.system(size: 18))
                .padding(.top, 1)

            Text("**Tip:** For best results, collect midstream urine sample in a clean container.")
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.10, green: 0.35, blue: 0.70))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(red: 0.87, green: 0.93, blue: 1.0))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(.label))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Header Clip Shape
struct HeaderClipShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r: CGFloat = 32
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - r, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: r, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.maxY - r),
            control: CGPoint(x: 0, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    MainMenuView()
        .environmentObject(BLEManager())
        .environmentObject(SensorDataManager())
}
