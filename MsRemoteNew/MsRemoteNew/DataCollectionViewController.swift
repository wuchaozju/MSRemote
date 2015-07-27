//
//  DataCollectionViewController.swift
//  MsRemoteNew
//
//  Created by Simiao Yu on 24/07/2015.
//  Copyright (c) 2015 Imperial College London. All rights reserved.
//

import UIKit

class DataCollectionViewController: UIViewController, DataCollectionDelegate {
    
    private struct Constants {
        static let COUNT_OF_POINTS = 8
        static let AVERAGE_OF_ACCURACY: Double = 30
        static let TIME_INTERVAL: NSTimeInterval = 1
        static let TIME_INTERVAL_CHANGE: Float = 0.1
        static let TIME_INTERVAL_CHANGE_FOR_COLLECTION: Float = 0.1
        private struct Prompts {
            static let STAND_STILL = "Please stand still for a while"
            static let READY_TO_WALK = "Ready to walk for 10 seconds"
            static let CHANGE_LOCATION = "Please change location and try again"
            static let FINISHED_COLLECTION = "Data collection is finished"
            static let COLLECTING_DATA = "Collecting Data"
        }
    }
    
    private var firstUIViewController: FirstViewController!
    private var accuracyData = [Double]()
    private var startTime: NSDate! = NSDate()
    private var finishTime: NSDate! = NSDate()
    
    
    @IBOutlet weak var timeProgress: UIProgressView!
    private var timeProgressNum: Float = 0
    @IBOutlet weak var promptsLabel: UILabel!
    
    
    
    @IBOutlet weak var startDataCollectionOutlet: UIButton!
    @IBAction func startDataCollection(sender: UIButton) {
        
        startTime = NSDate()
        
        sender.hidden = true
        self.timeProgressNum = 0
        timeProgress.setProgress(0, animated: false)
        self.changeDistanceFilter(0)
        self.getGPSData(true)
        
        promptsLabel.text = Constants.Prompts.COLLECTING_DATA
        timeProgress!.hidden = false
        
        var timer = NSTimer.scheduledTimerWithTimeInterval(Constants.TIME_INTERVAL, target: self, selector: "updateCollection:", userInfo: nil, repeats: true)
    }
    
    @IBOutlet weak var failedAndBackButtonOutlet: UIButton!
    @IBAction func failedAndBackButton(sender: UIButton) {
        sender.hidden = true
        startButtonOutlet!.hidden = false
        promptsLabel!.hidden = true
    }
    
    
    // main start button
    @IBOutlet weak var startButtonOutlet: UIButton!
    @IBAction func startButton(sender: UIButton) {
        sender.hidden = true
        accuracyData.removeAll(keepCapacity: false)
        self.timeProgressNum = 0
        timeProgress.setProgress(0, animated: false)
        self.changeDistanceFilter(0)
        self.getAccuracyData(true)
        
        promptsLabel!.hidden = false
        timeProgress!.hidden = false
        var timer = NSTimer.scheduledTimerWithTimeInterval(Constants.TIME_INTERVAL, target: self, selector: "updateProgress:", userInfo: nil, repeats: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let firstUINavigationController = self.tabBarController?.childViewControllers[0] as! UINavigationController
        firstUIViewController = firstUINavigationController.childViewControllers[0] as! FirstViewController
        
        firstUIViewController.dataCollectionDelegate = self
        
        startDataCollectionOutlet!.hidden = true
        failedAndBackButtonOutlet!.hidden = true
        promptsLabel!.hidden = true
        timeProgress!.hidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateProgress(timer: NSTimer) {
        timeProgressNum += Constants.TIME_INTERVAL_CHANGE
        timeProgress.setProgress(timeProgressNum, animated: true)
        if timeProgress.progress == 1.0 {
            getGPSData(false)
            timer.invalidate()
            timeProgress!.hidden = true
            self.changeDistanceFilter(10)
            
            // pass the check and ready to test
            if precheck() {
                startDataCollectionOutlet!.hidden = false
                promptsLabel.text = Constants.Prompts.READY_TO_WALK
            } else { // failed to pass the check
                failedAndBackButtonOutlet!.hidden = false
                promptsLabel.text = Constants.Prompts.CHANGE_LOCATION
            }
        }
    }
    
    func updateCollection(timer: NSTimer) {
        timeProgressNum += Constants.TIME_INTERVAL_CHANGE_FOR_COLLECTION
        timeProgress.setProgress(timeProgressNum, animated: true)
        if timeProgress.progress == 1.0 {
            getGPSData(false)
            timer.invalidate()
            timeProgress!.hidden = true
            self.changeDistanceFilter(10)
            
            finishTime = NSDate()
            uploadMarker()
            
            // used for finished task
            failedAndBackButtonOutlet!.hidden = false
            promptsLabel.text = Constants.Prompts.FINISHED_COLLECTION
        }
    }

    
    private func precheck() -> Bool {
        return accuracyData.count >= Constants.COUNT_OF_POINTS && getAverageFromDoubleArray(accuracyData) <= Constants.AVERAGE_OF_ACCURACY
    }
    
    
    private func changeDistanceFilter(filterNum: CLLocationDistance) {
        firstUIViewController.slsLocationManager.distanceFilter = filterNum
    }
    
    private func getGPSData(state: Bool) {
        firstUIViewController.allowDataForCollection(state)
    }
    
    private func getAccuracyData(state: Bool) {
        firstUIViewController.allowAccuracyForCollection(state)
    }

    
    //delegate function
    func collectData(latitude: Double, longitude: Double, accuracy: Double, locTimestamp: NSDate) {
        self.saveRemotely(latitude, longitude: longitude, accuracy: accuracy, locTimestamp: locTimestamp)
    }
    
    func collectAccuracyData(accuracy: Double) {
        accuracyData.append(accuracy)
    }
    
    private func getAverageFromDoubleArray(array: [Double]) -> Double {
        var sum: Double = 0
        for num in array {
            sum += num
        }
        return sum / Double(array.count)
    }
    
    private func saveRemotely(latitude: Double, longitude: Double, accuracy: Double, locTimestamp: NSDate) {
        // save all data locally and remotely
        let point = PFGeoPoint(latitude:latitude, longitude: longitude)
        
        var record = PFObject(className: "DataCollection")
        
        record["user"] = firstUIViewController.userID
        record["location"] = point
        record["accuracy"] = accuracy
        record["locTimestamp"] = locTimestamp
        
        record.saveInBackgroundWithBlock { (result:Bool, error:NSError!) -> Void in
            if !result {
            } else {
            }
        }

    }
    
    private func uploadMarker() {
        var marker = PFObject(className: "Markers")
        marker["user"] = firstUIViewController.userID
        marker["startTime"] = startTime
        marker["finishTime"] = finishTime

        marker.saveInBackgroundWithBlock { (result:Bool, error:NSError!) -> Void in
            if !result {
            } else {
            }
        }

    }
    

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
