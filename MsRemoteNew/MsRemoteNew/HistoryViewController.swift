//
//  HistoryViewController.swift
//  MsRemoteNew
//
//  Created by Simiao Yu on 05/04/2015.
//  Copyright (c) 2015 Imperial College London. All rights reserved.
//

import UIKit

class HistoryViewController: UIViewController, CPTPlotDataSource {
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var dataModel = DataModel()
    var graphView: CPTGraphHostingView!
    var timeData = [Double]()
    var speedData = [Double]()
    var day: NSDate!
    var formattedDate: String!
    var NumOfRecords: Int!
    
//    private let timeIntervalToShowData: Int = 15
    
//    var compressSpeedWithFixedTimePoint: [[Double]?]!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // configure plot parameters
//        let slotNum = 60 * 24 / timeIntervalToShowData
//        compressSpeedWithFixedTimePoint = [[Double]?](count: slotNum, repeatedValue: nil)
        
        // Do any additional setup after loading the view.
        fetchData()
    }
    
    private func fetchData() {
        spinner?.startAnimating()
        let qos = Int(QOS_CLASS_USER_INITIATED.rawValue)
        dispatch_async(dispatch_get_global_queue(qos, 0)) { () -> Void in
//            var speed = [Double]()
//            var time = [Double]()

            (self.speedData, self.timeData) = self.dataModel.getHistoryTimeSpeedData(self.NumOfRecords, day: self.day)
//            if speed.count != 0 && time.count == speed.count {
//                for i in 0...speed.count-1 {
//                    let index = Int(time[i] / Double(self.timeIntervalToShowData * 60))
//                    if self.compressSpeedWithFixedTimePoint[index] == nil {
//                        self.compressSpeedWithFixedTimePoint[index] = [Double]()
//                    }
//                    self.compressSpeedWithFixedTimePoint[index]!.append(speed[i])
//                }
//            }
            
//            self.generatePlotData()
            dispatch_async(dispatch_get_main_queue()) {
                self.spinner?.stopAnimating()
                self.configureHost()
                self.configureGraph()
                self.configurePlot()
                self.configureAxes()
            }
        }
    }
    
//    private func generatePlotData() {
//        for i in 0..<compressSpeedWithFixedTimePoint.count {
//            if let speedArray = compressSpeedWithFixedTimePoint[i] {
//                let averageSpeed = averageOf(speedArray)
//                speedData.append(averageSpeed)
//                let supposedTimePoint: Double = (Double(i) + 0.5) * Double(timeIntervalToShowData * 60)
//                timeData.append(supposedTimePoint)
//            }
//        }
//    }
//    
//    private func averageOf(data: [Double]) -> Double {
//        if data.count == 0 { return 0 }
//        var sum: Double = 0
//        for i in data {
//            sum += i
//        }
//        return sum / Double(data.count)
//    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    // (Required) The number of data points for the plot.
    func numberOfRecordsForPlot(plot: CPTPlot!) -> UInt {
        return UInt(speedData.count)
    }
    
    func doubleForPlot(plot: CPTPlot!, field fieldEnum: UInt, recordIndex idx: UInt) -> Double {
        if fieldEnum == UInt(CPTScatterPlotField.X.rawValue) {
            return timeData[Int(idx)]
        } else {
            return speedData[Int(idx)]
        }
    }

    // create host view
    func configureHost() {
        let naviBarHeight = self.navigationController!.navigationBar.frame.size.height
        let statusHeight = UIApplication.sharedApplication().statusBarFrame.size.height
        
        graphView = CPTGraphHostingView(frame: CGRect(x: 0, y: naviBarHeight + statusHeight, width: self.view.frame.width, height: self.view.frame.height - naviBarHeight - statusHeight))
        graphView.allowPinchScaling = false
        self.view.addSubview(graphView)
    }
    
    // create graph
    func configureGraph() {
        let graph = CPTXYGraph(frame: graphView.bounds)
        graphView.hostedGraph = graph
        graph.title = "\(formattedDate) with \(NumOfRecords) records"
        graph.paddingBottom = CGFloat(0)
        graph.paddingTop = CGFloat(0)
        graph.paddingLeft = CGFloat(0)
        graph.paddingRight = CGFloat(0)
        
        graph.plotAreaFrame.paddingBottom = CGFloat(40)
        graph.plotAreaFrame.paddingTop = CGFloat(20)
        graph.plotAreaFrame.paddingLeft = CGFloat(40)
        graph.plotAreaFrame.paddingRight = CGFloat(20)
        
        let plotSpace = graph.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.xRange = CPTPlotRange(location: NSNumber(int: 0), length: NSNumber(int: 86400))
        plotSpace.yRange = CPTPlotRange(location: NSNumber(int: 0), length: NSNumber(float: 4.2))
    }
    
    // configure plot
    func configurePlot() {
        // add scatter plot
        let scatPlot = CPTScatterPlot(frame: self.graphView.hostedGraph.frame)
        scatPlot.dataSource = self
        self.graphView.hostedGraph.addPlot(scatPlot, toPlotSpace: self.graphView.hostedGraph.defaultPlotSpace)
        
        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineWidth = 0.5
        let lineColor = CPTColor.blueColor()
        lineStyle.lineColor = lineColor.colorWithAlphaComponent(1)
        
        scatPlot.dataLineStyle = nil

        
        let plotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
        plotSymbol.fill = CPTFill(color: CPTColor(componentRed: 0, green: 0, blue: 1, alpha: 0.5))
        plotSymbol.lineStyle = nil
        plotSymbol.size = CGSizeMake(10.0, 10.0)
        scatPlot.plotSymbol = plotSymbol
    }
    
    // configure axes
    func configureAxes() {
        let axisSet = self.graphView.hostedGraph.axisSet as! CPTXYAxisSet
        
        let axisTextStyle = CPTMutableTextStyle()
        axisTextStyle.color = CPTColor.blackColor()
        axisTextStyle.fontName = "Helvetica-Bold"
        axisTextStyle.fontSize = CGFloat(12.0)
        
        let axisLineStyle = CPTMutableLineStyle()
        axisLineStyle.lineWidth = CGFloat(2)
        axisLineStyle.lineColor = CPTColor.blackColor()
        
        let xAxisTickLineStype = CPTMutableLineStyle()
        xAxisTickLineStype.lineWidth = CGFloat(0.5)
        xAxisTickLineStype.lineColor = CPTColor.redColor()
        xAxisTickLineStype.dashPattern = [CGFloat(1), CGFloat(1)]
        
        // for x axis
        let x = axisSet.xAxis
        x.title = "Time of day (hours)"
        x.titleOffset = CGFloat(-35)
        x.titleTextStyle = axisTextStyle
        x.axisLineStyle = axisLineStyle
        x.labelingPolicy = CPTAxisLabelingPolicy.None
        x.labelTextStyle = axisTextStyle
        x.majorTickLineStyle = xAxisTickLineStype
        x.majorTickLength = CGFloat(self.graphView.frame.height - 40 - 20)
        x.tickDirection = CPTSign.Positive
        
        let xLabels = NSMutableSet(capacity: 25)
        let xLocations = NSMutableSet(capacity: 25)
        
        for i in 0...24 {
            let label = CPTAxisLabel(text: "\(i)", textStyle: axisTextStyle)
            let location = NSNumber(int: Int32(i) * 3600)
            label.tickLocation = location
            label.offset = CGFloat(-20)
            xLabels.addObject(label)
            xLocations.addObject(location)
        }
        
        x.axisLabels = xLabels as Set<NSObject>
        x.majorTickLocations = xLocations as Set<NSObject>
        
        // for y axis
        let y = axisSet.yAxis
        y.title = "Speed (m/s)"
        y.titleOffset = CGFloat(-35)
        y.titleTextStyle = axisTextStyle
        y.axisLineStyle = axisLineStyle
        y.labelingPolicy = CPTAxisLabelingPolicy.None
        y.labelTextStyle = axisTextStyle
        y.majorTickLineStyle = xAxisTickLineStype
        y.majorTickLength = CGFloat(self.graphView.frame.width - 40 - 20)
        y.tickDirection = CPTSign.Positive
        
        let yLabels = NSMutableSet(capacity: 13)
        let yLocations = NSMutableSet(capacity: 13)
        
        for i in 0...8 {
            let label = CPTAxisLabel(text: "\(Float(i) * 0.5)", textStyle: axisTextStyle)
            let location = NSNumber(float: Float(i) * 0.5)
            label.tickLocation = location
            label.offset = CGFloat(-20)
            yLabels.addObject(label)
            yLocations.addObject(location)
        }
        y.axisLabels = yLabels as Set<NSObject>
        y.majorTickLocations = yLocations as Set<NSObject>
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
