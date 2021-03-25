//
//  distanceHelper.swift
//  test2
//
//  Created by Leigh Hunt on 25/03/21.
//

//  Inspired by https://richlloydmiles.medium.com/calculate-the-distance-between-two-points-on-earth-using-javascript-38e12c9a0f52


import Foundation
import CoreLocation

func degreesToRadians(_ degrees: Double) -> Double {
    return degrees * .pi / 180
}

func radiansToDegrees(_ radians: Double) -> Double {
    return radians * (180 / .pi)
}

func centralSubtendedAngle(_ locationX: CLLocationCoordinate2D, _ locationY: CLLocationCoordinate2D) -> Double {
    let locationXLatRadians = degreesToRadians(locationX.latitude)
    let locationYLatRadians = degreesToRadians(locationY.latitude)
return radiansToDegrees(
    acos(
      sin(locationXLatRadians) * sin(locationYLatRadians) +
        cos(locationXLatRadians) *
          cos(locationYLatRadians) *
          cos(
            degreesToRadians(
              abs(locationX.longitude - locationY.longitude)
            )
       )
    )
  )
}

let earthRadius = 6371.0    //km
func greatCircleDistance(_ angle: Double) -> Double {
    return 2.0 * .pi * earthRadius * (angle / 360.0)
}

func distance(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Double{
    return greatCircleDistance(centralSubtendedAngle(a, b)) * 1000
}
