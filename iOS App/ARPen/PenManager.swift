//
//  ARPenManager.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import CoreBluetooth

/**
 PenManager 
 */
protocol PenManagerDelegate {
    func button(_ button: Button, pressed: Bool)
    func connect(successfully: Bool)
}

/**
 The PenManager manages the bluetooth connection to the bluetooth chip of the hardware ARPen.
 */
class PenManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private let centralManager: CBCentralManager
    private let serviceUUID = CBUUID(string: "713D0000-503E-4C75-BA94-3148F18D941E")
    private var peripheral: CBPeripheral?
    var delegate: PenManagerDelegate?
    
    
    override init() {
        centralManager = CBCentralManager()
        super.init()
        UserDefaults.standard.addObserver(self, forKeyPath: UserDefaultsKeys.arPenName.rawValue, options: NSKeyValueObservingOptions.new, context: nil)
        centralManager.delegate = self
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let peripheral = self.peripheral {
            self.centralManager.cancelPeripheralConnection(peripheral)
            self.peripheral = nil
        }
        
        if UserDefaults.standard.string(forKey: UserDefaultsKeys.arPenName.rawValue) != "" {
            self.centralManagerDidUpdateState(self.centralManager)
        }
        //do your changes with for key
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
        if peripheral.name == UserDefaults.standard.string(forKey: UserDefaultsKeys.arPenName.rawValue) {
            self.centralManager.stopScan()
            self.peripheral = peripheral
            peripheral.delegate = self
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.delegate?.connect(successfully: true)
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.delegate?.connect(successfully: false)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for service in peripheral.services! {
            for characteristic in service.characteristics! {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else {
            print("noData")
            return
        }
        
        guard let string = String(data: data, encoding: .utf8) else {
            print("Problem with data: Data is not a string: \(data)")
            return
        }
        let array = string.split(separator: ":")
        
        guard array.count == 2 else {
            print("Problem with data: string has too many elements: \(array)")
            return
        }
        
        switch String(describing: array.first!) {
        case "B1":
            self.delegate?.button(.Button1, pressed: array.last! == "DOWN")
        case "B2":
            self.delegate?.button(.Button2, pressed: array.last! == "DOWN")
        case "B3":
            self.delegate?.button(.Button3, pressed: array.last! == "DOWN")
        default:
            print("Unkown Button pressed")
        }
        
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            
            // After 3 seconds stop scanning :/
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                if self.peripheral == nil {
                    self.delegate?.connect(successfully: false)
                    self.centralManager.stopScan()
                }
            })
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        default:
            self.delegate?.connect(successfully: false)
            break
        }
    }
    
    deinit {
        if let peripheral = self.peripheral {
            self.centralManager.cancelPeripheralConnection(peripheral)
            self.centralManager.stopScan()
        }
        UserDefaults.standard.removeObserver(self, forKeyPath: UserDefaultsKeys.arPenName.rawValue)
    }

    
}
