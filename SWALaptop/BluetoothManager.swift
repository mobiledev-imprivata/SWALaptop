//
//  BluetoothManager.swift
//  SWALaptop
//
//  Created by Jay Tucker on 1/9/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

// import Foundation

import CoreBluetooth

protocol BluetoothManagerDelegate {
    func didUpdateRSSI(RSSI: Int)
}

class BluetoothManager: NSObject {
    
    fileprivate let serviceUUID        = CBUUID(string: "1FE5D02C-78AB-414D-AD97-1A4E5297227A")
    fileprivate let characteristicUUID = CBUUID(string: "8C881368-8C34-41FD-8BCC-AD7EA408B1EE")
    
    fileprivate let timeoutInSecs = 5.0
    
    fileprivate var centralManager: CBCentralManager!
    fileprivate var peripheral: CBPeripheral!
    fileprivate var characteristic: CBCharacteristic!
    
    fileprivate var isPoweredOn = false
    fileprivate var scanTimer: Timer!
    fileprivate var isBusy = false
    
    var delegate: BluetoothManagerDelegate?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate:self, queue:nil)
    }
    
    func go() {
        log("go")
        guard isPoweredOn else {
            log("not powered on")
            return
        }
        guard !isBusy else {
            log("busy, ignoring request")
            return
        }
        isBusy = true
        startScanForPeripheral(serviceUuid: serviceUUID)
    }
    
    fileprivate func startScanForPeripheral(serviceUuid: CBUUID) {
        log("startScanForPeripheral")
        centralManager.stopScan()
        scanTimer = Timer.scheduledTimer(timeInterval: timeoutInSecs, target: self, selector: #selector(timeout), userInfo: nil, repeats: false)
        centralManager.scanForPeripherals(withServices: [serviceUuid], options: nil) // [CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(value: true)])     // nil)
    }
    
    // can't be private because called by timer
    func timeout() {
        log("timed out")
        centralManager.stopScan()
        isBusy = false
    }
    
    fileprivate func startReadingRSSI() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) {
            _ in
            let state = self.centralManager.state
            log("centralManager.state \(self.centralManagerStateToString(state: state))")
            self.peripheral.readRSSI()
        }
    }
    
    fileprivate func disconnect() {
        log("disconnect")
        centralManager.cancelPeripheralConnection(peripheral)
        peripheral = nil
        characteristic = nil
        isBusy = false
    }
    
    fileprivate func centralManagerStateToString(state: CBManagerState) -> String {
        var caseString: String!
        switch state {
        case .unknown:
            caseString = "unknown"
        case .resetting:
            caseString = "resetting"
        case .unsupported:
            caseString = "unsupported"
        case .unauthorized:
            caseString = "unauthorized"
        case .poweredOff:
            caseString = "poweredOff"
        case .poweredOn:
            caseString = "poweredOn"
        }
        return caseString
    }
    
}

extension BluetoothManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var caseString: String!
        switch central.state {
        case .unknown:
            caseString = "unknown"
        case .resetting:
            caseString = "resetting"
        case .unsupported:
            caseString = "unsupported"
        case .unauthorized:
            caseString = "unauthorized"
        case .poweredOff:
            caseString = "poweredOff"
        case .poweredOn:
            caseString = "poweredOn"
        }
        log("centralManagerDidUpdateState \(caseString!)")
        isPoweredOn = centralManager.state == .poweredOn
        go()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        log("centralManager didDiscoverPeripheral, RSSI \(RSSI)")
        scanTimer.invalidate()
        centralManager.stopScan()
        self.peripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("centralManager didConnectPeripheral")
        self.peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let message = "centralManager didDisconnectPeripheral " + (error == nil ? "ok" :  ("error " + error!.localizedDescription))
        log(message)
    }
    
}

extension BluetoothManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let message = "peripheral didDiscoverServices " + (error == nil ? "ok" :  ("error " + error!.localizedDescription))
        log(message)
        guard error == nil else { return }
        for service in peripheral.services! {
            log("service \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let message = "peripheral didDiscoverCharacteristicsFor service " + (error == nil ? "\(service.uuid) ok" :  ("error " + error!.localizedDescription))
        log(message)
        guard error == nil else { return }
        for characteristic in service.characteristics! {
            log("characteristic \(characteristic.uuid)")
            if characteristic.uuid == characteristicUUID {
                self.characteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                startReadingRSSI()
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        let message = "peripheral didReadRSSI " + (error == nil ? "\(RSSI)" :  ("error " + error!.localizedDescription))
        log(message)
        if error == nil {
            delegate?.didUpdateRSSI(RSSI: Int(RSSI))
        }
    }
    
}
