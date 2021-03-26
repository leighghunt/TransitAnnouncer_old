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
    
    var metlinkApiKey: String = ""
    var metlinkGTFSStopsURL: String = ""
    var stops: Stops = Stops()
    var nearestStops: StopsWithDistance = StopsWithDistance()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        if let metlinkApiKey = Bundle.main.infoDictionary?["METLINK_API_KEY"] as? String {
//            print(metlinkApiKey)
            self.metlinkApiKey = metlinkApiKey
        }

        if let metlinkGTFSStopsURL = Bundle.main.infoDictionary?["METLINK_GTFS_STOPS_URL"] as? String {
//            print(metlinkGTFSStopsURL)
            self.metlinkGTFSStopsURL = metlinkGTFSStopsURL
        }
        
        labelStatus.text="Locating..."
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
        
        loadStops()
    }

    func loadStops(){
        let url = URL(string: metlinkGTFSStopsURL)!
        var request = URLRequest(url: url)
                
        request.addValue(
            self.metlinkApiKey,
            forHTTPHeaderField: "x-api-key"
        )
        
        print("Loading stops...")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in

            if let error = error {
                // Handle HTTP request error
                print("Error accessing \(self.metlinkGTFSStopsURL): \(error)")
                return
            } else if let data = data {
                print("Loaded stops.")
                // Handle HTTP request response
                if let decodedResponse = try? JSONDecoder().decode(Stops.self, from: data) {
                    // we have good data – go back to the main thread
                    DispatchQueue.main.async {
                        // update our UI
                        print("Updating stops.")

                        self.stops = decodedResponse
                    }

                    // everything is good, so we can exit
                    return
                }
            } else {
                // if we're still here it means there was a problem
                print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        task.resume()

    }
    
    func findNearestStops(){
        let distanceCutOff = 100
        
        labelStatus.text = "Finding nearest stops..."

        if let location = self.manager.location{
            
            nearestStops.removeAll()
            
            for stop in stops{
                let stopCoordinate = CLLocationCoordinate2D(latitude: stop.stopLat, longitude: stop.stopLon)
                
                let distanceMetres = Int(distance(a: location.coordinate, b: stopCoordinate))

                if(distanceMetres<=distanceCutOff){
                    nearestStops.append(StopWithDistance(stop: stop, distance: distanceMetres))
                }
            }
            for stopWithDistance in nearestStops{
                print("\(stopWithDistance.stop.stopCode) \(stopWithDistance.stop.stopName) \(stopWithDistance.distance)")
            }

            // Order
            if let nearestStop = nearestStops.sorted(by: { $0.distance < $1.distance }).first{
                let summary = "There are \(self.nearestStops.count) stops within \(distanceCutOff) metres. \nNearest stop is \(nearestStop.stop.stopCode) \(nearestStop.stop.stopName) \nIt is \(nearestStop.distance) metres away."
                print(summary)
                labelStatus.text = summary
            }
            


        } else {

        }
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
        
//        if(nearestStops.count == 0){
        findNearestStops()
//        }
    }
}

