//
//  VictronRecordType.swift
//  VehicleTelemetry
//
//  Victron Instant Readout device/record types. Values are from the official
//  "Extra Manufacturer Data" spec (2022-12-14). V1 only decodes Battery Monitor;
//  the others are listed so diagnostics can label what it sees.
//

import Foundation

enum VictronRecordType: UInt8, Equatable {
    case solarCharger = 0x01
    case batteryMonitor = 0x02
    case inverter = 0x03
    case dcDcConverter = 0x04
    case smartLithium = 0x05
    case inverterRS = 0x06
    case acCharger = 0x08
    case smartBatteryProtect = 0x09
    case lynxSmartBMS = 0x0A
    case multiRS = 0x0B
    case veBusDevice = 0x0C
    case dcEnergyMeter = 0x0D
    case orionXS = 0x0F

    var displayName: String {
        switch self {
        case .solarCharger: return "Solar Charger"
        case .batteryMonitor: return "Battery Monitor"
        case .inverter: return "Inverter"
        case .dcDcConverter: return "DC/DC Converter"
        case .smartLithium: return "SmartLithium"
        case .inverterRS: return "Inverter RS"
        case .acCharger: return "AC Charger"
        case .smartBatteryProtect: return "Smart Battery Protect"
        case .lynxSmartBMS: return "Lynx Smart BMS"
        case .multiRS: return "Multi RS"
        case .veBusDevice: return "VE.Bus Device"
        case .dcEnergyMeter: return "DC Energy Meter"
        case .orionXS: return "Orion XS"
        }
    }
}
