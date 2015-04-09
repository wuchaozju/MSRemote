//
//  HistoryViewController.swift
//  MsRemoteNew
//
//  Created by Simiao Yu on 05/04/2015.
//  Copyright (c) 2015 Imperial College London. All rights reserved.
//

import UIKit

class HistoryViewController: UIViewController, CPTPlotDataSource {
    
    var dataModel = DataModel()
    var graphView: CPTGraphHostingView!
    var timeData = [Double]()
    var speedData = [Double]()
    var day: NSDate!
    var formattedDate: String!
    var NumOfRecords: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.configureHost()
        self.configureGraph()
        self.configurePlot()
        self.configureAxes()
        
        (speedData, timeData) = dataModel.getHistoryTimeSpeedData(NumOfRecords, day: day)

    }
    
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
        var graph = CPTXYGraph(frame: graphView.bounds)
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
        
        var plotSpace = graph.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.xRange = CPTPlotRange(location: NSNumber(int: 0), length: NSNumber(int: 86400))
        plotSpace.yRange = CPTPlotRange(location: NSNumber(int: 0), length: NSNumber(int: 60))
    }
    
    // configure plot
    func configurePlot() {
        // add scatter plot
        var scatPlot = CPTScatterPlot(frame: self.graphView.hostedGraph.frame)
        scatPlot.dataSource = self
        self.graphView.hostedGraph.addPlot(scatPlot, toPlotSpace: self.graphView.hostedGraph.defaultPlotSpace)
        
        scatPlot.dataLineStyle = nil
        
        var plotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
        plotSymbol.size = CGSizeMake(0.5, 0.5)
        plotSymbol.fill = CPTFill(color: CPTColor.blueColor())
        scatPlot.plotSymbol = plotSymbol
        
        //        // configure plot styles
        //        var plotLineStyle = scatPlot.dataLineStyle.mutableCopy() as CPTMutableLineStyle
        //        plotLineStyle.lineWidth = 0.5
        //        plotLineStyle.lineColor = CPTColor.blueColor()
        //        scatPlot.dataLineStyle = plotLineStyle
    }
    
    // configure axes
    func configureAxes() {
        var axisSet = self.graphView.hostedGraph.axisSet as! CPTXYAxisSet
        
        var axisTextStyle = CPTMutableTextStyle()
        axisTextStyle.color = CPTColor.blackColor()
        axisTextStyle.fontName = "Helvetica-Bold"
        axisTextStyle.fontSize = CGFloat(12.0)
        
        var axisLineStyle = CPTMutableLineStyle()
        axisLineStyle.lineWidth = CGFloat(2)
        axisLineStyle.lineColor = CPTColor.blackColor()
        
        var xAxisTickLineStype = CPTMutableLineStyle()
        xAxisTickLineStype.lineWidth = CGFloat(0.5)
        xAxisTickLineStype.lineColor = CPTColor.redColor()
        xAxisTickLineStype.dashPattern = [CGFloat(1), CGFloat(1)]
        
        // for x axis
        var x = axisSet.xAxis
        x.title = "Time of day (hours)"
        x.titleOffset = CGFloat(-35)
        x.titleTextStyle = axisTextStyle
        x.axisLineStyle = axisLineStyle
        x.labelingPolicy = CPTAxisLabelingPolicy.None
        x.labelTextStyle = axisTextStyle
        x.majorTickLineStyle = xAxisTickLineStype
        x.majorTickLength = CGFloat(self.graphView.frame.height - 40 - 20)
        x.tickDirection = CPTSign.Positive
        
        var xLabels = NSMutableSet(capacity: 25)
        var xLocations = NSMutableSet(capacity: 25)
        
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
        var y = axisSet.yAxis
        y.title = "Speed (m/s)"
        y.titleOffset = CGFloat(-35)
        y.titleTextStyle = axisTextStyle
        y.axisLineStyle = axisLineStyle
        y.labelingPolicy = CPTAxisLabelingPolicy.None
        y.labelTextStyle = axisTextStyle
        y.majorTickLineStyle = xAxisTickLineStype
        y.majorTickLength = CGFloat(self.graphView.frame.width - 40 - 20)
        y.tickDirection = CPTSign.Positive
        
        var yLabels = NSMutableSet(capacity: 13)
        var yLocations = NSMutableSet(capacity: 13)
        
        for i in 0...12 {
            let label = CPTAxisLabel(text: "\(i*5)", textStyle: axisTextStyle)
            let location = NSNumber(int: Int32(i) * 5)
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
