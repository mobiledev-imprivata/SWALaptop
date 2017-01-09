//
//  Logger.swift
//  SWALaptop
//
//  Created by Jay Tucker on 1/9/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

import Foundation

var dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "HH:mm:ss.SSS"
    return df
}()

func log(_ message: String) {
    let timestamp = dateFormatter.string(from: Date())
    print("[\(timestamp)] \(message)")
}
