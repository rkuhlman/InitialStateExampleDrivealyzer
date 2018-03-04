//
//  ViewController.swift
//  InitialStateExample
//
//  Created by Rick Kuhlman on 3/3/18.
//  Copyright © 2018 Rick Kuhlman. All rights reserved.
//

import UIKit
import CoreMotion
import Foundation
import CoreLocation

class ViewController: UIViewController,CLLocationManagerDelegate {
  @IBOutlet var rollLabel: UILabel!
  @IBOutlet var pitchLabel: UILabel!
  @IBOutlet var yawLabel: UILabel!
  var dataBuffer = [DataPoint]()
  let manager = CMMotionManager()
  let session = URLSession(configuration: .default)
  let baseURL = "https://groker.initialstate.com/api/events"
  let encoder = JSONEncoder()
  let locationManager = CLLocationManager()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  @IBAction func start(_ sender: Any) {
    UIApplication.shared.isIdleTimerDisabled = true
    startMotionDetection()
    locationManager.requestAlwaysAuthorization()
    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyBest
      locationManager.startUpdatingLocation()
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let location = locations.first
    let coord = "\(location?.coordinate.latitude ?? 0),\(location?.coordinate.longitude ?? 0)"
    print (coord)
    let epoch = NSDate().timeIntervalSince1970
    dataBuffer.append(DataPoint(key: "map", value: coord, epoch: epoch))
    yawLabel.text = "Long/Lat: " + coord
  }
  
  func startMotionDetection() {
    manager.deviceMotionUpdateInterval = 0.05
    if manager.isDeviceMotionAvailable {
      manager.startDeviceMotionUpdates(to: OperationQueue.main) { (data: CMDeviceMotion?, error: Error?) in
        guard let data = data else { return }
        self.handleDeviceMotionUpdate(deviceMotion:data)
      }
    }
  }
  
  func degrees(radians:Double) -> Double {
    return 180 / Double.pi * radians
  }
  
  func handleDeviceMotionUpdate(deviceMotion:CMDeviceMotion) {
    let attitude = deviceMotion.attitude
    let roll = degrees(radians: attitude.roll)
    let pitch = degrees(radians: attitude.pitch)
    let yaw = degrees(radians: attitude.yaw)
    let rollString = String(format: "%f", roll)
    let pitchString = String(format: "%f", pitch)
    let yawString = String(format: "%f", yaw)
    let acceleration = deviceMotion.userAcceleration
    let accelXString = String(format: "%f", acceleration.x)
    let accelYString = String(format: "%f", acceleration.y)
    let accelZString = String(format: "%f", acceleration.z)
    rollLabel.text = "Accel: " + accelXString + ", " + accelYString + ", " + accelZString
    pitchLabel.text = "Attitude: " + rollString + ", " + pitchString + ", " + yawString
    let epoch = NSDate().timeIntervalSince1970
    dataBuffer.append(DataPoint(key: "roll", value: rollString, epoch: epoch))
    dataBuffer.append(DataPoint(key: "pitch", value: pitchString, epoch: epoch))
    dataBuffer.append(DataPoint(key: "yaw", value: yawString, epoch: epoch))
    dataBuffer.append(DataPoint(key: "accelX", value: accelXString, epoch: epoch))
    dataBuffer.append(DataPoint(key: "accelY", value: accelYString, epoch: epoch))
    dataBuffer.append(DataPoint(key: "accelZ", value: accelZString, epoch: epoch))
    if dataBuffer.count > 50 {
      let data = try? encoder.encode(dataBuffer)
      sendData(data:data!)
      dataBuffer.removeAll()
    }
  }
  
  func sendData(data:Data) {
    guard let url = URL(string: baseURL) else {return}
    var request = URLRequest(url:url)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = ["X-IS-AccessKey":"2RIlybTv7FA45qS2GCyJLbJu6JvVtBqB",
                                   "X-IS-BucketKey":"HRFDM6TCCQWU",
                                   "Content-Type":"application/json"]
    request.httpBody = data
    let dataTask = session.dataTask(with: request) { (data, request, error) in
      print("SENT")
    }
    dataTask.resume()
  }
}

class DataPoint:Codable{
  let key: String?
  let value: String?
  let epoch: Double?
  
  init (key:String, value:String, epoch: Double){
    self.key = key
    self.value = value
    self.epoch = epoch
  }
}


