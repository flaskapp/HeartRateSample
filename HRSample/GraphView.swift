//
//  GraphView.swift
//  HRSample
//
//  Created by Ogawa Hideko on 4/28/15.
//  Copyright (c) 2015 Flask LLP. All rights reserved.
//

import UIKit
import HealthKit

class GraphView: UIView {
    var graphLayer = CAShapeLayer()
    var averateLayer = CAShapeLayer()
    var selectLayer = CALayer()
    var graphPath = UIBezierPath()
    var averatePath = UIBezierPath()
    let margin:CGFloat = 10
    let heartRateUnit: HKUnit = HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit())
    var min:Double = 40
    var max:Double = 180
    var pointDatas = Dictionary<CGFloat, HKStatistics>()
    @IBOutlet var durationLabel:UILabel!
    @IBOutlet var averageLabel:UILabel!
    @IBOutlet var minLabel:UILabel!
    @IBOutlet var maxLabel:UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if graphLayer.superlayer == nil {
            graphLayer.frame = CGRect(origin: CGPointZero, size: self.frame.size)
            graphLayer.lineWidth = 5.0
            graphLayer.lineCap = kCALineCapRound
            graphLayer.lineJoin = kCALineJoinRound
            graphLayer.strokeColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.2).CGColor
            self.layer.addSublayer(graphLayer)
            averateLayer.frame = CGRect(origin: CGPointZero, size: self.frame.size)
            averateLayer.lineWidth = 5.0
            averateLayer.lineCap = kCALineCapRound
            averateLayer.lineJoin = kCALineJoinRound
            averateLayer.strokeColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.9).CGColor
            self.layer.addSublayer(averateLayer)
            
            selectLayer.frame = CGRect(origin: CGPointZero, size: CGSize(width: 1, height: self.frame.size.height))
            selectLayer.backgroundColor = UIColor(red: 1.0, green: 0, blue: 0, alpha: 1.0).CGColor
            self.layer.addSublayer(selectLayer)
        }
    }
    
    func applyPathForAllDatas(datas:[HKQuantitySample], startDate:NSDate, endDate:NSDate) {
        let width = self.frame.size.width - (2 * margin)
        let xRate = width / CGFloat(endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970)
        let height:CGFloat = self.frame.size.height - (2 * margin)
        let yRate = height / CGFloat(max - min)
        let path = UIBezierPath()
        for data in datas {
            let quantity = data.quantity
            var value:Double = quantity.doubleValueForUnit(heartRateUnit)
            let x = CGFloat(data.startDate.timeIntervalSince1970 - startDate.timeIntervalSince1970) * xRate + margin
            let y:CGFloat = graphLayer.frame.size.height - (CGFloat(value - min) * yRate + margin)
            path.moveToPoint(CGPointMake(x, y))
            path.addLineToPoint(CGPointMake(x, y))
        }
        self.graphPath = path
        self.averatePath = UIBezierPath()
        pointDatas.removeAll(keepCapacity: false)
    }
    
    func applyPathForAverageDatas(collection:HKStatisticsCollection, startDate:NSDate, endDate:NSDate) {
        let width = self.frame.size.width - (2 * margin)
        let xRate = width / CGFloat(endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970)
        let height:CGFloat = self.frame.size.height - (2 * margin)
        let yRate = height / CGFloat(max - min)
        
        let path = UIBezierPath()
        let avePath = UIBezierPath()
        let viewHeight = self.frame.size.height
        pointDatas.removeAll(keepCapacity: false)

        for item in collection.statistics() {
            let statistics:HKStatistics = item as! HKStatistics
            let x:CGFloat = CGFloat(statistics.startDate.timeIntervalSince1970 - startDate.timeIntervalSince1970) * xRate + margin
            pointDatas[x] = statistics
            let maxQuantity = statistics.maximumQuantity()
            if maxQuantity != nil {
                var maxValue:Double = maxQuantity.doubleValueForUnit(heartRateUnit)
                let maxY:CGFloat = viewHeight - (CGFloat(maxValue - min) * yRate + margin)
                let minQuantity = statistics.minimumQuantity()
                if minQuantity != nil {
                    var minValue:Double = minQuantity.doubleValueForUnit(heartRateUnit)
                    let minY:CGFloat = viewHeight - (CGFloat(minValue - min) * yRate + margin)
                    path.moveToPoint(CGPointMake(x, minY))
                    path.addLineToPoint(CGPointMake(x, maxY))
                }
            }
            let quantity = statistics.averageQuantity()
            var value:Double = quantity.doubleValueForUnit(heartRateUnit)
            if value > 0 {
                let y:CGFloat = graphLayer.frame.size.height - (CGFloat(value - min) * yRate + margin)
                avePath.moveToPoint(CGPointMake(x, y))
                avePath.addLineToPoint(CGPointMake(x, y))
            }
        }
        self.graphPath = path
        self.averatePath = avePath
    }
    
    func updatePath() {
        graphLayer.path = graphPath.CGPath
        graphLayer.setNeedsDisplay()
        averateLayer.path = averatePath.CGPath
        averateLayer.setNeedsDisplay()
        self.showDetailViewWithX(0)
    }

    //MARK: Touch
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        showDetailViewWithTouches(touches)
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        showDetailViewWithTouches(touches)
    }
    
    private func showDetailViewWithTouches(touches: NSSet) {
        let touch:UITouch = touches.anyObject() as! UITouch
        let point:CGPoint = touch.locationInView(self)
        self.showDetailViewWithX(point.x)
    }

    private func showDetailViewWithX(x: CGFloat) {
        let targets:(current:HKStatistics?, currentX:CGFloat) = statisticsWithX(x)
        if targets.current == nil {
            durationLabel.text = ""
            averageLabel.text = ""
            maxLabel.text = ""
            minLabel.text = ""
            selectLayer.hidden = true
            return
        } else {
            selectLayer.frame = CGRect(origin: CGPoint(x: targets.currentX - 0.5, y: 0), size: selectLayer.frame.size)
            selectLayer.hidden = false
            let statistics = targets.current!
            let formatter = NSDateFormatter()
            formatter.dateStyle = NSDateFormatterStyle.MediumStyle
            formatter.timeStyle = NSDateFormatterStyle.ShortStyle
            durationLabel.text = "\(formatter.stringFromDate(statistics.startDate)) - \(formatter.stringFromDate(statistics.endDate))"
            
            let quantity = statistics.averageQuantity()
            var value:Double = quantity.doubleValueForUnit(heartRateUnit)
            averageLabel.text = "\(value)"
            
            let maxQuantity = statistics.maximumQuantity()
            var maxValue:Double = maxQuantity.doubleValueForUnit(heartRateUnit)
            maxLabel.text = "\(maxValue)"
            
            let minQuantity = statistics.minimumQuantity()
            var minValue:Double = minQuantity.doubleValueForUnit(heartRateUnit)
            minLabel.text = "\(minValue)"
        }
    }

    private func statisticsWithX(x:CGFloat) -> (current:HKStatistics?, currentX:CGFloat) {
        if (pointDatas.count == 0) {
            return (nil, 0)
        }
        var minDiffX:Float = -1
        var minKey:CGFloat? = nil
        var previousKey:NSNumber? = nil
        var beforeKey:NSNumber? = nil
        var keys:[CGFloat] = Array(pointDatas.keys)
        keys.sort { (obj1:CGFloat, obj2:CGFloat) -> Bool in
            return obj1 < obj2
        }
        for number:CGFloat in keys {
            let datax:Float = Float(number)
            var diff = Float(x) - datax
            if diff < 0 {
                diff = -1 * diff
            }
            if minDiffX == -1 || minDiffX > diff {
                minDiffX = diff
                previousKey = beforeKey
                minKey = number
            }
            beforeKey = number
        }
        var current:HKStatistics? = nil
        var currentX:CGFloat = 0
        if minKey != nil {
            current = pointDatas[minKey!]
            currentX = minKey!
        }
        return (current:current, currentX:currentX)
    }
}
