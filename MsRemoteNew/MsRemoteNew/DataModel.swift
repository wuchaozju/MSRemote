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
    
    func saveData(time: NSDate, speed: Double) -> Bool {
        let date = formatter.stringFromDate(time)

        // new day begins
        if dateOfTodayStr != date {
            
            dateOfTodayStr = date
            today0AM = formatter.dateFromString(date)!
            
            DateData[date] = [dataFormat(timeFrom0AM: NSDate().timeIntervalSinceDate(today0AM), speed: speed)]

            return false
        }
        
        // for today
        DateData[date]!.append(dataFormat(timeFrom0AM: NSDate().timeIntervalSinceDate(today0AM), speed: speed))
        return true
    }
    
}