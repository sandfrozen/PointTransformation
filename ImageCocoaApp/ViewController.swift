//
//  ViewController.swift
//  ImageCocoaApp
//
//  Created by Tomek Buslowski on 21.10.2017.
//  Copyright © 2017 Tomek Buslowski. All rights reserved.
//

import Cocoa
import Quartz

class ViewController: NSViewController {

    @IBOutlet weak var imagePathLabel: NSTextField!
    @IBOutlet weak var imageView: IKImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    

    @IBAction func openImageAction(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a image";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["png", "jpg"];
        
        if dialog.runModal() == NSApplication.ModalResponse.OK {
            if let result = dialog.url {
                self.imagePathLabel.stringValue = result.lastPathComponent
                self.imageView.setImageWith(result)
                
                let nsData = NSData(contentsOf: result)
                let bitMap = NSBitmapImageRep(data: nsData! as Data)
                print(bitMap?.size.width)
                print(bitMap?.size.height)
                print(bitMap?.setColor(NSColor.blue, atX: 1, y: 1))
                print(bitMap?.colorAt(x: 1, y: 1))

                
            }
        } else {
            return
        }
    }
    
    
}

