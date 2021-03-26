//
//  ViewController.swift
//  TransitAnnouncer
//
//  Created by Leigh Hunt on 26/03/21.
//

import UIKit
import CoreLocation
import MapKit
import Speech
import AVKit

class ViewController: UIViewController, CLLocationManagerDelegate, AVSpeechSynthesizerDelegate {

    @IBOutlet weak var labelStatus: UILabel!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var labelNear: UILabel!
    @IBOutlet weak var labelNearest: UILabel!
    @IBOutlet weak var labelDistance: UILabel!
    
    var manager: CLLocationManager = CLLocationManager()
    var synth=AVSpeechSynthesizer()

    var metlinkApiKey: String = ""
    var metlinkGTFSStopsURL: String = ""
    var metlinkGTFSStopPredictionURL: String = ""
    var stops: Stops = Stops()
    var stopPredictions: StopPredictions? = nil
    var nearestStops: StopsWithDistance = StopsWithDistance()
    var prevNearestStop: Stop? = nil

    let pinMe = MKPointAnnotation()
    let pinNearestStop = MKPointAnnotation()
    var mapZoomed = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        if let metlinkApiKey = Bundle.main.infoDictionary?["METLINK_API_KEY"] as? String {
            self.metlinkApiKey = metlinkApiKey
        }

        if let metlinkGTFSStopsURL = Bundle.main.infoDictionary?["METLINK_GTFS_STOPS_URL"] as? String {
            self.metlinkGTFSStopsURL = metlinkGTFSStopsURL
        }

        if let metlinkGTFSStopPredictionURL = Bundle.main.infoDictionary?["METLINK_GTFS_STOP_PREDICTION_URL"] as? String {
            self.metlinkGTFSStopPredictionURL = metlinkGTFSStopPredictionURL
        }

        labelStatus.text="Locating..."
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()

        map.mapType = .hybridFlyover

        synth.delegate = self

        // Allow other sounds to carry on
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers /*.interruptSpokenAudioAndMixWithOthers*/ /*.mixWithOthers*/])
        
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
                        self.findNearestStops()
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

                nearestStops.append(StopWithDistance(stop: stop, distance: distanceMetres))
            }

            nearestStops.sort(by: { $0.distance < $1.distance })

            for stopWithDistance in nearestStops{
                print("\(stopWithDistance.stop.stopCode) \(stopWithDistance.stop.stopName) \(stopWithDistance.distance)m")
            }

            var stopCodes = ""
            nearestStops.forEach{stop in
                stopCodes += stop.stop.stopCode + ", "
            }
            
            if(stopCodes.count>0){
                stopCodes = String(stopCodes.prefix(stopCodes.count-1))
            }

            labelNear.text = stopCodes

            if let nearestStop = nearestStops.first{
                let stopsWithinDistanceCutOff = self.nearestStops.filter{stop in return stop.distance <= distanceCutOff}.count
                let summary = "There are \(stopsWithinDistanceCutOff) stops within \(distanceCutOff) metres. \nNearest stop is \(nearestStop.stop.stopCode) \(nearestStop.stop.stopName) \nIt is \(nearestStop.distance) metres away."
                print(summary)
                labelStatus.text = summary
                
                var nearestStopChanged = false
                if let prevNearestStopId = prevNearestStop?.stopID{
                    if(nearestStop.stop.stopID != prevNearestStopId){
                        
                        // Let's make sure we're at least a fair bit closer before we swap over.
                        if(nearestStops.count == 1 || nearestStop.distance < Int(Double(nearestStops[1].distance) * 0.7)){
                            nearestStopChanged=true
                        }
                        
                    }
                } else {
                    // First time we've found a nearest stop
                    nearestStopChanged=true
                    map.addAnnotation(pinNearestStop)
                }
                
                labelDistance.text = "\(nearestStop.distance)m"

                if(nearestStopChanged){
                    prevNearestStop = nearestStop.stop
                    pinNearestStop.coordinate = CLLocationCoordinate2DMake(nearestStop.stop.stopLat, nearestStop.stop.stopLon)

                    print(nearestStop.stop.stopName)

                    let utterance = AVSpeechUtterance(string:"Nearest stop is now \(nearestStop.stop.stopName)")
                    labelNearest.text = "\(nearestStop.stop.stopCode) \(nearestStop.stop.stopName)"
                    synth.speak(utterance)

                    loadStopPredictions(stop_id: nearestStop.stop.stopCode)
                    
                }
            }
        } else {

        }
    }
    
    func loadStopPredictions(stop_id: String){
//        let url = URL(string: metlinkGTFSStopPredictionURL)!
        var url = URLComponents(string: metlinkGTFSStopPredictionURL)!
        url.queryItems = [
            URLQueryItem(name: "stop_id", value: stop_id)
        ]
//        url.queryItems?.append(URLQueryItem(name: "stop_id", value: stop_id))
        var request = URLRequest(url: url.url!)
                
        request.addValue(
            self.metlinkApiKey,
            forHTTPHeaderField: "x-api-key"
        )
    
//        print(url.url?.absoluteString)
        
        print("Loading stop predcitions...")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in

            if let error = error {
                // Handle HTTP request error
                print("Error accessing \(self.metlinkGTFSStopsURL): \(error)")
                return
            } else if let data = data {
                print("Loaded stop predictions.")
                // Handle HTTP request response
                do{
                    let decodedResponse = try JSONDecoder().decode(StopPredictions.self, from: data)
                        // we have good data – go back to the main thread
                        DispatchQueue.main.async {
                            // update our UI
                            print("Updating stop predictions.")

                            self.stopPredictions = decodedResponse
                        }

                        // everything is good, so we can exit
                        return
                    
                } catch let jsonError as NSError {
                    print("JSON decode failed: \(jsonError.localizedDescription)")
                }
            } else {
                // if we're still here it means there was a problem
                print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        task.resume()
    }
        
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        guard !synthesizer.isSpeaking else { return }

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        print(newHeading.trueHeading)
        
//        labelHeading.text = String(Int(newHeading.trueHeading))

    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else{
//            labelCoordinates.text = "Nope"
            return
        }
        
        if(last.speed>2){
            // greater than 2m/s = 7kph - over walking pace
            labelStatus.text="Moving > walking pace"
            return
        }
        
        labelStatus.text="Located"
        
//        labelCoordinates.text = "\(last.coordinate.longitude) | \(last.coordinate.latitude)"
        
        pinMe.coordinate = last.coordinate

        if(!mapZoomed){
            mapZoomed=true
            map.setRegion(MKCoordinateRegion(center: last.coordinate, latitudinalMeters: 100, longitudinalMeters: 100), animated: true)
    //        map.setCenter(last.coordinate, animated: true)
            map.addAnnotation(pinMe)
        }

        findNearestStops()
    }
}

