//
//  FirstViewController.swift
//  MsRemoteNew
//
//  Created by chao on 04/03/2015.
//  Copyright (c) 2015 Imperial College London. All rights reserved.
//

import UIKit
import MapKit

protocol UpdateChartDelegate {
    func updateChart(newDate: String, speed: Double)
    func updateChart(speed: Double)
}

class FirstViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate {

    var chartDelegate: UpdateChartDelegate?
    
    let slsLocationManager = CLLocationManager()
    let dataModel = DataModel()
    
    // store locations
    var locationArray: [CLLocation] = []
    
    // overlays on mapview for today's track.
    var overlayArray = [MKPolyline]()
    
    // polyline-speed dic
    var Poly_Speed: [MKPolyline: Double] = [:]
    
    @IBOutlet weak var map: MKMapView!
    
    @IBAction func currentLoc(sender: AnyObject) {
        let spanX = 0.007
        let spanY = 0.007
        
        var newRegion = MKCoordinateRegion(center: map.userLocation.coordinate, span: MKCoordinateSpanMake(spanX, spanY))
        map.setRegion(newRegion, animated: true)
    }
    
    func LaunchLocationUpdate(){
        
        self.startSLSorRegionMonitoringLocation(true)
        
    }
    
    func startSLSorRegionMonitoringLocation(isStandardLocationService:Bool) -> Void{
        
        
        
        // stop Standard Location Service (SLS)
        
        self.slsLocationManager.stopUpdatingLocation()
        
        
        
        if isStandardLocationService{
            
            //start Standard Location Service to track user's location in foreground
            
            self.startSLSToMonitorLocationWithSLSByDistanceFilter(10)
            
        }else{
            
            //TODO: Region Monitoring
            
            //[self startRegionMonitoring:thresholdDistnaceToUpdate howCloseToTriggerMessage:triggerDistance];
            
        }
        
    }
    
    func startSLSToMonitorLocationWithSLSByDistanceFilter(thresholdDistance:Int) -> Void {
        
        if CLLocationManager.locationServicesEnabled() == false {
            
            // prompt user for changing navi setting
            let alertController = UIAlertController(title: "Location Service OFF", message: "Enable location service for detecting your location. \n (Settings > Privacy > Location Services)", preferredStyle: .Alert)
            let OkAction = UIAlertAction(title: "Ok", style: .Default, handler: nil)
            alertController.addAction(OkAction)
            presentViewController(alertController, animated: false, completion: nil)
        }
        else {
            switch CLLocationManager.authorizationStatus() {
                
            case .AuthorizedAlways:
                
                
                map.showsUserLocation = true
                self.navigationItem.rightBarButtonItem?.enabled = true
                
                
                //TODO: Create the Message Trigger Manager
                
                /*
                
                //Create the Message Trigger Manager if this object does not already have one.
                
                //if (self.msgTriggerManager == nil) {
                
                self.msgTriggerManager = [[MessageTriggerManager alloc] initWithTriggerDistance:triggerDistance];
                
                //}
                
                */
                
                
                
                //Create the location manager if this object does not already have one.
                
                //if (nil == self.slsLocationManager){
                
                //    self.slsLocationManager = [[CLLocationManager alloc] init];
                
                //}
                
                
                // for Standard Location Service
                
                if thresholdDistance <= 30 {
                    
                    //set the desiredAccuracy. this property only work in Stardard Location Service
                    
                    // best accuracy for debug
//                     self.slsLocationManager.desiredAccuracy = kCLLocationAccuracyBest
                    self.slsLocationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                    
                }else{
                    
                    //set the desiredAccuracy. this property only work in Stardard Location Service
                    
                    //self.slsLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
                    
                    self.slsLocationManager.desiredAccuracy = kCLLocationAccuracyKilometer
                    
                }
                
                
                
                // set a movement threshold for new events. this property only work in Stardard Location Service
                
                self.slsLocationManager.distanceFilter = Double(thresholdDistance) // meters
                

                //set automatically pause to NO (default is YES)
                
                self.slsLocationManager.pausesLocationUpdatesAutomatically = false
                
                
                
                //set acticityType (default is CLActivityTypeOther)
                
                //we can use the time and moving distance to decide to use
                
                //CLActivityTypeAutomotiveNavigation (for vehicular navigation) or
                
                //CLActivityTypeFitness (for pedestrian-related activity) in the future
                
                //self.slsLocationManager.activityType = CLActivityTypeOther;
                
                
                
                self.slsLocationManager.requestAlwaysAuthorization()
                
                self.slsLocationManager.startUpdatingLocation()
                
                
                

                
            case .NotDetermined:
                slsLocationManager.requestAlwaysAuthorization()
                
            case .AuthorizedWhenInUse, .Restricted, .Denied:
                // prompt user for changing app setting
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
        
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        self.startSLSToMonitorLocationWithSLSByDistanceFilter(10)
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        
        if error.code == CLError.Denied.rawValue {
            
            //TODO: error handling
            
            manager.stopUpdatingLocation()
            
            
            
        }else{
            
            //TODO: error handling
            
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!){
        var location:CLLocation = locations.last as CLLocation
        
        locationArray.append(location)
                
        // draw on map
        if (locationArray.count > 1){
            let sourceIndex = locationArray.count - 2
            let destinationIndex = locationArray.count - 1
            
            let c1 = locationArray[sourceIndex].coordinate
            let c2 = locationArray[destinationIndex].coordinate
            var a = [c1, c2]
            
            var polyline = MKPolyline(coordinates: &a, count: a.count)
            var speed: Double = calculateSpeed(locationArray[sourceIndex], destination: locationArray[destinationIndex])
            
            // save data
            if dataModel.saveData(NSDate(), speed: speed) == false { // new day
                
                // remove tracks
                map.removeOverlays(overlayArray)
                overlayArray.removeAll(keepCapacity: false)
                
                // notify JB Chart VC
                chartDelegate?.updateChart(dataModel.dateOfTodayStr, speed: speed)
                
            } else {
                // notify JB Chart VC
                chartDelegate?.updateChart(speed)
            }
            
            sync(Poly_Speed) {
                self.Poly_Speed[polyline] = speed
            }
            overlayArray.append(polyline)
            map.addOverlay(polyline)

        }
        
        var latitude = (location.coordinate.latitude.description as NSString).doubleValue
        var longitude = (location.coordinate.longitude.description as NSString).doubleValue
        
        let point = PFGeoPoint(latitude:latitude, longitude:longitude)
        
        // parse update
//        var object = PFObject(className: "UserLocation")
//        
//        // for stored user ID
//        // use name of current device if no valid user ID is found
//        let userID = NSUserDefaults.standardUserDefaults().stringForKey("userID") ?? UIDevice.currentDevice().name
//        object.addObject(userID, forKey: "user")
//
//        object.addObject(point, forKey: "location")
//        object.saveEventually { (result:Bool, error:NSError!) -> Void in
//        
//        }
    }
    
    // calculate speed between two locations
    func calculateSpeed(source: CLLocation, destination: CLLocation) -> Double {
        var distance = source.distanceFromLocation(destination)
        var speed = distance / (destination.timestamp.timeIntervalSinceDate(source.timestamp))
        return min(max(speed, 0), 60)
    }
    
    // find colors for different speeds
    func findColorForSpeed(speed: Double) -> UIColor{
        switch speed {
        case 0..<1.5:
            return UIColor.redColor()
        case 1.5..<3:
            return UIColor.orangeColor()
        case 3..<6:
            return UIColor.yellowColor()
        case 6..<10:
            return UIColor.greenColor()
        case 10..<15:
            return UIColor.cyanColor()
        case 15..<27:
            return UIColor.blueColor()
        default:
            return UIColor.brownColor()
        }
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if overlay is MKPolyline {
            let forSpeed: MKPolyline = overlay as MKPolyline
            var polylineRenderer = MKPolylineRenderer(overlay: overlay)
            
            var speed: Double?
            sync(Poly_Speed){
                speed = self.Poly_Speed[forSpeed]
            }
            
            if let wrappedSpeed = speed {
                polylineRenderer.strokeColor = findColorForSpeed(wrappedSpeed)
                polylineRenderer.lineWidth = 4
                
                sync(Poly_Speed) {
                    self.Poly_Speed.removeAll(keepCapacity: true)
                }
                
                return polylineRenderer
            }
        }
        
        sync(Poly_Speed) {
            self.Poly_Speed.removeAll(keepCapacity: true)
        }
        
        return nil
    }
    
    // for similar synchronised method in objc
    func sync(lock: AnyObject, closure: () -> Void) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if NSUserDefaults.standardUserDefaults().boolForKey("HasLaunched") {
        
            basicSetup()
            
        } else {
            // if the app is first launched
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasLaunched")
            NSUserDefaults.standardUserDefaults().synchronize()
            
            userIDInput()
            
        }
    
    }
    
    func basicSetup() {
//        // parse setup
//        Parse.setApplicationId("FYSavrPyF5gn35uLR9RigzZF69gpfsw3yFdlmGSJ", clientKey: "4Oouc27YpQ6PoFznCnKP1ra5fbvds767FDmnmQz5")
        
        
        // setup map view
        map.delegate = self
        map.mapType = MKMapType.Standard
        
        slsLocationManager.delegate = self
        LaunchLocationUpdate()
    }
    
    // prompt for user ID when first launched
    func userIDInput() {
        let alertController = UIAlertController(title: "User ID", message: "Please input your User ID", preferredStyle: .Alert)
        
        let DoneAction = UIAlertAction(title: "Done", style: .Default) { (_) in
            // save user ID
            let UserIDTextField = alertController.textFields![0] as UITextField
            NSUserDefaults.standardUserDefaults().setObject(UserIDTextField.text, forKey: "userID")
            
            self.basicSetup()
        }
        DoneAction.enabled = false
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.delegate = self
            textField.placeholder = "User ID"
            
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                DoneAction.enabled = textField.text != ""
            }
        }
        
        alertController.addAction(DoneAction)
        
        self.presentViewController(alertController, animated: true) {
        }
        
    }
    
    // close the keyboard when pressing return
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

