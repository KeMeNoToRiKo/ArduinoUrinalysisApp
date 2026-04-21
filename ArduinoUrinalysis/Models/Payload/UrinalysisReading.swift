//
//  UrinalysisReading.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/21/26.
//

import SwiftUI

struct UrinalysisReading {
    let device: String
    let timestamp: Date

    let tempC: Double
    let pH: Double
    let tdsPPM: Double
    let ecUSCm: Double

    let colorR: Int
    let colorG: Int
    let colorB: Int
    let colorHex: String
    let lux: Double
    let cct: Int

    // MARK: Display strings
    var tempDisplay: String      { String(format: "%.1f°C", tempC) }
    var phDisplay: String        { String(format: "%.2f", pH) }
    var tdsDisplay: String       { "\(Int(tdsPPM)) ppm" }
    var ecDisplay: String        { String(format: "%.1f µS/cm", ecUSCm) }
    var luxDisplay: String       { String(format: "%.0f lx", lux) }
    var cctDisplay: String       { "\(cct) K" }
    var colorSwiftUI: Color      { Color(red: Double(colorR)/255, green: Double(colorG)/255, blue: Double(colorB)/255) }

    // MARK: Derived interpretations
    var hydrationPercent: Double {
        // Estimate hydration from TDS: lower TDS = better hydrated
        // Normal urine TDS: 200–1200 ppm. Map to 0–100% inversely.
        let clamped = max(200, min(1200, tdsPPM))
        return (1 - (clamped - 200) / 1000) * 100
    }
    var hydrationDisplay: String { "\(Int(hydrationPercent))%" }

    var hydrationStatus: String {
        switch hydrationPercent {
        case 75...:  return "Well Hydrated"
        case 50..<75: return "Mildly Dehydrated"
        default:     return "Dehydrated"
        }
    }

    var phStatus: String {
        switch pH {
        case ..<4.5: return "Very Acidic"
        case 4.5..<6.0: return "Acidic"
        case 6.0..<7.5: return "Normal"
        case 7.5..<8.5: return "Slightly Alkaline"
        default: return "Very Alkaline"
        }
    }

    // MARK: - Parse from raw JSON data
    static func from(data: Data) -> UrinalysisReading? {
        do {
            let payload = try JSONDecoder().decode(ArduinoPayload.self, from: data)
            let s = payload.sensors
            
            return UrinalysisReading(
                device:    payload.device,
                timestamp: Date(),
                tempC:     s.temp_c,      // No more Double() casting needed
                pH:        s.pH,
                tdsPPM:    s.tds_ppm,
                ecUSCm:    s.ec_us_cm,
                colorR:    s.color.r,
                colorG:    s.color.g,
                colorB:    s.color.b,
                colorHex:  s.color.hex,
                lux:       s.color.lux,
                cct:       s.color.cct
            )
        } catch {
            print("[Sensor] Decoding error: \(error)") // This will tell you exactly what failed
            return nil
        }
    }

    // MARK: - Simulated reading
    static func simulated() -> UrinalysisReading {
        let tds = Double.random(in: 200...900)
        let ph  = Double.random(in: 5.5...7.5)
        let ec  = tds * 2.0
        let r   = Int.random(in: 180...230)
        let g   = Int.random(in: 160...200)
        let b   = Int.random(in: 60...110)
        return UrinalysisReading(
            device:    "URINE-TEST-001",
            timestamp: Date(),
            tempC:     Double.random(in: 23...37),
            pH:        ph,
            tdsPPM:    tds,
            ecUSCm:    ec,
            colorR:    r,
            colorG:    g,
            colorB:    b,
            colorHex:  String(format: "#%02X%02X%02X", r, g, b),
            lux:       Double.random(in: 800...1600),
            cct:       Int.random(in: 2800...4000)
        )
    }
}
