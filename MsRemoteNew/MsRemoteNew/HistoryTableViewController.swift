//
//  HistoryTableViewController.swift
//  MsRemoteNew
//
//  Created by Simiao Yu on 04/04/2015.
//  Copyright (c) 2015 Imperial College London. All rights reserved.
//

import UIKit

class HistoryTableViewController: UITableViewController {
    @IBAction func returnToCorePlotViewController(segue:UIStoryboardSegue) {
        
    }
    private struct History {
        static let ReuseIdentifier = "History"
        static let SegueIdentifier = "Show Spec History"
    }
    
    private struct DateTrans {
        let date: NSDate
        let records: Int
    }
    
    private var datesWithRecords = [DateTrans]()
    private var selectedData: DateTrans!
    
    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: 150, height: 200)
        }
        set {super.preferredContentSize = newValue}
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // get all available dates
        getHistory()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return datesWithRecords.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(History.ReuseIdentifier, forIndexPath: indexPath) as UITableViewCell

        // Configure the cell...
        cell.textLabel?.text = dateFormatter(datesWithRecords[indexPath.row].date)
        cell.detailTextLabel?.text = "\(datesWithRecords[indexPath.row].records) records"
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        selectedData = datesWithRecords[indexPath.row]
        performSegueWithIdentifier(History.SegueIdentifier, sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case History.SegueIdentifier:
                if let NaviVC = segue.destinationViewController as? UINavigationController {
                    let HistoryVC = NaviVC.topViewController as HistoryViewController
                    HistoryVC.NumOfRecords = selectedData.records
                    HistoryVC.day = selectedData.date
                    HistoryVC.formattedDate = dateFormatter(selectedData.date)
                }
            default: break
            }
        }
    }
    
    func getHistory() {
        if var dict = NSUserDefaults.standardUserDefaults().dictionaryForKey("MSRecord") as? [String: Int] {
            // get date string of today
            let formatter = NSDateFormatter()
            formatter.dateFormat = "d/M/yyyy"
            formatter.timeZone = NSTimeZone(name: "UCT")
            let date = formatter.stringFromDate(NSDate())
            // remove today from dict
            dict.removeValueForKey(date)

            for (key, value) in dict {
                datesWithRecords.append(DateTrans(date: formatter.dateFromString(key)!, records: value))
            }
            datesWithRecords.sort() {$0.0.date.compare($1.0.date) == NSComparisonResult.OrderedAscending}
        }
        
    }
    
    func dateFormatter(date: NSDate) -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.stringFromDate(date)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

}
