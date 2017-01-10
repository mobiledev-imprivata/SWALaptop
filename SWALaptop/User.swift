//
//  User.swift
//  SWALaptop
//
//  Created by Jay Tucker on 1/10/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

import Foundation

enum UserLoginState { case loggedOut, searching, loggedIn }
enum UserLockState { case locked, unlocked }

protocol UserStateDelegate {
    func didUpdateLoginState(_ state: UserLoginState)
    func didUpdateLockState(_ state: UserLockState)
}

class User {
    
    let minRSSI       = -80
    let maxRSSI       = -20
    let thresholdRSSI = -45
    
    private(set) var loginState = UserLoginState.loggedOut {
        didSet {
            delegate?.didUpdateLoginState(loginState)
        }
    }
    
    private(set) var lockState = UserLockState.locked {
        didSet {
            delegate?.didUpdateLockState(lockState)
        }
    }
    
    var delegate: UserStateDelegate?
    
    func login() {
        guard loginState == .loggedOut else { return }
        loginState = .searching
    }
    
    func logout() {
        guard loginState == .loggedIn else { return }
        loginState = .loggedOut
        lockState = .locked
    }
    
    func isAboveThreshold(rssi: Int) -> Bool {
        return rssi >= thresholdRSSI
    }
    
    func updateRSSI(_ rssi: Int) {
        switch loginState {
        case .loggedOut:
            // do nothing
            break
        case .searching:
            if isAboveThreshold(rssi: rssi) {
                loginState = .loggedIn
                lockState = .unlocked
            }
        case .loggedIn:
            if !isAboveThreshold(rssi: rssi) {
                loginState = .loggedOut
                lockState = .locked
            }
        }
    }
    
}
