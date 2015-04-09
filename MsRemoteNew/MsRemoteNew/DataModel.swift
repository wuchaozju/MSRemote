//
//  DataModel.swift
//  MsRemoteNew
//
//  Created by Simiao Yu on 27/03/2015.
//  Copyright (c) 2015 Imperial College London. All rights reserved.
//

import Foundation

// for similar synchronised method in objc
func sync(lock: AnyObject, closure: () -> Void) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}

struct recordedData {
    let dayOfDate: String
    let speed: Double
    let timePoint: Double
    let latitude: Double
    let longitude: Double
    let groupOfDay: Int
}

class DataModel {

    private let formatter = NSDateFormatter()
    var dateOfTodayStr: String = ""
    var today0AM: NSDate!
    
    init() {
        formatter.dateFormat = "d/M/yyyy"
    }
    
    func getHistoryTimeSpeedData(NumOfRecords: Int, day: NSDate) -> ([Double], [Double]) {
        let date = formatter.stringFromDate(day)
        return querySpeedTimepointData(NumOfRecords, currentDay: date)
    }
    
    func getExistingRecordsForToday(currentTime: NSDate) -> ([Double], [Double])? {
        
        let date = formatter.stringFromDate(currentTime)
        
        if let dict = NSUserDefaults.standardUserDefaults().dictionaryForKey("MSRecord") as? [String: Int] {
            if let recordsNumForToday = dict[date] {
                dateOfTodayStr = date
                today0AM = formatter.dateFromString(date)!
                
                // query all existing data for today
                return querySpeedTimepointData(recordsNumForToday, currentDay: date)
            }
        }
        return nil
    }
    
    func saveData(time: NSDate, speed: Double, latitude: Double, longitude: Double) -> (Bool, NSTimeInterval) {
        
        let date = formatter.stringFromDate(time)        
        
        // new day begins
        if dateOfTodayStr != date {
            
            dateOfTodayStr = date
            today0AM = formatter.dateFromString(date)!
            
            var dict = NSUserDefaults.standardUserDefaults().dictionaryForKey("MSRecord") as? [String: Int]
            
            if dict == nil {
                var newDict = [String: Int]()
                newDict[date] = 1
                NSUserDefaults.standardUserDefaults().setObject(newDict, forKey: "MSRecord")
            } else {
                dict![date] = 1
                NSUserDefaults.standardUserDefaults().setObject(dict, forKey: "MSRecord")
            }
            
            let timeElapsed = NSDate().timeIntervalSinceDate(today0AM)
            
            let newRecord = recordedData(dayOfDate: date, speed: speed, timePoint: timeElapsed, latitude: latitude, longitude: longitude, groupOfDay: 0)
            saveLocallyAndRemotely(newRecord)

            return (false, timeElapsed)
        }
        
        // for today
        var currentPoints: Int = 0
        if var dict = NSUserDefaults.standardUserDefaults().dictionaryForKey("MSRecord") as? [String: Int] {
            if var numberOfRecords = dict[date] {
                numberOfRecords += 1
                dict[date] = numberOfRecords
                currentPoints = numberOfRecords
                NSUserDefaults.standardUserDefaults().setObject(dict, forKey: "MSRecord")
            }
        }
        
        let timeElapsed = NSDate().timeIntervalSinceDate(today0AM)
        let newRecord = recordedData(dayOfDate: date, speed: speed, timePoint: timeElapsed, latitude: latitude, longitude: longitude, groupOfDay: currentPoints / 1000)
        saveLocallyAndRemotely(newRecord)
        
        return (true, timeElapsed)
    }

    private func saveLocallyAndRemotely(newRecord: recordedData) {
        
        // save all data locally and remotely
        let point = PFGeoPoint(latitude:newRecord.latitude, longitude:newRecord.longitude)

        var record = PFObject(className: "UserLocation")
        
        // for stored user ID
        // use name of current device if no valid user ID is found
        let userID = NSUserDefaults.standardUserDefaults().stringForKey("userID") ?? UIDevice.currentDevice().name
        
        record["user"] = userID
        record["location"] = point
        record["speed"] = newRecord.speed
        record["timePoint"] = newRecord.timePoint
        record["day"] = newRecord.dayOfDate
        record["groupOfDay"] = newRecord.groupOfDay
        
        record.pinInBackgroundWithBlock { (result:Bool, error:NSError!) -> Void in

        }

        record.saveEventually { (result:Bool, error:NSError!) -> Void in
            
        }

    }
    
    func querySpeedTimepointData(NumOfRecords: Int, currentDay: String) -> ([Double], [Double]){
        
        var timeArray = [Double]()
        var speedArray = [Double]()
        
        let groupsNum: Int = NumOfRecords / 1000
        for i in 0...groupsNum {
            let query = PFQuery(className: "UserLocation")
            query.fromLocalDatastore()
            query.whereKey("day", equalTo: currentDay)
            query.whereKey("groupOfDay", equalTo: i)
            query.limit = 1000
            
            let objects = query.findObjects() as! [PFObject]
            for object in objects {
                speedArray.append(object["speed"] as! Double)
                timeArray.append(object["timePoint"] as! Double)
            }
        }
        return (speedArray, timeArray)
    }

}