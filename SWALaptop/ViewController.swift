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
    @IBOutlet weak var userLabel: UILabel!
    
    @IBOutlet weak var minRSSILabel: UILabel!
    @IBOutlet weak var curRSSILabel: UILabel!
    @IBOutlet weak var maxRSSILabel: UILabel!
    @IBOutlet weak var rssiProgressView: UIProgressView!

    @IBOutlet weak var lockLabel: UILabel!
    @IBOutlet weak var terminalLabel: UILabel!
    
    fileprivate var blurView: UIVisualEffectView!
    
    fileprivate let lockedColor = UIColor.red
    fileprivate let unlockedColor = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)

    fileprivate let liveTerminalColor =  UIColor.blue //  UIColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1.0)
    
    fileprivate let stateMachine = StateMachine()
    fileprivate var bluetoothManager: BluetoothManager!
    
    fileprivate var currentUser: Int?
    
    fileprivate var isBlurred = false
    fileprivate var isBlacked = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        configureUI()
        
        stateMachine.delegate = self
        
        bluetoothManager = BluetoothManager()
        bluetoothManager.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func configureUI() {
        userLabel.text = "Logged out"

        minRSSILabel.text = "\(stateMachine.minRSSI)"
        maxRSSILabel.text = "\(stateMachine.maxRSSI)"
        
        curRSSILabel.text = ""
        
        rssiProgressView.setProgress(0.0, animated: true)
        
        terminalLabel.textColor = .black
        
        blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurView.frame = terminalLabel.bounds
        blurView.alpha = 0.0
        terminalLabel.addSubview(blurView)
    }
    
    @IBAction func tappedBadge(_ sender: Any) {
        let index = userSegmentedControl.selectedSegmentIndex
        let name = userSegmentedControl.titleForSegment(at: index)!
        log("tappedBadge \(index) \(name)")
        if stateMachine.state == .idle {
            stateMachine.startSearch()
            bluetoothManager.connect(index: index)
        }
    }
    
    fileprivate func lock() {
        UIView.animate(withDuration: 1.0) {
            self.lockLabel.text = "Locked"
            self.lockLabel.backgroundColor = self.lockedColor
        }
    }
    
    fileprivate func unlock() {
        UIView.animate(withDuration: 1.0) {
            self.lockLabel.text = "Unlocked"
            self.lockLabel.backgroundColor = self.unlockedColor
        }
    }
    
    fileprivate func blur() {
        log("blur")
        UIView.animate(withDuration: 2.0) {
            self.blurView.alpha = 1.0
            self.isBlurred = true
        }
    }
    
    fileprivate func unblur() {
        log("unblur")
        UIView.animate(withDuration: 2.0) {
            self.blurView.alpha = 0.0
            self.isBlurred = false
        }
    }
    
    fileprivate func fadeIn() {
        log("fadeIn")
        UIView.animate(withDuration: 2.0) {
            self.terminalLabel.textColor = .white
            self.terminalLabel.backgroundColor = self.liveTerminalColor
            self.isBlacked = false
        }
    }
    
    fileprivate func fadeOut() {
        log("fadeOut")
        UIView.animate(withDuration: 2.0) {
            self.terminalLabel.textColor = .black
            self.terminalLabel.backgroundColor = .black
            self.isBlacked = true
        }
    }
    
}

extension ViewController: BluetoothManagerDelegate {
    
    func didDisconnect() {
        stateMachine.idle()
}
    
    func didUpdateRSSI(_ rssi: Int) {
        curRSSILabel.text = "\(rssi)"
        
        let progress = Float(rssi - stateMachine.minRSSI) / Float(stateMachine.maxRSSI - stateMachine.minRSSI)
        rssiProgressView.setProgress(progress, animated: true)
        rssiProgressView.progressTintColor = stateMachine.isAboveThreshold(rssi: rssi) ? unlockedColor : lockedColor
        
        if stateMachine.state == .searching {
            userLabel.text = "Come closer!"
        }
        
        stateMachine.updateRSSI(rssi)
    }
    
}

extension ViewController: StateMachineDelegate {

    func didUpdateState(_ state: State) {
        log("state updated to \(state)")
        switch state {
        case .idle:
            userLabel.text = "Logged out"
            curRSSILabel.text = ""
            rssiProgressView.setProgress(0.0, animated: true)
            bluetoothManager.disconnect()
            if isBlurred {
                unblur()
            }
            fadeOut()
            lock()
        case .searching:
            userLabel.text = "Searching..."
        case .unlocked:
            let index = userSegmentedControl.selectedSegmentIndex
            let name = userSegmentedControl.titleForSegment(at: index)!
            userLabel.text = name

            if isBlurred {
                unblur()
            } else if isBlacked {
                fadeIn()
            }
            unlock()
        case .lockedShort:
            blur()
            lock()
        case .lockedLong:
            unblur()
            fadeOut()
        }
    }
    
}
