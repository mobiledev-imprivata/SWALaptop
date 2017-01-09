//
//  ViewController.swift
//  SWALaptop
//
//  Created by Jay Tucker on 1/9/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    
    @IBOutlet weak var userSegmentedControl: UISegmentedControl!
    
    
    @IBOutlet weak var minRSSILabel: UILabel!
    @IBOutlet weak var curRSSILabel: UILabel!
    @IBOutlet weak var maxRSSILabel: UILabel!
    
    @IBOutlet weak var rssiProgressView: UIProgressView!
    @IBOutlet weak var lockLabel: UILabel!
    
    fileprivate let minRSSI = -80
    fileprivate let maxRSSI = -20
    
    fileprivate let lockedColor = UIColor.red
    fileprivate let unlockedColor = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
    
    
    fileprivate let thresholdRSSI = -45
    
    private var bluetoothManager: BluetoothManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        configureRSSIProgressView()
        bluetoothManager = BluetoothManager()
        bluetoothManager.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func configureRSSIProgressView() {
        minRSSILabel.text = "\(minRSSI)"
        maxRSSILabel.text = "\(maxRSSI)"

        curRSSILabel.text = ""
        
        rssiProgressView.setProgress(0.0, animated: true)
    }

    @IBAction func login(_ sender: Any) {
        let index = userSegmentedControl.selectedSegmentIndex
        log("index \(index)")
    }
    
}

extension ViewController: BluetoothManagerDelegate {

    func didUpdateRSSI(RSSI: Int) {
        log("didUpdateRSSI \(RSSI)")
        
        curRSSILabel.text = "\(RSSI)"
        
        let isAboveThreshhold = RSSI > thresholdRSSI
        let color = isAboveThreshhold ? unlockedColor : lockedColor
        
        let progress = Float(RSSI - minRSSI) / Float(maxRSSI - minRSSI)
        rssiProgressView.setProgress(progress, animated: true)
        rssiProgressView.progressTintColor = color
        
        lockLabel.backgroundColor = color
        lockLabel.text = isAboveThreshhold ? "Unlocked" : "Locked"
    }
    
}
