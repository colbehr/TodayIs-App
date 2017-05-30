//
//  ViewController.swift
//  TodayIs
//
//  Created by Jonathan Cho on 5/11/17.
//  Copyright © 2017 Coding Dojo. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
class ViewController: UIViewController {
    var celebrationMarker = 0
    var today = Date()
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var celebrationLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    var resultSearchController:UISearchController? = nil
    let locationManager = CLLocationManager()
    var selectedPin:MKPlacemark? = nil  //caches any incoming placemarks
    var currentCelebration: String = ""
    //creates an instance of allData to be used in this class
    let data = allData()
    //PolyLine for route when created
    var polyline = MKPolyline()
    
    @IBOutlet weak var searchBarHolder: UIView!

    func displayCelebration(){
        if((data.Days[today.toString().lowercased()]) != nil){
            
            currentCelebration = (data.Days[today.toString().lowercased()]?[celebrationMarker][0])!.capitalized
            celebrationLabel.text = currentCelebration
            // this next bit chops off the "National" and "Day" characters to populate the search bar
            if currentCelebration.range(of:"National") != nil{
                currentCelebration = currentCelebration.toLengthOf(length: 9)
            }
            if currentCelebration.range(of:"Day") != nil{
                let endIndex = currentCelebration.index(currentCelebration.endIndex, offsetBy: -4)
                currentCelebration = currentCelebration.substring(to: endIndex)
            }
        } else {
            celebrationLabel.text = "No Days Avalible"
            currentCelebration = "no"
        }
    }
    
    func displayDate(){
        dateLabel.text = today.toString()
        displayCelebration()
    }
    
    func initiateSearchBar(){
        //      set up the search bar, configures it and embeds it within the navigation bar
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        if(currentCelebration != "no"){
            resultSearchController!.searchBar.placeholder = "Find \(currentCelebration) near you"
        } else {
            resultSearchController!.searchBar.placeholder = "No Data"
        }

        searchBar.backgroundColor = UIColor.clear
        searchBar.backgroundImage = nil
        searchBarHolder.backgroundColor = UIColor.clear
        searchBar.tintColor = UIColor.clear
        searchBar.barTintColor = UIColor(red:0.93,green:0.51,blue:0.23,alpha:1.0)
        searchBarHolder.addSubview(searchBar)
        self.searchBarHolder.layer.zPosition = 10
    }
    
    @IBAction func dateNext(_ sender: UIButton) {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)
        today = tomorrow!
        celebrationMarker = 0
        displayDate()
        if(currentCelebration != "no"){
            resultSearchController!.searchBar.placeholder = "Find \(currentCelebration) near you"
        } else {
            resultSearchController!.searchBar.placeholder = "No Data"
        }
    }
    
    @IBAction func datePrev(_ sender: UIButton) {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)
        today = yesterday!
        celebrationMarker = 0
        displayDate()
        if(currentCelebration != "no"){
            resultSearchController!.searchBar.placeholder = "Find \(currentCelebration) near you"
        } else {
            resultSearchController!.searchBar.placeholder = "No Data"
        }
    }
    
    @IBAction func celebrationNext(_ sender: UIButton) {
        celebrationMarker += 1
        if(data.Days[today.toString().lowercased()] != nil){
        if(celebrationMarker >= data.Days[today.toString().lowercased()]!.count){
            celebrationMarker = 0
        }}
        displayCelebration()
        if(currentCelebration != "no"){
            resultSearchController!.searchBar.placeholder = "Find \(currentCelebration) near you"
        } else {
            resultSearchController!.searchBar.placeholder = "No Data"
        }
    }
    
    @IBAction func celebrationPrev(_ sender: UIButton) {
        celebrationMarker -= 1
        if(celebrationMarker < 0 && data.Days[today.toString().lowercased()] != nil){
            celebrationMarker = (data.Days[today.toString().lowercased()]!.count-1)
        }
        displayCelebration()
        if(currentCelebration != "no"){
            resultSearchController!.searchBar.placeholder = "Find \(currentCelebration) near you"
        } else {
            resultSearchController!.searchBar.placeholder = "No Data"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "seeDetails" {
            let detailViewController = segue.destination as! DetailsViewController
            detailViewController.passText = data.Days[today.toString().lowercased()]?[celebrationMarker][1].chopPrefix(7)
            detailViewController.passTitle = "National \(currentCelebration) Day"
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        displayDate()
        mapView.layer.masksToBounds = true
        mapView.layer.cornerRadius = 10
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        mapView.delegate=self
        
        //      set-up the search results table:
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        
        //      passes along a handle of the mapView from the main View Controller onto the locationSearchTable
        locationSearchTable.mapView = mapView
        
        initiateSearchBar()
        
        //      configure the UISearchController's appearance
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        //      The parent (ViewController) passes a handle of itself to the child controller (LocationSearchTable)
        locationSearchTable.handleMapSearchDelegate = self
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func drawRoute(_ UserLoc: CLLocation, destPin: CLLocation){
        //deletes any current polyline
        let overlays = mapView.overlays
        self.mapView.removeOverlays(overlays)
        //Set up 2 coordinates
        let c1 = CLLocationCoordinate2D(latitude: UserLoc.coordinate.latitude, longitude: UserLoc.coordinate.longitude)
        let c2 = CLLocationCoordinate2D(latitude: destPin.coordinate.latitude, longitude: destPin.coordinate.longitude)
        //Create a direction request
        let request = MKDirectionsRequest()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: c1))
        request.destination = MKMapItem( placemark: MKPlacemark(coordinate: c2))
        request.requestsAlternateRoutes = false
        //submit direction request and save to variable
        let directions = MKDirections(request: request)
        directions.calculate(completionHandler: {(response, error) in
            if error != nil {
                print("Error getting directions")
            } else {
                //draw a polyline
                for route in (response?.routes)! {
                    self.mapView.add(route.polyline,
                                   level: MKOverlayLevel.aboveRoads)
                }
                
            }
        })
        
    }

    // an API call that launches the Apple Maps app with driving directions. You convert the cached selectedPin to a MKMapItem. The Map Item is then able to open up driving directions in Apple Maps using the openInMapsWithLaunchOptions() method
    func getDirections(){
        if let selectedPin = selectedPin {
            let mapItem = MKMapItem(placemark: selectedPin)
            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
            mapItem.openInMaps(launchOptions: launchOptions)
        }
    }

}

extension ViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let span = MKCoordinateSpanMake(0.05, 0.05)
            let region = MKCoordinateRegionMake(location.coordinate, span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: NSError) {
        print("error:: \(error)")
    }
}

//  implements the dropPinZoomIn() method in order to adopt the HandleMapSearch protocol.
extension ViewController: HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark){
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        // populate the map pin with information
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        mapView.addAnnotation(annotation)  //adds annotation to the map
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)  //zooms the map to the coordinate
        drawRoute(CLLocation(latitude: mapView.userLocation.coordinate.latitude, longitude: mapView.userLocation.coordinate.longitude),destPin: CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude))
    }
}



// customize the map pin callout with a button that takes you to Apple Maps for driving directions
extension ViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            // return nil so you don't interfere with the user's blue location dot
            return nil
        }
        let reuseId = "pin" // reuse identifier for the pin
        // setting the map pin UI, along with the color and callout
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint(x: 0,y :0), size: smallSquare))
        button.setBackgroundImage(#imageLiteral(resourceName: "car"), for: .normal)
        button.addTarget(self, action: #selector(ViewController.getDirections), for: .touchUpInside)
        // set to an UIButton that you instantiate programmatically. The button is set to a size of 30×30. The button image is set to an asset catalog image named car, and the button’s action is wired to a custom method called getDirections()
        pinView?.leftCalloutAccessoryView = button
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer! {
        if overlay is MKPolyline{
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.orange
            polylineRenderer.lineDashPattern = [5,5]
            polylineRenderer.lineWidth = 3
            return polylineRenderer
            
        }
        return nil
    }

}



extension Date {
    func toString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d"
        return dateFormatter.string(from: self)
    }
}
extension String {
    func chopPrefix(_ count: Int = 1) -> String {
        return substring(from: index(startIndex, offsetBy: count))
    }
    
    func chopSuffix(_ count: Int = 1) -> String {
        return substring(to: index(endIndex, offsetBy: -count))
    }
}
extension String {
    func capitalizingFirstLetter() -> String {
        let first = String(characters.prefix(1)).capitalized
        let other = String(characters.dropFirst())
        return first + other
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
extension String {
    func toLengthOf(length:Int) -> String {
        if length <= 0 {
            return self
        } else if let to = self.index(self.startIndex, offsetBy: length, limitedBy: self.endIndex) {
            return self.substring(from: to)
            
        } else {
            return ""
        }
    }
}

