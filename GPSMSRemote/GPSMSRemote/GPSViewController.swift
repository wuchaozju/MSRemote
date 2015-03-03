//
//  GPSViewController.swift
//  GPSMSRemote
//
//  Created by chao on 27/02/2015.
//  Copyright (c) 2015 Imperial College London. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

enum ButtonState {
    case Start, Stop
}

class GPSViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    var manager:CLLocationManager!
    var myLocations: [CLLocation] = []
    var checkButtonState: ButtonState = .Start

    @IBOutlet weak var map: MKMapView!
    @IBAction func Start(sender: AnyObject) {
        if checkButtonState == .Start {
            switch CLLocationManager.authorizationStatus() {
            case .Authorized:
                manager.startUpdatingLocation()
                map.showsUserLocation = true
                self.navigationItem.rightBarButtonItem?.enabled = true
                self.navigationItem.leftBarButtonItem?.title = "Stop Tracking"
                checkButtonState = .Stop
                
            case .NotDetermined:
                manager.requestAlwaysAuthorization()
            case .AuthorizedWhenInUse, .Restricted, .Denied:
                let alertController = UIAlertController(
                    title: "Background Location Access Disabled",
                    message: "Please open settings and set location access to 'Always'.",
                    preferredStyle: .Alert)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                alertController.addAction(cancelAction)
                
                let openAction = UIAlertAction(title: "Settings", style: .Default) { (action) in
                    if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                        UIApplication.sharedApplication().openURL(url)
                    }
                }
                alertController.addAction(openAction)
                
                presentViewController(alertController, animated: true, completion: nil)
            }
        }
            
        else {
            self.navigationItem.rightBarButtonItem?.enabled = false
            manager.stopUpdatingLocation()
            checkButtonState = .Start
            self.navigationItem.leftBarButtonItem?.title = "Start Tracking"
        }
    }
    
    @IBAction func currentLoc(sender: AnyObject) {
        let spanX = 0.007
        let spanY = 0.007
        var newRegion = MKCoordinateRegion(center: map.userLocation.coordinate, span: MKCoordinateSpanMake(spanX, spanY))
        map.setRegion(newRegion, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Setup location manager
        manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 1
        manager.pausesLocationUpdatesAutomatically = true
        
        // Setup map view
        map.delegate = self
        map.mapType = MKMapType.Standard
    
        self.navigationItem.leftBarButtonItem?.enabled = true
    }
    
//    override func viewDidAppear(animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        switch CLLocationManager.authorizationStatus() {
//        case .Authorized:
//            manager.startUpdatingLocation()
//            map.showsUserLocation = true
//        case .NotDetermined:
//            manager.requestAlwaysAuthorization()
//        case .AuthorizedWhenInUse, .Restricted, .Denied:
//            let alertController = UIAlertController(
//                title: "Background Location Access Disabled",
//                message: "Please open settings and set location access to 'Always'.",
//                preferredStyle: .Alert)
//            
//            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
//            alertController.addAction(cancelAction)
//            
//            let openAction = UIAlertAction(title: "Settings", style: .Default) { (action) in
//                if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
//                    UIApplication.sharedApplication().openURL(url)
//                }
//            }
//            alertController.addAction(openAction)
//            
//            presentViewController(alertController, animated: true, completion: nil)
//
//        }
    
//        // Check if location service is ON
//        if CLLocationManager.locationServicesEnabled() == true {
//            if CLLocationManager.authorizationStatus() != .Authorized ||  CLLocationManager.authorizationStatus() != .AuthorizedWhenInUse {
//                manager.requestAlwaysAuthorization()
//            }
//            manager.startUpdatingLocation()
//            map.showsUserLocation = true
//        }
//        else {
//            let alertController = UIAlertController(title: "Location Service OFF", message: "Enable location service for detecting your location. \n (Settings > Privacy > Location Services)", preferredStyle: .Alert)
//            let OkAction = UIAlertAction(title: "Ok", style: .Default, handler: nil)
//            alertController.addAction(OkAction)
//            presentViewController(alertController, animated: false, completion: nil)
//        }
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        myLocations.append(locations[locations.count - 1] as CLLocation)
        println("\(locations[locations.count - 1]) ++++++++++ \(myLocations.count)")
        
        if (myLocations.count > 1){
            var sourceIndex = myLocations.count - 2
            var destinationIndex = myLocations.count - 1
            
            let c1 = myLocations[sourceIndex].coordinate
            let c2 = myLocations[destinationIndex].coordinate
            var a = [c1, c2]
            
            var polyline = MKPolyline(coordinates: &a, count: a.count)
            map.addOverlay(polyline)
        }
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if overlay is MKPolyline {
            var polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.blueColor()
            polylineRenderer.lineWidth = 4
            return polylineRenderer
        }
        return nil
    }

}

/*class GPSViewController: UIViewController, MKMapViewDelegate {
    

    var currentPoint: Point =  Point(coord:[0.0, 0.0])
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var mapTypeSegmentControl: UISegmentedControl!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        // Custom initialization
    }
    
    required init(coder aDecoder: NSCoder)  {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapTypeSegmentControl.setTitle(NSLocalizedString("Map", comment: "Map"), forSegmentAtIndex: 0);
        mapTypeSegmentControl.setTitle(NSLocalizedString("Satellite", comment: "Satellite"), forSegmentAtIndex: 1);
        mapTypeSegmentControl.setTitle(NSLocalizedString("Hybrid", comment: "Hybrid"), forSegmentAtIndex: 2);
        
        if self.mapView.annotations.count <= 1 {
            NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector:"timerAction:", userInfo: nil, repeats: false)
            let height = 0.01
            let span = MKCoordinateSpanMake(0.75 * height, height);
            let centerCoord = currentPoint.coordinate;
            let visibleRegion = MKCoordinateRegionMake(centerCoord, span);
            mapView.setRegion(visibleRegion, animated:true)
        }
        
        self.mapTypeSegmentControl.selectedSegmentIndex = 0;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // #pragma mark - NSTimer Delegate
    func timerAction(timer: NSTimer) {
        mapView.addAnnotation(currentPoint)
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if let anno = annotation as? MKUserLocation {
            return mapView.viewForAnnotation(mapView.userLocation)
        }
        
        let AnnotationIdentifier = "StationPin";
        if let pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(AnnotationIdentifier) {
            return pinView;
        }
        else {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: AnnotationIdentifier)
            pinView.animatesDrop = true
            pinView.canShowCallout = true
            if let anno = annotation as? Point {
                anno.title = NSString(format:"%8f,%8f", anno.coordinate.latitude, anno.coordinate.longitude)
            }
            return pinView
        }
    }
    
    @IBAction func mapTypeChanged(sender: UISegmentedControl!) {
        let index = sender.selectedSegmentIndex
        switch index {
        case 2:
            mapView.mapType = .Hybrid
        case 1:
            mapView.mapType = .Satellite
        case 0:
            fallthrough
        default:
            mapView.mapType = .Standard
        }
    }
}*/