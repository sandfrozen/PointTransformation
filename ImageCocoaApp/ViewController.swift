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
    
    var context: CGContext!
    var pixelValues: Array<FloatColor>!
    var pixelBuffer: UnsafeMutablePointer<RGBA32>!
    var width: Int!
    var height: Int!
    
    @IBOutlet weak var rgbaControl: NSSegmentedControl!
    @IBOutlet weak var operationControl: NSSegmentedControl!
    @IBOutlet weak var valueTextFiled: NSTextField!
    @IBOutlet weak var infoTestFiled: NSTextField!
    @IBOutlet weak var brightnessValueTextFiled: NSTextField!
    
    
    var resultUrl: URL! {
        didSet {
            guard let cgImage: CGImage = ikImageView.image()?.takeUnretainedValue() else {
                print("Unable to get image from IKImageView")
                return
            }
            
            let originalBitmap = NSBitmapImageRep.init(cgImage: cgImage)
            
            let colorSpace       = CGColorSpaceCreateDeviceRGB()
            width                = cgImage.width
            height               = cgImage.height
            let bytesPerPixel    = 4
            let bitsPerComponent = 8
            let bytesPerRow      = bytesPerPixel * width
            let bitmapImfo       = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            
            guard let contextGuarded = CGContext.init(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapImfo) else {
                print("Unable to create context")
                return
            }
            
            context = contextGuarded
            
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            
            guard let buffer = context.data else {
                print("Unable to get context data")
                return
            }
            
            pixelValues = []
            pixelBuffer = buffer.bindMemory(to: RGBA32.self, capacity: width*height)
            
            for row in 0 ..< height {
                for col in 0 ..< width {
                    let offset = row * width + col
                    let actualRGB = originalBitmap.colorAt(x: col, y: row)!.cgColor.components!
                    let red =   (Float)(actualRGB[0] * 255)
                    let green = (Float)(actualRGB[1] * 255)
                    let blue =  (Float)(actualRGB[2] * 255)
                    pixelValues.insert(FloatColor(red: red, green: green, blue: blue, alpha: 255), at: offset)
                }
            }
            infoTestFiled.stringValue = "loaded"
        }
    }
    
    var operationsOnQueue: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayout() {
        self.ikImageView.zoomImageToFit(nil)
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
                self.ikImageView.setImageWith(url)
                self.ikImageView.zoomImageToFit(nil)
                resultUrl = url
            }
        } else {
            return
        }
        
        if resultUrl == nil {
            let _ = dialogInfoOK(title: "Error", text: "Problem occured while photo was reading.")
        }
    }
    
    @IBAction func resetImageAction(_ sender: Any) {
        if ikImageView.image() == nil {
            print("No loaded image to reset")
            return
        }
        self.ikImageView.setImageWith(resultUrl)
        self.ikImageView.zoomImageToFit(nil)
        
        guard let cgImage: CGImage = ikImageView.image()?.takeUnretainedValue() else {
            print("Unable to get image from IKImageView")
            return
        }
        
        let originalBitmap = NSBitmapImageRep.init(cgImage: cgImage)
        
        pixelValues = []
        
        for row in 0 ..< height {
            for col in 0 ..< width {
                let offset = row * width + col
                let actualRGB = originalBitmap.colorAt(x: col, y: row)!.cgColor.components!
                let red =   (Float)(actualRGB[0] * 255)
                let green = (Float)(actualRGB[1] * 255)
                let blue =  (Float)(actualRGB[2] * 255)
                pixelValues.insert(FloatColor(red: red, green: green, blue: blue, alpha: 255), at: offset)
            }
        }
    }
    
    @IBAction func doOperationAction(_ sender: Any) {
        operationsOnQueue += 1
        self.infoTestFiled.stringValue = "Op on queue: \(operationsOnQueue)"
        processPixels()
        operationsOnQueue -= 1
    }
    
    @IBAction func brightnessAction(_ sender: Any) {
//        guard let cgImage: CGImage = ikImageView.image()?.takeUnretainedValue() else {
//            print("Unable to get image from IKImageView")
//            return
//        }
//        let ciImage: CIImage = CIImage.init(cgImage: cgImage)
//
//        let context = CIContext(options: nil)
//        let brightnessFilter = CIFilter(name: "CIColorControls")!
//        brightnessFilter.setValue(ciImage, forKey: "inputImage")
//
//        var value = self.brightnessValueTextFiled.float()
//        if (sender as! NSButton).tag == 0 {
//            value *= -1
//        }
//
//        brightnessFilter.setValue(value, forKey: "inputBrightness")
//        let outputImage = brightnessFilter.outputImage!
//        let cgimg = context.createCGImage(outputImage, from: outputImage.extent)
//
//        ikImageView.setImage(cgimg, imageProperties: nil)
//        self.ikImageView.zoomImageToFit(nil)
    }
    
    @IBAction func testerAction(_ sender: Any) {
        //averageFilter()
    }
    
    
    
    private func averageFilter() {
        guard let cgImage: CGImage = ikImageView.image()?.takeUnretainedValue() else {
            print("Unable to get image from IKImageView")
            return
        }
        
        let originalBitmap = NSBitmapImageRep.init(cgImage: cgImage)
        
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let width            = cgImage.width
        let height           = cgImage.height
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width
        let bitmapImfo       = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        
        guard let context = CGContext.init(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapImfo) else {
            print("Unable to create context")
            return
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let buffer = context.data else {
            print("Unable to get context data")
            return
        }
        
        let pixelBuffer = buffer.bindMemory(to: RGBA32.self, capacity: width*height)
        
        for row in 1 ..< Int(height)-1 {
            for col in 1 ..< Int(width)-1 {
                var sumR:CGFloat = 0
                var sumG:CGFloat = 0
                var sumB:CGFloat = 0
                
                for r in row-1...row+1 {
                    for c in col-1...col+1 {
                        let localRGB = originalBitmap.colorAt(x: c, y: r)!.cgColor.components!
                        sumR += localRGB[0]
                        sumG += localRGB[1]
                        sumB += localRGB[2]
                    }
                }
                
                let avgR: CGFloat = sumR / 9 * 255
                let avgG: CGFloat = sumG / 9 * 255
                let avgB: CGFloat = sumB / 9 * 255
                
                let offset = row * width + col
                pixelBuffer[offset] = RGBA32(red: avgR.RGB255(), green: avgG.RGB255(), blue: avgB.RGB255(), alpha: 255)
            }
        }
        
        guard let resultCGImage = context.makeImage() else {
            print("Unable to make image from processed context")
            return
        }
        ikImageView.setImage(resultCGImage, imageProperties: nil)
        self.ikImageView.zoomImageToFit(nil)
    }
    
    private func processPixels() {
        let operation   = operationControl.selectedSegment
        let value       = self.valueTextFiled.float()
        
        let changeRed   = rgbaControl.isSelected(forSegment: 0)
        let changeGreen = rgbaControl.isSelected(forSegment: 1)
        let changeBlue  = rgbaControl.isSelected(forSegment: 2)
        
        infoTestFiled.stringValue = "\(operationControl.label(forSegment: operation)!) \(value)\(changeRed ? " R" : "")\(changeGreen ? " G" : "")\(changeBlue ? " B" : "")"
        
        for row in 0 ..< height {
            for col in 0 ..< width {
                let offset = row * width + col
                
                switch operation {
                case 0:
                    if changeRed    { pixelValues[offset].red   += value }
                    if changeGreen  { pixelValues[offset].green += value }
                    if changeBlue   { pixelValues[offset].blue  += value }
                case 1:
                    if changeRed    { pixelValues[offset].red   -= value }
                    if changeGreen  { pixelValues[offset].green -= value }
                    if changeBlue   { pixelValues[offset].blue  -= value }
                case 2:
                    if changeRed    { pixelValues[offset].red   *= value }
                    if changeGreen  { pixelValues[offset].green *= value }
                    if changeBlue   { pixelValues[offset].blue  *= value }
                case 3:
                    if changeRed    { pixelValues[offset].red   /= value }
                    if changeGreen  { pixelValues[offset].green /= value }
                    if changeBlue   { pixelValues[offset].blue  /= value }
                default:
                    break
                }
                pixelBuffer[offset] = RGBA32(red: pixelValues[offset].red.RGB255(), green: pixelValues[offset].green.RGB255(), blue: pixelValues[offset].blue.RGB255(), alpha: 255)
            }
        }
        
        guard let resultCGImage = context.makeImage() else {
            print("Unable to make image from processed context")
            return
        }
        ikImageView.setImage(resultCGImage, imageProperties: nil)
        self.ikImageView.zoomImageToFit(nil)
    }
    
    private func dialogInfoOK(title: String, text: String) -> Bool {
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
    
    func RGB255 () -> UInt8 {
        return self > 255 ? UInt8(255) : ( self < 0 ? UInt8(0) : UInt8(self))
    }
}

extension NSTextField {
    func float() -> Float {
        return Float(self.stringValue) ?? 0.0
    }
}

extension Float {
    func RGB255 () -> UInt8 {
        return self > 255 ? UInt8(255) : ( self < 0 ? UInt8(0) : UInt8(self))
    }
    
    func int() -> Int {
        return Int(self)
    }
}

struct FloatColor {
    
    var red: Float
    var green: Float
    var blue: Float
    var alpha: Float
    
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


