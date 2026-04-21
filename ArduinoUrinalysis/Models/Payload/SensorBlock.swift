//
//  SensorBlock.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/21/26.
//

struct SensorBlock: Decodable {
    let temp_c: Double   // Changed from String
    let pH: Double       // Changed from String
    let tds_ppm: Double  // Changed from String
    let ec_us_cm: Double // Changed from String
    let color: ColorBlock
}
