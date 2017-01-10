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
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var minRSSILabel: UILabel!
    @IBOutlet weak var curRSSILabel: UILabel!
    @IBOutlet weak var maxRSSILabel: UILabel!
    
    @IBOutlet weak var rssiProgressView: UIProgressView!
    @IBOutlet weak var lockLabel: UILabel!
    
    fileprivate let lockedColor = UIColor.red
    fileprivate let unlockedColor = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
    
    fileprivate let user = User()
    fileprivate var bluetoothManager: BluetoothManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        configureRSSIProgressView()
        
        user.delegate = self
        
        bluetoothManager = BluetoothManager()
        bluetoothManager.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func configureRSSIProgressView() {
        minRSSILabel.text = "\(user.minRSSI)"
        maxRSSILabel.text = "\(user.maxRSSI)"
        
        curRSSILabel.text = ""
        
        rssiProgressView.setProgress(0.0, animated: true)
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        let index = userSegmentedControl.selectedSegmentIndex
        let name = userSegmentedControl.titleForSegment(at: index)!
        log("index \(index) \(name)")
        if user.loginState == .loggedOut {
            user.login()
            bluetoothManager.connect(index: index)
        } else if user.loginState == .loggedIn {
            user.logout()
        }
    }
    
}

extension ViewController: BluetoothManagerDelegate {
    
    func didDisconnect() {
        curRSSILabel.text = ""
        rssiProgressView.setProgress(0.0, animated: true)

        user.logout()
}
    
    func didUpdateRSSI(_ rssi: Int) {
        curRSSILabel.text = "\(rssi)"
        
        let progress = Float(rssi - user.minRSSI) / Float(user.maxRSSI - user.minRSSI)
        rssiProgressView.setProgress(progress, animated: true)
        rssiProgressView.progressTintColor = user.isAboveThreshold(rssi: rssi) ? unlockedColor : lockedColor
        
        user.updateRSSI(rssi)
    }
    
}

extension ViewController: UserStateDelegate {

    func didUpdateLoginState(_ state: UserLoginState) {
        log("user login state updated to \(state)")
        switch state {
        case .loggedOut:
            loginButton.setTitle("Login", for: .normal)
            bluetoothManager.disconnect()
        case .searching:
            loginButton.setTitle("Searching...", for: .normal)
        case .loggedIn:
            loginButton.setTitle("Logout", for: .normal)
        }
    }
    
    func didUpdateLockState(_ state: UserLockState) {
        log("user lock state updated to \(state)")
        switch state {
        case .locked:
            lockLabel.text = "Locked"
            lockLabel.backgroundColor = lockedColor
        case .unlocked:
            lockLabel.text = "Unlocked"
            lockLabel.backgroundColor = unlockedColor
        }
    }
    
}
