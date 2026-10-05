//
//  VictronBMVDecoder.swift
//  VehicleTelemetry
//
//  Decodes a decrypted Victron Battery Monitor Instant Readout payload into a
//  BatteryState. Field order, bit widths, scaling and NA sentinels follow the
//  official "Extra Manufacturer Data" spec (2022-12-14):
//
//    remaining minutes : 16 bits, unsigned, minutes,  NA 0xFFFF
//    voltage           : 16 bits, signed,   /100 V,   NA 0x7FFF
//    alarm reason      : 16 bits  (unused here)
//    aux input         : 16 bits  (unused here)
//    aux mode          :  2 bits  (unused here)
//    current           : 22 bits, signed,   /1000 A,  NA 0x3FFFFF
//    consumed Ah       : 20 bits, unsigned, -/10 Ah,  NA 0xFFFFF
//    state of charge   : 10 bits, unsigned, /10 %,    NA 0x3FF
//
//  Sentinel/NA readings become nil - never zero.
//

import Foundation

enum VictronBMVDecoder {
    static func decode(decrypted: Data, deviceID: String, timestamp: Date) -> BatteryState {
        var reader = BitReader(decrypted)

        let ttgRaw = reader.readUnsigned(16)
        let voltageRaw = reader.readUnsigned(16)
        _ = reader.readUnsigned(16)   // alarm reason (unused in V1)
        _ = reader.readUnsigned(16)   // aux input (unused in V1)
        _ = reader.readUnsigned(2)    // aux mode (unused in V1)
        let currentRaw = reader.readUnsigned(22)
        let consumedRaw = reader.readUnsigned(20)
        let socRaw = reader.readUnsigned(10)

        let timeRemaining = ttgRaw == 0xFFFF ? nil : Int(ttgRaw)

        let voltage: Double? = voltageRaw == 0x7FFF
            ? nil
            : Double(Int16(bitPattern: UInt16(truncatingIfNeeded: voltageRaw))) / 100.0

        let current: Double? = currentRaw == 0x3FFFFF
            ? nil
            : Double(signExtend(currentRaw, bits: 22)) / 1000.0

        let consumedAh: Double? = consumedRaw == 0xFFFFF
            ? nil
            : -Double(consumedRaw) / 10.0

        let stateOfCharge: Double? = socRaw == 0x3FF
            ? nil
            : Double(socRaw) / 10.0

        // The Battery Monitor does not broadcast power; VictronConnect derives it
        // as voltage x current. We derive it the same way only when both exist.
        let power: Double?
        if let voltage, let current {
            power = voltage * current
        } else {
            power = nil
        }

        return BatteryState(
            deviceID: deviceID,
            timestamp: timestamp,
            stateOfCharge: stateOfCharge,
            voltage: voltage,
            current: current,
            power: power,
            consumedAh: consumedAh,
            timeRemainingMinutes: timeRemaining
        )
    }

    private static func signExtend(_ raw: UInt32, bits: Int) -> Int {
        let signBit: UInt32 = 1 << (bits - 1)
        if raw & signBit != 0 {
            return Int(raw) - (1 << bits)
        }
        return Int(raw)
    }
}
