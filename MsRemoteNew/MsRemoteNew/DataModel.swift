//
//  DataModel.swift
//  MsRemoteNew
//
//  Created by Simiao Yu on 27/03/2015.
//  Copyright (c) 2015 Imperial College London. All rights reserved.
//

import Foundation

struct dataFormat {
    let timeFrom0AM: NSTimeInterval
    let speed: Double
}

class DataModel {

    let formatter = NSDateFormatter()
    var DateData = [String:[dataFormat]]()
    var dateOfTodayStr: String = ""
    var today0AM: NSDate!
    
    init() {
        formatter.dateFormat = "d/M/yyyy"
    }
    
    func saveData(time: NSDate, speed: Double) -> (Bool, NSTimeInterval) {
        let date = formatter.stringFromDate(time)
        
        // new day begins
        if dateOfTodayStr != date {
            
            dateOfTodayStr = date
            today0AM = formatter.dateFromString(date)!
            
            let timeElapsed = NSDate().timeIntervalSinceDate(today0AM)
            DateData[date] = [dataFormat(timeFrom0AM: timeElapsed, speed: speed)]

            return (false, timeElapsed)
        }
        
        // for today
        let timeElapsed = NSDate().timeIntervalSinceDate(today0AM)
        DateData[date]!.append(dataFormat(timeFrom0AM: timeElapsed, speed: speed))
        return (true, timeElapsed)
    }
    
}