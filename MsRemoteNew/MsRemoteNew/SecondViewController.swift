//
//  SecondViewController.swift
//  MsRemoteNew
//
//  Created by chao on 04/03/2015.
//  Copyright (c) 2015 Imperial College London. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController, JBLineChartViewDelegate, JBLineChartViewDataSource, UpdateChartDelegate {
    var lineChartView = JBLineChartView()
    var dataToDisplay = [Double]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let NaviVC = self.tabBarController!.viewControllers![0] as UINavigationController
        let FirstVC = NaviVC.topViewController as FirstViewController
        FirstVC.chartDelegate = self
        
        // Graph generation
        lineChartView.dataSource = self
        lineChartView.delegate = self
        lineChartView.backgroundColor = UIColor.whiteColor()
        
        lineChartView.frame = CGRectMake(0 + 20, 32 + 20, self.view.frame.size.width - 40, self.view.frame.size.height - 49 - 32 - 20);
        lineChartView.minimumValue = CGFloat(0)
        lineChartView.maximumValue = CGFloat(60)
        self.view.addSubview(lineChartView);
        lineChartView.reloadData();
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    // Graph properties
    func numberOfLinesInLineChartView(lineChartView: JBLineChartView!) -> UInt {
        return 1
    }
    
    func lineChartView(lineChartView: JBLineChartView, numberOfVerticalValuesAtLineIndex lineIndex: UInt) -> UInt {
        
        return UInt(dataToDisplay.count)
    }
    
    func lineChartView(lineChartView: JBLineChartView!, verticalValueForHorizontalIndex horizontalIndex: UInt, atLineIndex lineIndex: UInt) -> CGFloat {
        
        var result = CGFloat(dataToDisplay[Int(horizontalIndex)])

        return result
    }
    
    func lineChartView(lineChartView: JBLineChartView!, widthForLineAtLineIndex lineIndex: UInt) -> CGFloat {
        return CGFloat(1)
    }
    
    func lineChartView(lineChartView: JBLineChartView!, fillColorForLineAtLineIndex lineIndex: UInt) -> UIColor! {
        
        return UIColor(red:0.0, green:0.81,blue:1,alpha:0.5)
    }
    
    func lineChartView(lineChartView: JBLineChartView!, colorForLineAtLineIndex lineIndex: UInt) -> UIColor! {
        return UIColor(red:0.48, green:0.82,blue:1,alpha:0.8)
    }
    
    // delegate methods
    func updateChart(speed: Double) {
        dataToDisplay.append(speed)
        lineChartView.reloadData();
    }

    func updateChart(newDate: String, speed: Double) {
        dataToDisplay.removeAll(keepCapacity: false)
        dataToDisplay.append(speed)
        lineChartView.reloadData();
    }
}

