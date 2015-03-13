//
//  SecondViewController.swift
//  MsRemoteNew
//
//  Created by chao on 04/03/2015.
//  Copyright (c) 2015 Imperial College London. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController, JBLineChartViewDelegate, JBLineChartViewDataSource {
    var lineChartView = JBLineChartView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Graph generation
        lineChartView.dataSource = self
        lineChartView.delegate = self
        lineChartView.backgroundColor = UIColor.whiteColor()
        
        lineChartView.frame = CGRectMake(0, 32, self.view.frame.size.width, self.view.frame.size.height - 49 - 32);
        lineChartView.minimumValue = CGFloat(0)
        lineChartView.maximumValue = CGFloat(100)
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
        
        return 100
    }
    
    func lineChartView(lineChartView: JBLineChartView!, verticalValueForHorizontalIndex horizontalIndex: UInt, atLineIndex lineIndex: UInt) -> CGFloat {
        return CGFloat(arc4random_uniform(100))
    }
    
    func lineChartView(lineChartView: JBLineChartView!, widthForLineAtLineIndex lineIndex: UInt) -> CGFloat {
        return CGFloat(1)
    }

}

