//
//  BluetoothManager.swift
//  SWALaptop
//
//  Created by Jay Tucker on 1/9/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

// import Foundation

import CoreBluetooth

protocol BluetoothManagerDelegate: class {
    func didDisconnect()
    func didUpdateRSSI(_ rssi: Int)
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
    fileprivate var rssiTimer: Timer?
    fileprivate var isBusy = false
    
    weak var delegate: BluetoothManagerDelegate?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate:self, queue:nil)
    }
    
    func connect(index: Int) {
        log("connect \(index)")
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
    
    func disconnect() {
        log("disconnect")
        guard peripheral != nil else { return }
        centralManager.cancelPeripheralConnection(peripheral)
        peripheral = nil
        characteristic = nil
        isBusy = false
    }

    fileprivate func startScanForPeripheral(serviceUuid: CBUUID) {
        log("startScanForPeripheral")
        centralManager.stopScan()
        scanTimer = Timer.scheduledTimer(withTimeInterval: timeoutInSecs, repeats: false) {
            _ in
            log("scan timed out")
            self.centralManager.stopScan()
            self.isBusy = false
        }
        centralManager.scanForPeripherals(withServices: [serviceUuid], options: nil)
    }
    
    fileprivate func startReadingRSSI() {
        rssiTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            _ in
            self.peripheral.readRSSI()
        }
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
        rssiTimer?.invalidate()
        rssiTimer = nil
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
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        log("peripheral didModifyServices")
        if invalidatedServices.count > 0 {
            rssiTimer?.invalidate()
            rssiTimer = nil
            delegate?.didDisconnect()
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
            delegate?.didUpdateRSSI(Int(truncating: RSSI))
        }
    }
    
}
