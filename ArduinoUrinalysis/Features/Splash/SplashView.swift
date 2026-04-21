//
//  SplashView.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/12/26.
//


import SwiftUI

struct SplashView: View {
    @Binding var isFinished: Bool

    @State private var dotOpacities: [Double] = [1, 1, 1]
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            // MARK: - Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.22, green: 0.55, blue: 0.90),
                    Color(red: 0.00, green: 0.76, blue: 0.87)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // MARK: - Logo
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 160, height: 160)
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)

                    // Water drop shape
                    WaterDropShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.22, green: 0.55, blue: 0.90),
                                    Color(red: 0.00, green: 0.76, blue: 0.87)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 72, height: 90)
                        .overlay(
                            // Inner shine
                            Ellipse()
                                .fill(Color.white.opacity(0.35))
                                .frame(width: 20, height: 30)
                                .offset(x: -10, y: -18)
                        )
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // MARK: - Text
                VStack(spacing: 8) {
                    Text("Smart Urinalysis")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)

                    Text("Monitor")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                }
                .opacity(textOpacity)

                // MARK: - Animated dots
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .opacity(dotOpacities[i])
                    }
                }
                .padding(.top, 8)
                .opacity(textOpacity)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            // Animate logo in
            withAnimation(.easeOut(duration: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            // Fade text in slightly after
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                textOpacity = 1.0
            }
            // Start dot pulse loop
            animateDots()
            // Dismiss splash after 2.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    isFinished = true
                }
            }
        }
    }

    // MARK: - Dot pulse animation
    private func animateDots() {
        for i in 0..<3 {
            withAnimation(
                Animation
                    .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                    .delay(Double(i) * 0.2)
            ) {
                dotOpacities[i] = 0.25
            }
        }
    }
}

// MARK: - Water drop shape
struct WaterDropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = rect.midX

        // Starts at the tip (top centre), curves down and out to a rounded bottom
        path.move(to: CGPoint(x: cx, y: 0))
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.65),
            control1: CGPoint(x: cx + w * 0.6, y: h * 0.15),
            control2: CGPoint(x: w, y: h * 0.45)
        )
        path.addArc(
            center: CGPoint(x: cx, y: h * 0.65),
            radius: w / 2,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: false
        )
        path.addCurve(
            to: CGPoint(x: cx, y: 0),
            control1: CGPoint(x: 0, y: h * 0.45),
            control2: CGPoint(x: cx - w * 0.6, y: h * 0.15)
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    SplashView(isFinished: .constant(false))
}
