//
//  ArduinoPayload.swift
//  ArduinoUrinalysis
//
//  Created by Xavier Michael Emmanuel Novio Ombrog on 4/21/26.
//

struct ArduinoPayload: Decodable {
    let device: String
    let version: String
    let type: String
    let sensors: SensorBlock
}
