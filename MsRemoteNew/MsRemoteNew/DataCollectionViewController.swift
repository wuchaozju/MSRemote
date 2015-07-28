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
        static let ACCURACY_THREHOLD: Double = 10
        static let AVERAGE_ACCURACY_THREHOLD: Double = 15
        static let UPLOADED_PERCENTAGE: Double = 0.9
        
        static let TIME_INTERVAL: NSTimeInterval = 1
        static let TIME_INTERVAL_CHANGE: Float = 0.1// 10 seconds
        static let TIME_INTERVAL_COLLECTION: NSTimeInterval = 40 // 40 seconds
        private struct Prompts {
            static let STAND_STILL = "Please stand still for a while"
            static let READY_TO_WALK = "Ready to walk for 10 seconds"
            static let CHANGE_LOCATION = "Please change location and try again"
            static let FINISHED_COLLECTION = "Data collection is finished"
            static let COLLECTING_DATA = "Collecting Data"
            
            // results prompts
            static let FAIL_TIME_OUT = "Time out. Please try again"
            static let FAIL_LOW_ACCURACY = "Low accuarcy. Please change location and try again"
            static let FAIL_BAD_NETWORK = "Bad network. Please check your network and try again"
            static let FAIL_LOW_NUM_POINTS = "Low number of data. Please change location and try again"
            static let SUCCESS = "Data collection is finished successfully"
        }
        private struct States {
            static let FAIL_TIME_OUT = "FAIL_TIME_OUT"
            static let FAIL_LOW_ACCURACY = "FAIL_LOW_ACCURACY"
            static let FAIL_BAD_NETWORK = "FAIL_BAD_NETWORK"
            static let FAIL_LOW_NUM_POINTS = "FAIL_LOW_NUM_POINTS"
            static let SUCCESS = "SUCCESS"
        }
    }
    
    private var firstUIViewController: FirstViewController!
    private var accuracyData = [Double]()
    private var startTime: NSDate! = NSDate()
    private var finishTime: NSDate! = NSDate()
    private var timerOFCollection: NSTimer!
    
    private var accuracyCollectedData = [Double]()
    private var uploadedDataNum: Int = 0
    
    @IBOutlet weak var timeProgress: UIProgressView!
    private var timeProgressNum: Float = 0
    @IBOutlet weak var promptsLabel: UILabel!
    
    // stop walking button
    @IBOutlet weak var stopDataCollectionOutlet: UIButton!
    @IBAction func stopDataCollection(sender: UIButton) {
        if timerOFCollection != nil {
            timerOFCollection.invalidate()
        }
        sender.hidden = true
        
        getGPSData(false)
        self.changeDistanceFilter(10)
        
        finishTime = NSDate()
        let passedSeconds = finishTime.timeIntervalSinceDate(startTime)
        let state: String = checkState(passedSeconds)
        uploadMarker(state)
        
        // used for finished task
        stopDataCollectionOutlet!.hidden = true
        failedAndBackButtonOutlet!.hidden = false
    }
    
    // start walking button
    @IBOutlet weak var startDataCollectionOutlet: UIButton!
    @IBAction func startDataCollection(sender: UIButton) {
        
        accuracyCollectedData.removeAll(keepCapacity: false)
        uploadedDataNum = 0
        sender.hidden = true
        stopDataCollectionOutlet!.hidden = false
        promptsLabel.text = Constants.Prompts.COLLECTING_DATA

        startTime = NSDate()
        self.changeDistanceFilter(0)
        self.getGPSData(true)
        
        timerOFCollection = NSTimer.scheduledTimerWithTimeInterval(Constants.TIME_INTERVAL_COLLECTION, target: self, selector: "timeOutFunction", userInfo: nil, repeats: false)
    }
    
    // return to main start button
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
        promptsLabel!.text = Constants.Prompts.STAND_STILL
        timeProgress!.hidden = false
        var timer = NSTimer.scheduledTimerWithTimeInterval(Constants.TIME_INTERVAL, target: self, selector: "updateProgress:", userInfo: nil, repeats: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let firstUINavigationController = self.tabBarController?.childViewControllers[0] as! UINavigationController
        firstUIViewController = firstUINavigationController.childViewControllers[0] as! FirstViewController
        
        firstUIViewController.dataCollectionDelegate = self
        
        stopDataCollectionOutlet!.hidden = true
        startDataCollectionOutlet!.hidden = true
        failedAndBackButtonOutlet!.hidden = true
        promptsLabel!.hidden = true
        timeProgress!.hidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func timeOutFunction() {
        timerOFCollection = nil
        getGPSData(false)
        self.changeDistanceFilter(10)
        stopDataCollectionOutlet!.hidden = true
        failedAndBackButtonOutlet!.hidden = false
        promptsLabel.text = Constants.Prompts.FAIL_TIME_OUT

        uploadMarker(Constants.States.FAIL_TIME_OUT)
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
    
//    func updateCollection(timer: NSTimer) {
//        timeProgressNum += Constants.TIME_INTERVAL_CHANGE_FOR_COLLECTION
//        timeProgress.setProgress(timeProgressNum, animated: true)
//        if timeProgress.progress == 1.0 {
//            getGPSData(false)
//            timer.invalidate()
//            timeProgress!.hidden = true
//            self.changeDistanceFilter(10)
//            
//            finishTime = NSDate()
//            uploadMarker()
//            
//            // used for finished task
//            failedAndBackButtonOutlet!.hidden = false
//            promptsLabel.text = Constants.Prompts.FINISHED_COLLECTION
//        }
//    }

    private func checkState(seconds: NSTimeInterval) -> String {
        if seconds <= 10 || accuracyCollectedData.count <= Int(seconds - 2) {
            promptsLabel.text = Constants.Prompts.FAIL_LOW_NUM_POINTS
            return Constants.States.FAIL_LOW_NUM_POINTS
        }
        else if getAverageFromDoubleArray(self.accuracyCollectedData) > Constants.AVERAGE_ACCURACY_THREHOLD {
            promptsLabel.text = Constants.Prompts.FAIL_LOW_ACCURACY
            return Constants.States.FAIL_LOW_ACCURACY
        }
        else if Double(uploadedDataNum) / Double(accuracyCollectedData.count) <= Constants.UPLOADED_PERCENTAGE {
            promptsLabel.text = Constants.Prompts.FAIL_BAD_NETWORK
            return Constants.States.FAIL_BAD_NETWORK
        }
        promptsLabel.text = Constants.Prompts.SUCCESS
        return Constants.States.SUCCESS
    }
    
    private func precheck() -> Bool {
//        return accuracyData.count >= Constants.COUNT_OF_POINTS && getAverageFromDoubleArray(accuracyData) <= Constants.AVERAGE_OF_ACCURACY
        return getNumOfGoodAccuracy(accuracyData) >= Constants.COUNT_OF_POINTS
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
        accuracyCollectedData.append(accuracy)
        self.saveRemotely(latitude, longitude: longitude, accuracy: accuracy, locTimestamp: locTimestamp)
    }
    
    //delegate function
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
    
    private func getNumOfGoodAccuracy(array: [Double]) -> Int {
        var num: Int = 0
        for point in array {
            if point <= Constants.ACCURACY_THREHOLD {
                ++num
            }
        }
        
        return num
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
                ++self.uploadedDataNum
                println("uploaded: \(self.uploadedDataNum)")
            }
        }

    }
    
    private func uploadMarker(state: String) {
        var marker = PFObject(className: "Markers")
        marker["user"] = firstUIViewController.userID
        marker["startTime"] = startTime
        marker["finishTime"] = finishTime
        marker["state"] = state

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
