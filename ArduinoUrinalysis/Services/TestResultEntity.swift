//
//  TestResultEntity.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/13/26.
//

import Foundation
import SwiftData

@Model
public final class TestResultEntity {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date

    // MARK: - Ownership
    /// The UUID of the UserEntity who ran this test.
    public var userID: UUID
    /// Denormalised copy of the username at the time of the test.
    /// Kept separate so the label is still readable even if the account is deleted.
    public var username: String

    // MARK: - Test origin
    /// `true` when the reading came from simulated (demo) mode rather than a real device.
    public var isSimulated: Bool

    // MARK: - Raw sensor values
    public var tempC: Double
    public var pH: Double
    public var tdsPPM: Double
    public var ecUSCm: Double
    public var colorR: Int
    public var colorG: Int
    public var colorB: Int
    public var colorHex: String
    public var lux: Double
    public var cct: Int

    // MARK: - Derived / classified results
    public var hydrationPercent: Double
    /// "NORMAL" | "MILD DEHYDRATION" | "DEHYDRATED"
    public var overallStatus: String
    /// 0–100 confidence score produced by the classification algorithm.
    public var algorithmConfidence: Double
    public var recommendation: String
    public var deviceName: String

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        userID: UUID,
        username: String,
        isSimulated: Bool,
        tempC: Double,
        pH: Double,
        tdsPPM: Double,
        ecUSCm: Double,
        colorR: Int,
        colorG: Int,
        colorB: Int,
        colorHex: String,
        lux: Double,
        cct: Int,
        hydrationPercent: Double,
        overallStatus: String,
        algorithmConfidence: Double,
        recommendation: String,
        deviceName: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.userID = userID
        self.username = username
        self.isSimulated = isSimulated
        self.tempC = tempC
        self.pH = pH
        self.tdsPPM = tdsPPM
        self.ecUSCm = ecUSCm
        self.colorR = colorR
        self.colorG = colorG
        self.colorB = colorB
        self.colorHex = colorHex
        self.lux = lux
        self.cct = cct
        self.hydrationPercent = hydrationPercent
        self.overallStatus = overallStatus
        self.algorithmConfidence = algorithmConfidence
        self.recommendation = recommendation
        self.deviceName = deviceName
    }
}

// MARK: - Factory

extension TestResultEntity {

    /// Builds and returns a fully classified entity ready to be inserted into SwiftData.
    ///
    /// - Parameters:
    ///   - reading:      The raw sensor reading captured from BLE or simulation.
    ///   - user:         The `UserEntity` currently logged in.
    ///   - isSimulated:  Pass `true` when the reading came from `SensorDataManager.simulatedMode`.
    static func from(
        reading: UrinalysisReading,
        user: UserEntity,
        isSimulated: Bool
    ) -> TestResultEntity {
        let (status, confidence, recommendation) = classify(reading: reading)
        return TestResultEntity(
            timestamp:           reading.timestamp,
            userID:              user.id,
            username:            user.username,
            isSimulated:         isSimulated,
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
    }

    // MARK: - Classification algorithm (placeholder — replace with Fuzzy-KNN)

    /// Returns (status, confidence %, recommendation) for a given reading.
    /// Called on a background thread from `AnalyzingView` — must be pure / thread-safe.
    static func classify(
        reading: UrinalysisReading
    ) -> (status: String, confidence: Double, recommendation: String) {

        var scores: [Double] = []

        // pH: normal 6.0–7.5
        let phScore: Double
        switch reading.pH {
        case 6.0 ..< 7.5:  phScore = 1.0
        case 5.0 ..< 6.0,
             7.5 ..< 8.0:   phScore = 0.6
        default:            phScore = 0.2
        }
        scores.append(phScore)

        // TDS: normal 200–800 ppm
        let tdsScore: Double
        switch reading.tdsPPM {
        case 200 ..< 800:   tdsScore = 1.0
        case 800 ..< 1000:  tdsScore = 0.5
        default:            tdsScore = 0.1
        }
        scores.append(tdsScore)

        // EC: normal 400–1600 µS/cm
        let ecScore: Double
        switch reading.ecUSCm {
        case 400  ..< 1600: ecScore = 1.0
        case 1600 ..< 2000: ecScore = 0.5
        default:            ecScore = 0.1
        }
        scores.append(ecScore)

        // Color lightness via lux — higher lux → lighter colour → better hydrated
        let luxScore: Double
        switch reading.lux {
        case 1200...:       luxScore = 1.0
        case 800 ..< 1200:  luxScore = 0.65
        default:            luxScore = 0.3
        }
        scores.append(luxScore)

        let avg = scores.reduce(0, +) / Double(scores.count)

        // Confidence: base 75 % + up to 20 % from how much the parameters agree
        let variance = scores.map { pow($0 - avg, 2) }.reduce(0, +) / Double(scores.count)
        let spread   = sqrt(variance)
        let confidence = min(95, 75 + (1 - spread) * 20)

        let status: String
        let recommendation: String

        switch avg {
        case 0.75...:
            status = "NORMAL"
            recommendation = "Maintain current hydration levels by drinking water regularly throughout the day."
        case 0.45 ..< 0.75:
            status = "MILD DEHYDRATION"
            recommendation = "Increase fluid intake. Aim for at least 8 glasses of water per day and reduce caffeine."
        default:
            status = "DEHYDRATED"
            recommendation = "Significant dehydration detected. Drink water immediately and consult a healthcare provider if symptoms persist."
        }

        return (status, confidence, recommendation)
    }
}
