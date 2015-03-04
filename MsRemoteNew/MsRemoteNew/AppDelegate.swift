//
//  AppDelegate.swift
//  MsRemoteNew
//
//  Created by chao on 04/03/2015.
//  Copyright (c) 2015 Imperial College London. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var slsLocationManager:CLLocationManager?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        Parse.setApplicationId("FYSavrPyF5gn35uLR9RigzZF69gpfsw3yFdlmGSJ", clientKey: "4Oouc27YpQ6PoFznCnKP1ra5fbvds767FDmnmQz5")
        
        /*
        var object = PFObject(className: "TestClass")
        object.addObject("Banana", forKey: "favoriteFood")
        object.addObject("Chocolate", forKey: "favoriteIceCream")
        object.save()
        */
        self.slsLocationManager = CLLocationManager()

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        self.reLaunchLocationUpdateInForeground()

    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func reLaunchLocationUpdateInForeground(){
        self.startSLSorRegionMonitoringLocation(true)
    }
    
    func startSLSorRegionMonitoringLocation(isStandardLocationService:Bool) -> Void{
        
        // stop Standard Location Service (SLS)
        self.slsLocationManager?.stopUpdatingLocation()
        
        if isStandardLocationService{
            //start Standard Location Service to track user's location in foreground
            self.startSLSToMonitorLocationWithSLSByDistanceFilter(10, howCloseToTriggerMessage: 1)
        }else{
            //TODO: Region Monitoring
            //[self startRegionMonitoring:thresholdDistnaceToUpdate howCloseToTriggerMessage:triggerDistance];
        }
    }
    
    func startSLSToMonitorLocationWithSLSByDistanceFilter(thresholdDistance:Int, howCloseToTriggerMessage:Int) -> Void {
        
        if CLLocationManager.locationServicesEnabled() {
            
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
            
            self.slsLocationManager?.delegate = self
            
            // for Standard Location Service
            if thresholdDistance <= 30 {
                //set the desiredAccuracy. this property only work in Stardard Location Service
                //self.slsLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
                self.slsLocationManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            }else{
                //set the desiredAccuracy. this property only work in Stardard Location Service
                //self.slsLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
                self.slsLocationManager?.desiredAccuracy = kCLLocationAccuracyKilometer
            }
            
            // set a movement threshold for new events. this property only work in Stardard Location Service
            self.slsLocationManager?.distanceFilter = Double(30) // meters
            
            
            //set automatically pause to NO (default is YES)
            self.slsLocationManager?.pausesLocationUpdatesAutomatically = false
            
            //set acticityType (default is CLActivityTypeOther)
            //we can use the time and moving distance to decide to use
            //CLActivityTypeAutomotiveNavigation (for vehicular navigation) or
            //CLActivityTypeFitness (for pedestrian-related activity) in the future
            //self.slsLocationManager.activityType = CLActivityTypeOther;
            
            self.slsLocationManager?.requestAlwaysAuthorization()
            
            self.slsLocationManager?.startUpdatingLocation()
            
            
        }else{
            
            let serviceDisableAlert = UIAlertView(title: "GPS disabled", message: "Please turn on your GPS for this app", delegate: nil, cancelButtonTitle: "Cancel")
            
            serviceDisableAlert.show()
            
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!){
        
        var location:CLLocation = locations.last as CLLocation
        
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        if error.code == CLError.Denied.rawValue {
            //TODO: error handling
            manager.stopUpdatingLocation()
            
        }else{
            //TODO: error handling
        }
        
    }
    func locationManager(manager: CLLocationManager!, didStartMonitoringForRegion region: CLRegion!) {
        
    }
    func locationManager(manager: CLLocationManager!, monitoringDidFailForRegion region: CLRegion!, withError error: NSError!) {
        
    }
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        
    }
    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        
    }



}

