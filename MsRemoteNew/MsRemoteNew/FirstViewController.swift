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
    func updateChart(newDate: String, speed: Double, time: NSTimeInterval)
    func updateChart(speed: Double, time: NSTimeInterval)
    func initChartWithExistingRecords(speedArray: [Double], timeArray: [Double])
}

class FirstViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate {

    var chartDelegate: UpdateChartDelegate?
    
    let slsLocationManager = CLLocationManager()
    var dataModel: DataModel!
    
    // store locations
    var locationArray: [CLLocation] = []
    
    // overlays on mapview for today's track.
    var overlayArray = [MKPolyline]()
    
    // polyline-speed dic
    var Poly_Speed: [MKPolyline: Double] = [:]
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var legendView: UIView!
    var updatedPotisionNum = 0
    
    @IBAction func toggleFilter(sender: UIBarButtonItem) {
        if sender.title == "Filtered" {
            self.slsLocationManager.distanceFilter = kCLDistanceFilterNone
            sender.title = "No Filter"
        } else {
            self.slsLocationManager.distanceFilter = 5
            sender.title = "Filtered"
        }
    }
    
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
            
            self.startSLSToMonitorLocationWithSLSByDistanceFilter(5)
            
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
                    self.slsLocationManager.desiredAccuracy = kCLLocationAccuracyBest
                    
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
        LaunchLocationUpdate()
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
        var location:CLLocation = locations.last as! CLLocation
        
        // for testing
        ++updatedPotisionNum
        if updatedPotisionNum >= 1000 {
            updatedPotisionNum = 0
        }
        self.navigationItem.title = "\(location.horizontalAccuracy)" + " " + "\(updatedPotisionNum)"
        
        // discard bad data
        let accuracyInMeter = location.horizontalAccuracy
//        if accuracyInMeter <= 0 || accuracyInMeter > 10 {
//            return
//        }

        locationArray.append(location)
                
        // draw on map
        if (locationArray.count > 1){
            // get latitude and longitude
            let latitude = (location.coordinate.latitude.description as NSString).doubleValue
            let longitude = (location.coordinate.longitude.description as NSString).doubleValue
            
            // get previous location
            let preLoc = locationArray[locationArray.count - 2]
            
            let c1 = preLoc.coordinate
            let c2 = location.coordinate
            var a = [c1, c2]
            
            let polyline = MKPolyline(coordinates: &a, count: a.count)
            var speed: Double = calculateSpeed(preLoc, destination: location)
            
            // for walking speed
//            if speed > 0 && speed <= 2 {
                // get time
                let timeDifference = location.timestamp.timeIntervalSinceDate(preLoc.timestamp)
                let averagedTimePointForSpeed = NSDate(timeInterval: timeDifference / 2, sinceDate: preLoc.timestamp)
                let timeStampForLoc = location.timestamp
                
                // save data
                if dataModel == nil {
                    dataModel = DataModel()
                    if let (speedArray, timeArray) = dataModel.getExistingRecordsForToday(averagedTimePointForSpeed) {
                        chartDelegate?.initChartWithExistingRecords(speedArray, timeArray: timeArray)
                    }
                }
                let (oldday, timeSec) = dataModel.saveData(averagedTimePointForSpeed, speed: speed, duration: timeDifference, latitude: latitude, longitude: longitude, accuracy: accuracyInMeter, locTimestamp: timeStampForLoc)
                if oldday == false { // new day
                    
                    // remove tracks
                    map.removeOverlays(overlayArray)
                    overlayArray.removeAll(keepCapacity: false)
                    
                    // notify core plot Chart VC
                    chartDelegate?.updateChart(dataModel.dateOfTodayStr, speed: speed, time: timeSec)
                    
                } else {
                    // notify core plot Chart VC
                    chartDelegate?.updateChart(speed, time: timeSec)
                }

//            }
            
            sync(Poly_Speed) {
                self.Poly_Speed[polyline] = speed
            }
            overlayArray.append(polyline)
            map.addOverlay(polyline)
        
        }
        
    }
    
    // calculate speed between two locations
    func calculateSpeed(source: CLLocation, destination: CLLocation) -> Double {
        var distance = source.distanceFromLocation(destination)
        var speed = distance / (destination.timestamp.timeIntervalSinceDate(source.timestamp))
        return speed
    }
    
    // find colors for different speeds
    func findColorForSpeed(speed: Double) -> UIColor{
        switch speed {
        case 0..<0.7:
            return UIColor.redColor()
        case 0.7..<1.4:
            return UIColor.greenColor()
        case 1.4..<2.0:
            return UIColor.blueColor()
        default:
            return UIColor.blackColor()
        }
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if overlay is MKPolyline {
            let forSpeed: MKPolyline = overlay as! MKPolyline
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
        
        // setup map view
        map.delegate = self
        map.mapType = MKMapType.Standard
        
        // setup legend view
        legendView.backgroundColor = UIColor(white: 0.2, alpha: 0.2)
        view.addSubview(legendView)
        
        slsLocationManager.delegate = self
        tabBarController?.selectedIndex = 1
        
        LaunchLocationUpdate()
    }
    
    // prompt for user ID when first launched
    func userIDInput() {
        let alertController = UIAlertController(title: "User ID", message: "Please input your User ID", preferredStyle: .Alert)
        
        let DoneAction = UIAlertAction(title: "Done", style: .Default) { (_) in
            // save user ID
            let UserIDTextField = alertController.textFields![0] as! UITextField
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

