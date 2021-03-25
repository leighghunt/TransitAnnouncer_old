// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let stops = try? newJSONDecoder().decode(Stops.self, from: jsonData)

import Foundation

// MARK: - Stop
struct Stop: Codable {
    let id: Int
    let stopID, stopCode, stopName, stopDesc: String
    let zoneID: String
    let stopLat, stopLon: Double
    let locationType: Int
    let parentStation: ParentStation
    let stopURL: String
    let stopTimezone: StopTimezone

    enum CodingKeys: String, CodingKey {
        case id
        case stopID = "stop_id"
        case stopCode = "stop_code"
        case stopName = "stop_name"
        case stopDesc = "stop_desc"
        case zoneID = "zone_id"
        case stopLat = "stop_lat"
        case stopLon = "stop_lon"
        case locationType = "location_type"
        case parentStation = "parent_station"
        case stopURL = "stop_url"
        case stopTimezone = "stop_timezone"
    }
}

struct StopWithDistance {
    let stop: Stop
    let distance: Int
}

enum ParentStation: String, Codable {
    case empty = ""
    case khan = "KHAN"
    case mana = "MANA"
    case ngai = "NGAI"
    case paek = "PAEK"
    case para = "PARA"
    case peto = "PETO"
    case plim = "PLIM"
    case pori = "PORI"
    case redw = "REDW"
    case tait = "TAIT"
    case taka = "TAKA"
    case tawa = "TAWA"
    case wate = "WATE"
    case wobu = "WOBU"
}

enum StopTimezone: String, Codable {
    case empty = ""
    case pacificAuckland = "Pacific/Auckland"
}

typealias Stops = [Stop]
typealias StopsWithDistance = [StopWithDistance]
