//
//  StateMachine.swift
//  SWALaptop
//
//  Created by Jay Tucker on 1/10/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

import Foundation

enum State {
    case idle
    case searching
    case unlocked
    case lockedShort
    case lockedLong
}

protocol StateMachineDelegate: class {
    func didUpdateState(_ state: State)
}

class StateMachine {
    
    let minRSSI       = -80
    let maxRSSI       = -20
    let thresholdRSSI = -45
    
    private let searchTimeout = 20.0
    private let unlockedToLockedShortTimeout = 5.0
    private let lockedShortToLockedLongTimeout = 15.0
    private let lockedLongToIdleTimeout = 20.0
    
    weak var delegate: StateMachineDelegate?

    private(set) var state = State.idle {
        didSet {
            log("changed from state \(oldValue) to \(state)")
            switch state {
            case .idle:
                stopTimer()
            case .searching:
                startTimer(ti: searchTimeout, to: .idle)
            case .unlocked:
                stopTimer()
            case .lockedShort:
                startTimer(ti: lockedShortToLockedLongTimeout, to: .lockedLong)
            case .lockedLong:
                startTimer(ti: lockedLongToIdleTimeout, to: .idle)
            }
            delegate?.didUpdateState(state)
        }
    }
    
    private var timer: Timer?
    
    func startSearch() {
        guard state == .idle else { return }
        state = .searching
    }
    
    func idle() {
        state = .idle
    }
    
    func isAboveThreshold(rssi: Int) -> Bool {
        return rssi >= thresholdRSSI
    }
    
    func updateRSSI(_ rssi: Int) {
        switch state {
        case .idle, .lockedLong:
            break
        case .searching:
            if isAboveThreshold(rssi: rssi) {
                stopTimer()
                state = .unlocked
            }
        case .unlocked:
            if isAboveThreshold(rssi: rssi) {
                stopTimer()
            } else {
                startTimer(ti: unlockedToLockedShortTimeout, to: .lockedShort)
            }
        case .lockedShort:
            if isAboveThreshold(rssi: rssi) {
                stopTimer()
                state = .unlocked
            }
        }
    }
    
    private func startTimer(ti: TimeInterval, to state: State) {
        guard timer == nil else { return }
        log("startTimer with interval of \(ti) from state \(self.state) to \(state)")
        timer = Timer.scheduledTimer(withTimeInterval: ti, repeats: false) {
            _ in
            log("timed out")
            self.timer = nil
            self.state = state
        }
    }
    
    private func stopTimer() {
        guard timer != nil else { return }
        log("stopTimer")
        timer?.invalidate()
        timer = nil
    }
    
}
