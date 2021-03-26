// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let stopPredictions = try? newJSONDecoder().decode(StopPredictions.self, from: jsonData)

import Foundation

// MARK: - StopPredictions
struct StopPredictions: Codable {
    let farezone: String
    let closed: Bool
    let departures: [Departure]
}

// MARK: - Departure
struct Departure: Codable {
    let stopID, serviceID, direction, departureOperator: String
    let origin, destination: Destination
    let delay: String
    let vehicleID: String?
    let name: String
    let arrival, departure: Arrival
    let status: String?
    let monitored, wheelchairAccessible: Bool

    enum CodingKeys: String, CodingKey {
        case stopID
        case serviceID
        case direction
        case departureOperator
        case origin, destination, delay
        case vehicleID
        case name, arrival, departure, status, monitored
        case wheelchairAccessible
    }
}

// MARK: - Arrival
struct Arrival: Codable {
    let aimed: Date
    let expected: Date?
}

// MARK: - Destination
struct Destination: Codable {
    let stopID, name: String

    enum CodingKeys: String, CodingKey {
        case stopID
        case name
    }
}
