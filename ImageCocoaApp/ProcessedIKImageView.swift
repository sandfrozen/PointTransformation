//
//  ProcessedIKImageView.swift
//  ImageCocoaApp
//
//  Created by Tomek Buslowski on 29.10.2017.
//  Copyright © 2017 Tomek Buslowski. All rights reserved.
//

import Cocoa
import Quartz

class ProcessedIKImageView: IKImageView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func touchesBegan(with event: NSEvent) {
        print("\(event.locationInWindow)")
    }
    
}
