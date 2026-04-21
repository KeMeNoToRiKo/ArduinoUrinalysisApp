//
//  DisclaimerView.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 2/22/26.
//

import SwiftUI

struct DisclaimerView: View {
    @AppStorage("disclaimerAccepted") private var disclaimerAccepted: Bool = false
    private let usableWidthRatio: CGFloat = 0.9
    private let usableWidthBtn: CGFloat = 0.6
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let totalWidth = geometry.size.width
            //let totalHeight = geometry.size.height
            let horizontalPadding = (1 - usableWidthRatio) * totalWidth / 2
            let horizontalBtnPadding = (1 - usableWidthBtn) * totalWidth / 2

            VStack(spacing: geometry.size.height * 0.05) {
                Spacer()
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size/4, height: size/4)
                    .foregroundColor(.orange)
                    .padding()
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
                   
                
                VStack(spacing: 12) {
                    Text("This device is for screening purposes only and does not replace professional medical advice, diagnosis, or treatment.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            

                    Text("Always consult with a qualified healthcare provider regarding any medical concerns or conditions.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.blue.opacity(0.15))
                .cornerRadius(20)
                .padding(.horizontal, horizontalPadding)
                
                VStack(spacing: 12) {
                    Text("Important:")
                        .foregroundColor(.red)
                        .fontWeight(.bold)

                    Text("This app is designed for preliminary screening and hydration monitoring. Abnormal results should be confirmed by laboratory testing.")
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.yellow.opacity(0.3))
                .cornerRadius(20)
                .padding(.horizontal, horizontalPadding)

                //Spacer()
                    
                VStack(spacing: 15) {
                                
                                Button {
                                    disclaimerAccepted = true
                                } label: {
                                    Text("Agree & Continue")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(15)
                                }

                                Button {
                                    exit(0)
                                } label: {
                                    Text("Disagree")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(.red)
                                        .cornerRadius(15)
                                }
                            }
                            .padding(.bottom, 30)
                            .padding(.horizontal, horizontalBtnPadding)
                
                
                    
            }
            
        }
        
    }
}

#Preview {
    DisclaimerView()
}
