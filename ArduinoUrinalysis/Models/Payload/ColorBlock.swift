//
//  ColorBlock.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/21/26.
//

struct ColorBlock: Decodable {
    let r: Int
    let g: Int
    let b: Int
    let hex: String
    let lux: Double      // Changed from String
    let cct: Int
}
