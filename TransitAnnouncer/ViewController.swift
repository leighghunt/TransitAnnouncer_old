//
//  ViewController.swift
//  TransitAnnouncer
//
//  Created by Leigh Hunt on 26/03/21.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var labelStatus: UILabel!
    @IBOutlet weak var labelCoordinates: UILabel!
    @IBOutlet weak var labelHeading: UILabel!
    @IBOutlet weak var map: MKMapView!
    
    var manager: CLLocationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        if let metlinkApiKey = Bundle.main.infoDictionary?["METLINK_API_KEY"] as? String {
            print(metlinkApiKey)
        }

        if let metlinkGTFSStopsURL = Bundle.main.infoDictionary?["METLINK_GTFS_STOPS_URL"] as? String {
            print(metlinkGTFSStopsURL)
        }
        
        labelStatus.text="Locating..."
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()

    }

    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        print(newHeading.trueHeading)
        
        labelHeading.text = String(Int(newHeading.trueHeading))

    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else{
            labelCoordinates.text = "Nope"
            return
        }
        
        labelStatus.text="Located"
        
        labelCoordinates.text = "\(last.coordinate.longitude) | \(last.coordinate.latitude)"
        let pin = MKPointAnnotation()
        pin.coordinate = last.coordinate

//        map.setRegion(MKCoordinateRegion(center: last.coordinate, latitudinalMeters: 100, longitudinalMeters: 500), animated: true)
        map.setCenter(last.coordinate, animated: true)
        map.addAnnotation(pin)
    }
}

