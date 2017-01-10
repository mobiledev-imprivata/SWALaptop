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
    
    var delegate: UserStateDelegate?

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
    
    private let searchTimeout = 20.0
    private let logoutTimeout = 20.0
    
    private var searchTimer: Timer?
    private var logoutTimer: Timer?
    
    func login() {
        guard loginState == .loggedOut else { return }
        loginState = .searching
        searchTimer = Timer.scheduledTimer(withTimeInterval: searchTimeout, repeats: false) {
            _ in
            log("search timed out")
            self.stopSearchTimer()
            self.loginState = .loggedOut
        }
    }
    
    func logout() {
        guard loginState == .loggedIn else { return }
        stopLogoutTimer()
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
                stopSearchTimer()
                loginState = .loggedIn
                lockState = .unlocked
            }
        case .loggedIn:
            if isAboveThreshold(rssi: rssi) {
                if lockState == .unlocked { return }
                stopLogoutTimer()
                lockState = .unlocked
            } else {
                if lockState == .locked { return }
                lockState = .locked
                logoutTimer = Timer.scheduledTimer(withTimeInterval: logoutTimeout, repeats: false) {
                    _ in
                    log("logout timed out")
                    self.stopLogoutTimer()
                    self.loginState = .loggedOut
                }
            }
        }
    }
    
    private func stopSearchTimer() {
        log("stopSearchTimer")
        searchTimer?.invalidate()
        searchTimer = nil
    }
    
    private func stopLogoutTimer() {
        log("stopLogoutTimer")
        logoutTimer?.invalidate()
        logoutTimer = nil
    }
    
}
