//
//  GCDBlackBox.swift
//  VirtualTourist
//
//  Created by Adam Zarn on 8/24/16.
//  Copyright © 2016 Adam Zarn. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(updates: () -> Void) {
    dispatch_async(dispatch_get_main_queue()) {
        updates()
    }
}
