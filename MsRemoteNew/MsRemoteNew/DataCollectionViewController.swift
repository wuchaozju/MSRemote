//
//  DataCollectionViewController.swift
//  MsRemoteNew
//
//  Created by Simiao Yu on 24/07/2015.
//  Copyright (c) 2015 Imperial College London. All rights reserved.
//

import UIKit
import AudioToolbox

class DataCollectionViewController: UIViewController, DataCollectionDelegate {
        var chartDelegate: UpdateChartDelegate?

//    @IBAction func buttonA(sender: AnyObject) {
//        self.collectedDataLabel.hidden = true
//        self.uploadedDataLabel.hidden = true
//        self.accuracyDataLabel.hidden = true
//        self.averageAccuracyLabel.hidden = true
//        self.uploadedStatusLabel.hidden = true
//        self.passedTimeLabel.hidden = true
//    }
//    
//    @IBAction func buttonB(sender: AnyObject) {
//        self.collectedDataLabel.hidden = false
//        self.uploadedDataLabel.hidden = false
//        self.accuracyDataLabel.hidden = false
//        self.averageAccuracyLabel.hidden = false
//        self.uploadedStatusLabel.hidden = false
//        self.passedTimeLabel.hidden = false
//    }
//    
//    // Debugging label
//    @IBOutlet weak var collectedDataLabel: UILabel!
//    @IBOutlet weak var uploadedDataLabel: UILabel!
//    @IBOutlet weak var accuracyDataLabel: UILabel!
//    @IBOutlet weak var averageAccuracyLabel: UILabel!
//    @IBOutlet weak var uploadedStatusLabel: UILabel!
//    @IBOutlet weak var passedTimeLabel: UILabel!
//    //debug timer
//    private var timerForDebugging: NSTimer!
//    private var passedTime: Int = 0
    
    private struct Constants {
        static let COUNT_OF_POINTS = 7 //
        static let ACCURACY_THREHOLD: Double = 10
        static let AVERAGE_ACCURACY_THREHOLD: Double = 15
        static let UPLOADED_PERCENTAGE: Double = 0.5
        static let COLLECTION_PERCENTAGE: Double = 0.8 // collected / passed time
        
        // for updateProgress, 12 seconds
        static let TIME_INTERVAL: NSTimeInterval = 1
        static let TIME_INTERVAL_CHANGE: Float = 0.083333
        
        static let TIME_INTERVAL_COLLECTION: NSTimeInterval = 300 // 300 seconds
        
        // for startWaiting, 10 seconds
        static let START_WAITING_TIME: NSTimeInterval = 10
        static let TIME_INTERVAL_START_WAITING: NSTimeInterval = 1
        static let TIME_INTERVAL_START_WAITING_CHANGE: Float = 0.1
        
        // for stopWaiting, 10 seconds
        static let STOP_WAITING_TIME: NSTimeInterval = 10
        static let TIME_INTERVAL_STOP_WAITING: NSTimeInterval = 1
        static let TIME_INTERVAL_STOP_WAITING_CHANGE: Float = 0.1
        
        // for passed time
        static let TIME_FOR_COLLECTION: NSTimeInterval = 30
//        static let TIME_FOR_COLLECTION: NSTimeInterval = 0


        // for uploading, 20 seconds
        static let TIME_INTERVAL_UPLOADING: NSTimeInterval = 1
        static let TIME_INTERVAL_UPLOADING_CHANGE: Float = 0.05
//        static let TIME_INTERVAL_UPLOADING_CHANGE: Float = 0.5


        private struct Prompts {
            static let BEFORE_PRE_CHECK = "Press ESTIMATE and walk around\nto estimate signal quality"
            static let PRE_CHECK_WALKING = "Estimating signal quality\nPlease walk around the starting point"
            static let STAND_STILL = "Please stand still for a while\nbefore you start walking"
            static let STAND_STILL_AFTER_WALKING = "Please stand still for a while"
            static let READY_TO_WALK = "You may start collecting data"
            static let CHANGE_LOCATION = "Signal quality is not good enough\nPlease change location and try again"
            static let COLLECTING_DATA = "Start walking ...\nPress STOP when you want to stop walking"
            static let WAITING_FOR_UPLOADING = "Analysing and uploading data ...\nYou may continue your activity"
            
            // results prompts
            static let FAIL_TIME_OUT = "Time out! You walked too long\nPlease try again"
            static let FAIL_LOW_ACCURACY = "Bad GPS signal\nPlease change location and try again"
            static let FAIL_LOW_GPS_POINTS = "Bad GPS signal\nPlease change location and try again"
            static let FAIL_BAD_NETWORK = "Bad Internet connection\nPlease change location and try again"
            static let FAIL_LOW_WALKING_TIME = "Not enough data\nPlease walk for a longer time"
            static let SUCCESS = "Data collection is sucessful"
        }
        private struct States {
            static let FAIL_TIME_OUT = "FAIL_TIME_OUT"
            static let FAIL_LOW_ACCURACY = "FAIL_LOW_ACCURACY"
            static let FAIL_LOW_GPS_POINTS = "FAIL_LOW_GPS_POINTS"
            static let FAIL_BAD_NETWORK = "FAIL_BAD_NETWORK"
            static let FAIL_LOW_WALKING_TIME = "FAIL_LOW_WALKING_TIME"
            static let SUCCESS = "SUCCESS"
        }
    }
    private struct dataPoints {
        let latitude: Double
        let longitude: Double
        let accuracy: Double
        let locTimestamp: NSDate
    }
    var dataModel: DataModel!
    
    
    @IBOutlet weak var walkTimerLabel: UILabel!
    
    private var firstUIViewController: FirstViewController!
    private var accuracyData = [Double]()
    private var startTime: NSDate! = NSDate()
    private var finishTime: NSDate! = NSDate()
    private var passedSeconds: NSTimeInterval = 0
    
    private var timerOfPrechecking: NSTimer!
    private var timerOfCollection: NSTimer!
    private var timerOfStartWaiting: NSTimer!
    private var timerOfStopWaiting: NSTimer!
    private var timerOfUploading: NSTimer!
    private var timerOfWalking: NSTimer!
    
//    private var accuracyCollectedData = [Double]()
    private var collectedData = [dataPoints]()
    private var uploadedDataNum: Int = 0
    private var startTime_uploadedNum_Dict = [NSDate: Int]()
    
    @IBOutlet weak var timeProgress: UIProgressView!
    private var timeProgressNum: Float = 0
    @IBOutlet weak var promptsLabel: UILabel!
    

    // images
    
    @IBOutlet weak var leftRightArrowImageView: UIImageView!
    @IBOutlet weak var rightRightArrowImageView: UIImageView!
    @IBOutlet weak var step1ImageView: UIImageView!
    @IBOutlet weak var step2ImageView: UIImageView!
    @IBOutlet weak var step3ImageView: UIImageView!
    
    // abort button

    @IBOutlet weak var abortButtonOutlet: UIButton!
    @IBAction func abortButton(sender: UIButton) {
        let alertController = UIAlertController(title: "Are you sure to abort?", message: "", preferredStyle: .Alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .Default) { (action) in
            if self.timerOfCollection != nil {
                self.timerOfCollection.invalidate()
            }
            if self.timerOfStartWaiting != nil {
                self.timerOfStartWaiting.invalidate()
            }
            if self.timerOfPrechecking != nil {
                self.timerOfPrechecking.invalidate()
            }
            if self.timerOfStopWaiting != nil {
                self.timerOfStopWaiting.invalidate()
            }
            if self.timerOfUploading != nil {
                self.timerOfUploading.invalidate()
            }
            if self.timerOfWalking != nil {
                self.timerOfWalking.invalidate()
            }
            
            self.getGPSData(false)
            self.getAccuracyData(false)
            self.changeDistanceFilter(10)
            
            self.abortButtonOutlet!.hidden = true
            self.stopDataCollectionOutlet!.hidden = true
            self.startDataCollectionOutlet!.hidden = true
            self.failedAndBackButtonOutlet!.hidden = true
//            self.promptsLabel!.hidden = true
            self.timeProgress!.hidden = true
            
            self.startButtonOutlet!.hidden = false
            
            self.leftRightArrowImageView!.hidden = true
            self.rightRightArrowImageView!.hidden = true
            self.step1ImageView!.hidden = true
            self.step2ImageView!.hidden = true
            self.step3ImageView!.hidden = true
            self.step1ImageView!.image = UIImage(named: "on_1")
            self.step2ImageView!.image = UIImage(named: "on_2")
            self.step3ImageView!.image = UIImage(named: "on_3")
            
            self.promptsLabel.text = Constants.Prompts.BEFORE_PRE_CHECK
            self.walkTimerLabel!.hidden = true
            
//            //debug
//            self.collectedDataLabel.text = "col 0"
//            self.uploadedDataLabel.text = "up 0"
//            self.accuracyDataLabel.text = "acc 0"
//            self.averageAccuracyLabel.text = "avg 0"
//            self.uploadedStatusLabel.text = "n/a"
//            self.passedTimeLabel.text = "t 0"
//            if self.timerForDebugging != nil {
//                self.timerForDebugging.invalidate()
//            }
//            self.passedTime = 0

        }
        
        alertController.addAction(yesAction)
        
        let noAction = UIAlertAction(title: "No", style: .Default) { (action) in
        }
        
        alertController.addAction(noAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)

    }
    // stop walking button
    @IBOutlet weak var stopDataCollectionOutlet: UIButton!
    @IBAction func stopDataCollection(sender: UIButton) {
        step2ImageView!.image = UIImage(named: "on_2")
        step3ImageView!.image = UIImage(named: "off_3")
        
        if timerOfCollection != nil {
            timerOfCollection.invalidate()
        }
        promptsLabel.text = Constants.Prompts.STAND_STILL_AFTER_WALKING
        
        self.timeProgress!.hidden = false
        self.timeProgressNum = 0
        self.timeProgress.setProgress(0, animated: false)
        
        // stop waiting timer
        timerOfStopWaiting = NSTimer.scheduledTimerWithTimeInterval(Constants.TIME_INTERVAL_STOP_WAITING, target: self, selector: "stopWaiting", userInfo: nil, repeats: true)
        
        // used for finished task
        stopDataCollectionOutlet!.hidden = true
        
        timerOfWalking.invalidate()
        walkTimerLabel!.hidden = true
    }
    
    // start walking button
    @IBOutlet weak var startDataCollectionOutlet: UIButton!
    @IBAction func startDataCollection(sender: UIButton) {
        
        collectedData.removeAll(keepCapacity: false)
        uploadedDataNum = 0
        sender.hidden = true
        promptsLabel.text = Constants.Prompts.STAND_STILL

        sync(startTime) {
            self.startTime = NSDate()
        }
        sync(self.startTime_uploadedNum_Dict) {
            self.startTime_uploadedNum_Dict[self.startTime] = 0
        }


        self.changeDistanceFilter(0)
        self.getGPSData(true)
        
        self.timeProgress!.hidden = false
        self.timeProgressNum = 0
        self.timeProgress.setProgress(0, animated: false)

        // start waiting timer
        timerOfStartWaiting = NSTimer.scheduledTimerWithTimeInterval(Constants.TIME_INTERVAL_START_WAITING, target: self, selector: "startWaiting", userInfo: nil, repeats: true)
        
        //debug timer
//        timerForDebugging = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "debugTimerSelector", userInfo: nil, repeats: true)
        
        leftRightArrowImageView!.hidden = false
        rightRightArrowImageView!.hidden = false
        step1ImageView!.image = UIImage(named: "off_1")
        step1ImageView!.hidden = false
        step2ImageView!.hidden = false
        step3ImageView!.hidden = false
        
    }
    
//    func debugTimerSelector() {
//        ++passedTime
//        passedTimeLabel.text = "t \(passedTime)"
//    }
    
    // return to main start button
    @IBOutlet weak var failedAndBackButtonOutlet: UIButton!
    @IBAction func failedAndBackButton(sender: UIButton) {
        sender.hidden = true
        failedAndBackButtonOutlet.backgroundColor = UIColor.redColor()
        failedAndBackButtonOutlet.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        startButtonOutlet!.hidden = false
//        promptsLabel!.hidden = true
        promptsLabel!.text = Constants.Prompts.BEFORE_PRE_CHECK
        
        self.leftRightArrowImageView!.hidden = true
        self.rightRightArrowImageView!.hidden = true
        self.step1ImageView!.hidden = true
        self.step2ImageView!.hidden = true
        self.step3ImageView!.hidden = true
        self.step1ImageView!.image = UIImage(named: "on_1")
        self.step2ImageView!.image = UIImage(named: "on_2")
        self.step3ImageView!.image = UIImage(named: "on_3")
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
        promptsLabel!.text = Constants.Prompts.PRE_CHECK_WALKING
        timeProgress!.hidden = false
        abortButtonOutlet!.hidden = false
        
        timerOfPrechecking = NSTimer.scheduledTimerWithTimeInterval(Constants.TIME_INTERVAL, target: self, selector: "updateProgress", userInfo: nil, repeats: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let firstUINavigationController = self.tabBarController?.childViewControllers[0] as! UINavigationController
        firstUIViewController = firstUINavigationController.childViewControllers[0] as! FirstViewController
        
        firstUIViewController.dataCollectionDelegate = self
        
        leftRightArrowImageView!.hidden = true
        rightRightArrowImageView!.hidden = true
        step1ImageView!.hidden = true
        step2ImageView!.hidden = true
        step3ImageView!.hidden = true
        
        abortButtonOutlet!.hidden = true
        stopDataCollectionOutlet!.hidden = true
        startDataCollectionOutlet!.hidden = true
        failedAndBackButtonOutlet!.hidden = true
//        promptsLabel!.hidden = true
        timeProgress!.hidden = true
        
        walkTimerLabel!.hidden = true
        self.promptsLabel.text = Constants.Prompts.BEFORE_PRE_CHECK
        
//        //debug
//        self.collectedDataLabel.hidden = true
//        self.uploadedDataLabel.hidden = true
//        self.accuracyDataLabel.hidden = true
//        self.averageAccuracyLabel.hidden = true
//        self.uploadedStatusLabel.hidden = true
//        self.passedTimeLabel.hidden = true

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func uploadingTimer() {
        
//        timerForDebugging.invalidate()
        
        timeProgressNum += Constants.TIME_INTERVAL_UPLOADING_CHANGE
        timeProgress.setProgress(timeProgressNum, animated: true)
        
        if timeProgress.progress == 1.0 {
            timerOfUploading.invalidate()
            timeProgress!.hidden = true

            let state: String = checkState(passedSeconds)
            uploadMarker(state)
            failedAndBackButtonOutlet!.hidden = false
            if state == Constants.States.SUCCESS + "_col:\(collectedData.count)" {
                failedAndBackButtonOutlet.backgroundColor = UIColor(red: 0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
                failedAndBackButtonOutlet.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            }
            
            abortButtonOutlet!.hidden = true

        }
    }
    
    func stopWaiting() {

        timeProgressNum += Constants.TIME_INTERVAL_STOP_WAITING_CHANGE
        timeProgress.setProgress(timeProgressNum, animated: true)
        
        if timeProgress.progress == 1.0 {
            
            leftRightArrowImageView!.hidden = true
            rightRightArrowImageView!.hidden = true
            step1ImageView!.hidden = true
            step2ImageView!.hidden = true
            step3ImageView!.hidden = true
            step3ImageView!.image = UIImage(named: "on_3")
            
            timerOfStopWaiting.invalidate()
            
            getGPSData(false)
            self.changeDistanceFilter(10)
            finishTime = NSDate()
            passedSeconds = finishTime.timeIntervalSinceDate(startTime)
            
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            promptsLabel.text = Constants.Prompts.WAITING_FOR_UPLOADING
            
            // uploading timer
            timeProgress!.hidden = true
            timeProgress.setProgress(0, animated: false)
            self.timeProgressNum = 0
            timeProgress!.hidden = false
            timerOfUploading = NSTimer.scheduledTimerWithTimeInterval(Constants.TIME_INTERVAL_UPLOADING, target: self, selector: "uploadingTimer", userInfo: nil, repeats: true)
        }
 
    }
    
    func startWaiting() {
        timeProgressNum += Constants.TIME_INTERVAL_START_WAITING_CHANGE
        timeProgress.setProgress(timeProgressNum, animated: true)
        if timeProgress.progress == 1.0 {
            timerOfStartWaiting.invalidate()
            timeProgress!.hidden = true
            
            stopDataCollectionOutlet!.hidden = false
            
            // timeout timer
            timerOfCollection = NSTimer.scheduledTimerWithTimeInterval(Constants.TIME_INTERVAL_COLLECTION, target: self, selector: "timeOutFunction", userInfo: nil, repeats: false)
            
            promptsLabel.text = Constants.Prompts.COLLECTING_DATA
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            step1ImageView!.image = UIImage(named: "on_1")
            step2ImageView!.image = UIImage(named: "off_2")
            
            // start walking timer
            self.walkTimerLabel!.text = "00:00"
            self.walkTimerLabel!.hidden = false
            timerOfWalking = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "updateWalkingTimer", userInfo: nil, repeats: true)
        }
    }
    
    
    func updateWalkingTimer() {
        walkTimerLabel!.text = findTimeString(NSDate().timeIntervalSinceDate(startTime) - 10.0)
    }
    
    private func findTimeString(seconds: NSTimeInterval) -> String {
        let min: Int = Int(seconds / 60)
        var minString = "\(min)"
        if min < 10 {
            minString = "0" + minString
        }
        
        let sec: Int = Int(seconds - Double(min) * 60)
        var secString = "\(sec)"
        if sec < 10 {
            secString = "0" + secString
        }
        return "\(minString):\(secString)"
    }
    
    func timeOutFunction() {
        timerOfCollection = nil
        
        getGPSData(false)
        self.changeDistanceFilter(10)
        stopDataCollectionOutlet!.hidden = true
        failedAndBackButtonOutlet!.hidden = false
        promptsLabel.text = Constants.Prompts.FAIL_TIME_OUT

        timerOfWalking.invalidate()
        walkTimerLabel!.hidden = true
        
        finishTime = NSDate()
        uploadMarker(Constants.States.FAIL_TIME_OUT)
    }
    
    func updateProgress() {
        timeProgressNum += Constants.TIME_INTERVAL_CHANGE
        timeProgress.setProgress(timeProgressNum, animated: true)
        if timeProgress.progress == 1.0 {
            getAccuracyData(false)
            timerOfPrechecking.invalidate()
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

    private func checkState(seconds: NSTimeInterval) -> String {
        var uploadedDataPoint = 0
        sync(self.startTime_uploadedNum_Dict) {
            uploadedDataPoint = self.startTime_uploadedNum_Dict[self.startTime]!
        }
        if seconds <= Constants.TIME_FOR_COLLECTION {
            promptsLabel.text = Constants.Prompts.FAIL_LOW_WALKING_TIME
            return Constants.States.FAIL_LOW_WALKING_TIME
        }
        else if walkingPercentageCheck(seconds) < Constants.COLLECTION_PERCENTAGE {
            promptsLabel.text = Constants.Prompts.FAIL_LOW_GPS_POINTS
            return Constants.States.FAIL_LOW_GPS_POINTS
        }
        else if getAverageAccuracy(self.collectedData) > Constants.AVERAGE_ACCURACY_THREHOLD {
            promptsLabel.text = Constants.Prompts.FAIL_LOW_ACCURACY
            return Constants.States.FAIL_LOW_ACCURACY
        }
        else if Double(uploadedDataPoint) / Double(collectedData.count) <= Constants.UPLOADED_PERCENTAGE {
            promptsLabel.text = Constants.Prompts.FAIL_BAD_NETWORK
            return Constants.States.FAIL_BAD_NETWORK
        }
        promptsLabel.text = Constants.Prompts.SUCCESS
        
        // plot
        // save data
        let finishTime = NSDate()
//        if dataModel == nil {
//            dataModel = DataModel()
//            if let (speedArray, timeArray) = dataModel.getExistingRecordsForToday(finishTime) {
//                chartDelegate?.initChartWithExistingRecords(speedArray, timeArray: timeArray)
//            }
//        }
        var speed = getAverageSpeed(collectedData)
        speed = speed >= 4.0 ? 4.0 : speed
        let (oldday, timeSec) = dataModel.saveData(finishTime, speed: speed, duration: 0, latitude: 0, longitude: 0, accuracy: 0, locTimestamp: finishTime)
        if oldday == false { // new day
            
            // notify core plot Chart VC
            chartDelegate?.updateChart(dataModel.dateOfTodayStr, speed: speed, time: timeSec)
        } else {
            // notify core plot Chart VC
            chartDelegate?.updateChart(speed, time: timeSec)
        }
        return Constants.States.SUCCESS + "_col:\(collectedData.count)"
    }
    
    private func walkingPercentageCheck(seconds: NSTimeInterval) -> Double {
        return Double(collectedData.count) / (seconds - Constants.START_WAITING_TIME - Constants.STOP_WAITING_TIME)
    }
    
    private func precheck() -> Bool {
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

    
    //delegate function for data collection
    func collectData(latitude: Double, longitude: Double, accuracy: Double, locTimestamp: NSDate) {
        collectedData.append(dataPoints(latitude: latitude, longitude: longitude, accuracy: accuracy, locTimestamp: locTimestamp))
        self.saveRemotely(latitude, longitude: longitude, accuracy: accuracy, locTimestamp: locTimestamp, startTime: startTime)
        
//        collectedDataLabel.text = "col \(accuracyCollectedData.count)"
//        accuracyDataLabel.text = "acc \(accuracy)"
//        averageAccuracyLabel.text = "avg \(self.getAverageFromDoubleArray(accuracyCollectedData))"
    }
    
    //delegate function for precheck
    func collectAccuracyData(accuracy: Double) {
        accuracyData.append(accuracy)
//        //debug
//        accuracyDataLabel.text = "acc \(accuracy)"
//        collectedDataLabel.text = "col \(accuracyData.count)"
    }
    
    private func getAverageFromDoubleArray(array: [Double]) -> Double {
        var sum: Double = 0
        for num in array {
            sum += num
        }
        return sum / Double(array.count)
    }
    
    private func getAverageAccuracy(pointsArray: [dataPoints]) -> Double {
        var sum: Double = 0
        for point in pointsArray {
            sum += point.accuracy
        }
        return sum / Double(pointsArray.count)
    }
    
    private func getAverageSpeed(pointsArray: [dataPoints]) -> Double {
        var sum: Double = 0
        for var i = 1; i < pointsArray.count; ++i {
            let loc1 = CLLocation(latitude: pointsArray[i-1].latitude, longitude: pointsArray[i-1].longitude)
            let loc2 = CLLocation(latitude: pointsArray[i].latitude, longitude: pointsArray[i].longitude)
            let distance = loc1.distanceFromLocation(loc2)
            
            let time1 = pointsArray[i-1].locTimestamp
            let time2 = pointsArray[i].locTimestamp
            let timeDiff = time2.timeIntervalSinceDate(time1)
            sum += distance / timeDiff
        }
        return sum / Double(pointsArray.count)
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
    
    private func saveRemotely(latitude: Double, longitude: Double, accuracy: Double, locTimestamp: NSDate, startTime: NSDate) {
        // save all data locally and remotely
        let point = PFGeoPoint(latitude:latitude, longitude: longitude)
        
        let record = PFObject(className: "DataCollection")
        
        record["user"] = firstUIViewController.userID
        record["location"] = point
        record["accuracy"] = accuracy
        record["locTimestamp"] = locTimestamp
        record.saveInBackgroundWithBlock { (result:Bool, error:NSError?) -> Void in
            if !result {
            } else {
                sync(self.startTime_uploadedNum_Dict) {
                    self.startTime_uploadedNum_Dict[startTime]! += 1
                }
//                dispatch_async(dispatch_get_main_queue()) {
//                    self.uploadedDataLabel.text = "up \(self.startTime_uploadedNum_Dict[startTime]!)"
//                }
//                ++self.uploadedDataNum
//                self.uploadedDataLabel.text = "up \(self.uploadedDataNum)"
            }
        }

    }
    
    private func uploadMarker(state: String) {
        let marker = PFObject(className: "Markers")
        marker["user"] = firstUIViewController.userID
        marker["startTime"] = startTime
        marker["finishTime"] = finishTime
        marker["state"] = state

        marker.saveInBackgroundWithBlock { (result:Bool, error:NSError?) -> Void in
            if !result {
            } else {
//                self.uploadedStatusLabel.text = state
            }
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
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

