//
//  ViewController.swift
//  HRSample
//
//  Created by Ogawa Hideko on 4/28/15.
//  Copyright (c) 2015 Flask LLP. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    @IBOutlet var graphView:GraphView!
    @IBOutlet var dateLabel:UILabel!
    @IBOutlet var intervalLabel:UILabel!
    @IBOutlet var intervalSegment:UISegmentedControl!
    @IBOutlet var intervalStepper:UIStepper!
    @IBOutlet var durationLabel:UILabel!
    @IBOutlet var durationSegment:UISegmentedControl!
    @IBOutlet var durationStepper:UIStepper!
    @IBOutlet var activityIndicator:UIActivityIndicatorView!
    @IBOutlet var dataCountLabel:UILabel!
    @IBOutlet var timeLabel:UILabel!
    
    let healthStore:HKHealthStore = HKHealthStore()
    let heartRate = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
    let activeCalories = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)
    var startDate:NSDate!
    var endDate:NSDate!
    let intervalCompoents = NSDateComponents()
    var maxHeartRate:Double = 200

    override func viewDidLoad() {
        super.viewDidLoad()
        self.startDate = NSDate()
        self.setupDay()
        self.applyInterval()
        self.requestFitAccess()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Actions
    
    @IBAction func didChangeDurationSegment() {
        self.startDate = NSDate()
        if durationSegment.selectedSegmentIndex == 0 {
            self.setupDay()
        } else if durationSegment.selectedSegmentIndex == 1 {
            self.setupMonth()
        } else if durationSegment.selectedSegmentIndex == 2 {
            self.setupYear()
        }
        self.queryData(heartRate)
    }
    
    @IBAction func didChangeDurationValue(stepper:UIStepper) {
        let value = Int(durationStepper.value)
        durationLabel.text = "\(value)"
        self.didChangeDurationSegment()
    }

    @IBAction func didChangeIntervalSegment() {
        if intervalSegment.selectedSegmentIndex == 0 {
            intervalStepper.value = 30
        } else if intervalSegment.selectedSegmentIndex == 1 {
            intervalStepper.value = 1
        } else if intervalSegment.selectedSegmentIndex == 2 {
            intervalStepper.value = 1
        }
        self.applyInterval()
        self.queryData(heartRate)
    }
    
    @IBAction func didChangeIntervalValue(stepper:UIStepper) {
        self.applyInterval()
        self.queryData(heartRate)
    }
    
    private func applyInterval() {
        let value = Int(intervalStepper.value)
        intervalLabel.text = "\(value)"
        intervalCompoents.minute = (intervalSegment.selectedSegmentIndex == 0) ? value : 0
        intervalCompoents.hour = (intervalSegment.selectedSegmentIndex == 1) ? value : 0
        intervalCompoents.day = (intervalSegment.selectedSegmentIndex == 2) ? value : 0
    }
    
    @IBAction func previous() {
        let cal: NSCalendar = NSCalendar.currentCalendar()
        let calUnit:NSCalendarUnit = NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitDay
        var dayComps: NSDateComponents = cal.components(calUnit, fromDate: startDate)
        if durationSegment.selectedSegmentIndex == 0 {
            dayComps.day -= 1
            self.startDate = cal.dateFromComponents(dayComps)
            self.setupDay()
        } else if durationSegment.selectedSegmentIndex == 1 {
            dayComps.month -= 1
            self.startDate = cal.dateFromComponents(dayComps)
            self.setupMonth()
        } else if durationSegment.selectedSegmentIndex == 2 {
            dayComps.year -= 1
            self.startDate = cal.dateFromComponents(dayComps)
            self.setupYear()
        }
        self.queryData(heartRate)
    }
    
    @IBAction func next() {
        let cal: NSCalendar = NSCalendar.currentCalendar()
        let calUnit:NSCalendarUnit = NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitDay
        var dayComps: NSDateComponents = cal.components(calUnit, fromDate: startDate)
        if durationSegment.selectedSegmentIndex == 0 {
            dayComps.day += 1
            self.startDate = cal.dateFromComponents(dayComps)
            self.setupDay()
        } else if durationSegment.selectedSegmentIndex == 1 {
            dayComps.month += 1
            self.startDate = cal.dateFromComponents(dayComps)
            self.setupMonth()
        } else if durationSegment.selectedSegmentIndex == 2 {
            dayComps.year += 1
            self.startDate = cal.dateFromComponents(dayComps)
            self.setupYear()
        }
        self.queryData(heartRate)
    }

    private func setupDay() {
        let cal: NSCalendar = NSCalendar.currentCalendar()
        let calUnit:NSCalendarUnit = NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitDay
        var dayComps: NSDateComponents = cal.components(calUnit, fromDate: startDate)
        self.startDate = cal.dateFromComponents(dayComps)
        dayComps.day += Int(durationStepper.value) - 1
        dayComps.hour = 23
        dayComps.minute = 59
        dayComps.second = 59
        self.endDate = cal.dateFromComponents(dayComps)
    }
    
    private func setupMonth() {
        let cal: NSCalendar = NSCalendar.currentCalendar()
        let calUnit:NSCalendarUnit = NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitMonth
        var dayComps: NSDateComponents = cal.components(calUnit, fromDate: startDate)
        self.startDate = cal.dateFromComponents(dayComps)
        dayComps.month += Int(durationStepper.value)
        dayComps.second -= 1
        self.endDate = cal.dateFromComponents(dayComps)
    }
    
    private func setupYear() {
        let cal: NSCalendar = NSCalendar.currentCalendar()
        let calUnit:NSCalendarUnit = NSCalendarUnit.CalendarUnitYear
        var dayComps: NSDateComponents = cal.components(calUnit, fromDate: startDate)
        self.startDate = cal.dateFromComponents(dayComps)
        dayComps.year += Int(durationStepper.value)
        dayComps.second -= 1
        self.endDate = cal.dateFromComponents(dayComps)
    }

    private func requestFitAccess() {
        if (!HKHealthStore.isHealthDataAvailable()) {
            return;
        }
        let readTypes:Set<NSObject> = Set([heartRate,activeCalories])
        healthStore.requestAuthorizationToShareTypes(Set(), readTypes: readTypes) { (success, error) -> Void in
            if success {
                self.queryData(self.heartRate)
            } else {
                println("HealthKitで読み込み許可されていません")
            }
        }
    }
    
    //MARK: Query
    
    private func queryData(type:HKQuantityType) {
        if startDate == nil || endDate == nil { return }
        self.activityIndicator.startAnimating()
        let start = NSDate().timeIntervalSince1970
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        formatter.timeStyle = NSDateFormatterStyle.ShortStyle
        self.dateLabel.text = "\(formatter.stringFromDate(startDate)) - \(formatter.stringFromDate(endDate))"
        let predicate:NSPredicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: HKQueryOptions.StrictStartDate)
        let sortDescriptor:NSSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        if intervalStepper.value > 0 {
            var options: HKStatisticsOptions = (HKStatisticsOptions.DiscreteAverage | HKStatisticsOptions.DiscreteMin | HKStatisticsOptions.DiscreteMax)
            let collectionQuery:HKStatisticsCollectionQuery = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: predicate, options: options, anchorDate:self.anchorDate(), intervalComponents: intervalCompoents)
            collectionQuery.initialResultsHandler = {(collectionQuery:HKStatisticsCollectionQuery!, collection:HKStatisticsCollection!,error:NSError!) -> Void in
                self.graphView.applyPathForAverageDatas(collection, startDate: self.startDate, endDate: self.endDate)
                let end = NSDate().timeIntervalSince1970
                dispatch_async(dispatch_get_main_queue()) {
                    self.dataCountLabel.text = "\(collection.statistics().count)"
                    self.timeLabel.text = "\(end - start)sec"
                    self.graphView.updatePath()
                    self.activityIndicator.stopAnimating()
                }
            }
            self.healthStore.executeQuery(collectionQuery)
        } else {
            let query:HKSampleQuery = HKSampleQuery(sampleType: type, predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor]) { (query, results, error) -> Void in

                self.graphView.applyPathForAllDatas(results as! [HKQuantitySample], startDate: self.startDate, endDate: self.endDate)
                let end = NSDate().timeIntervalSince1970
                dispatch_async(dispatch_get_main_queue()) {
                    self.dataCountLabel.text = "\(results.count)"
                    self.timeLabel.text = "\(end - start)sec"
                    self.graphView.updatePath()
                    self.activityIndicator.stopAnimating()
                }
            }
            self.healthStore.executeQuery(query)
        }
    }

    private func anchorDate() -> NSDate {
        let cal: NSCalendar = NSCalendar.currentCalendar()
        let calUnit:NSCalendarUnit = NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitMonth
        var dayComps: NSDateComponents = cal.components(calUnit, fromDate: NSDate())
        return cal.dateFromComponents(dayComps)!
    }
    
    private func queryMax() {
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: HKQueryOptions.StrictStartDate)
        let statsOptions: HKStatisticsOptions = HKStatisticsOptions.DiscreteMax
        let statsQuery = HKStatisticsQuery(quantityType: heartRate, quantitySamplePredicate: predicate, options: statsOptions, completionHandler: {
            (query: HKStatisticsQuery!, result: HKStatistics!, error: NSError!) in
            
            if result != nil {
                let heartRateUnit: HKUnit = HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit())
                var value:Double = result.maximumQuantity().doubleValueForUnit(heartRateUnit)
                self.maxHeartRate = value
            }
            
        })
        self.healthStore.executeQuery(statsQuery)
    }

}

