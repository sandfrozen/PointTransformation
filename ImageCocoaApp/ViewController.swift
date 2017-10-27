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
    @IBOutlet weak var ikImageView: IKImageView!
    
    @IBOutlet weak var redCheckBox: NSButton!
    @IBOutlet weak var grnCheckBox: NSButton!
    @IBOutlet weak var bluCheckBox: NSButton!
    @IBOutlet weak var alpCheckBox: NSButton!
    
    @IBOutlet weak var operationControl: NSSegmentedControl!
    @IBOutlet weak var valueTextFiled: NSTextField!
    
    var resultUrl: URL!
    
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
            if let url = dialog.url {
                self.imagePathLabel.stringValue = url.lastPathComponent
                resultUrl = url
                self.ikImageView.setImageWith(resultUrl)
                self.ikImageView.zoomImageToFit(nil)
            }
        } else {
            return
        }
        
        if resultUrl == nil {
            let _ = dialogInfoOK(title: "Error", text: "Problem occured while photo was reading.")
        }
    }
    
    @IBAction func doOperationAction(_ sender: Any) {
        processPixels()
    }
    
    func processPixels() {
//        let ciContext = CIContext(options: nil)
//        guard let cgImage = ciContext.createCGImage(inputImage, from: inputImage.extent) else {
//            print("--- unable to get CGImage")
//            return
//        }
        
        let cgImage = ikImageView.image().takeUnretainedValue()
        
        let originalBitmap = NSBitmapImageRep.init(cgImage: cgImage)
        
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let width            = cgImage.width
        let height           = cgImage.height
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width
        let bitmapImfo       = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        
        guard let context = CGContext.init(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapImfo) else {
            print("unable to create context")
            return
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let buffer = context.data else {
            print("unable to get context data")
            return
        }
        
        let pixelBuffer = buffer.bindMemory(to: RGBA32.self, capacity: width*height)
        
        for row in 0 ..< Int(height) {
            for col in 0 ..< Int(width) {
                let offset = row * width + col
                let actualColor = originalBitmap.colorAt(x: col, y: row)
                let rgbaArray = actualColor!.cgColor.components!
                var red = ((Int)(rgbaArray[0] * 255)).RGB255()
                var green = ((Int)(rgbaArray[1] * 255) - 10).RGB255()
                var blue = ((Int)(rgbaArray[2] * 255)).RGB255()

                
                pixelBuffer[offset] = RGBA32(red: red, green: green,   blue: blue, alpha: 255)
            }
        }
        
        let resultCGImage = context.makeImage()!
        ikImageView.setImage(resultCGImage, imageProperties: nil)
        self.ikImageView.zoomImageToFit(nil)
    }
    
    func dialogInfoOK(title: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        return alert.runModal() == .alertFirstButtonReturn
    }
}


extension CGFloat {
    func int() -> Int {
        return Int(self)
    }
}

extension NSTextField {
    func int() -> Int {
        return Int(self.stringValue) ?? 0
    }
}

extension Int {
    func RGB255 () -> UInt8 {
        return self > 255 ? UInt8(255) : ( self < 0 ? UInt8(0) : UInt8(self))
    }
}


struct RGB255 {
    var value: Int {
        didSet {
            if value > 255 {
                value = 255
            } else if value < 0 {
                value = 0
            }
        }
    }
}

struct RGBA32: Equatable {
    private var color: UInt32
    
    var redComponent: UInt8 {
        return UInt8((color >> 24) & 255)
    }
    
    var greenComponent: UInt8 {
        return UInt8((color >> 16) & 255)
    }
    
    var blueComponent: UInt8 {
        return UInt8((color >> 8) & 255)
    }
    
    var alphaComponent: UInt8 {
        return UInt8((color >> 0) & 255)
    }
    
    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
    
        let r = (UInt32(red) << 24)
        let g = (UInt32(green) << 16)
        let b = (UInt32(blue) << 8)
        let a = (UInt32(alpha) << 0)
        color = r | g | b | a
    }
    
    static let red     = RGBA32(red: 255, green: 0,   blue: 0,   alpha: 255)
    static let green   = RGBA32(red: 0,   green: 255, blue: 0,   alpha: 255)
    static let blue    = RGBA32(red: 0,   green: 0,   blue: 255, alpha: 255)
    static let white   = RGBA32(red: 255, green: 255, blue: 255, alpha: 255)
    static let black   = RGBA32(red: 0,   green: 0,   blue: 0,   alpha: 255)
    static let magenta = RGBA32(red: 255, green: 0,   blue: 255, alpha: 255)
    static let yellow  = RGBA32(red: 255, green: 255, blue: 0,   alpha: 255)
    static let cyan    = RGBA32(red: 0,   green: 255, blue: 255, alpha: 255)
    
    static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    
    static func ==(lhs: RGBA32, rhs: RGBA32) -> Bool {
        return lhs.color == rhs.color
    }
}


