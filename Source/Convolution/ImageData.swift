//
//  ImageData.swift
//  Convolution
//
//  Created by Kevin Coble on 2/15/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Cocoa

public struct ImageDataSource : OptionSetType
{
    public let rawValue : Int
    public init(rawValue:Int){ self.rawValue = rawValue}
    
    static let None = ImageDataSource(rawValue: 0)
    static let Red  = ImageDataSource(rawValue: 1 << 0)
    static let Green = ImageDataSource(rawValue: 1 << 1)
    static let Blue  = ImageDataSource(rawValue: 1 << 2)
    static let Average  = ImageDataSource(rawValue: 1 << 3)
    static let Minimum  = ImageDataSource(rawValue: 1 << 4)
    static let Maximum  = ImageDataSource(rawValue: 1 << 5)
    
    //  This function assumes a single flag set
    public func getString() ->String
    {
        if self.contains(.Red) { return "Red" }
        if self.contains(.Green) { return "Green" }
        if self.contains(.Blue) { return "Blue" }
        if self.contains(.Average) { return "Average" }
        if self.contains(.Minimum) { return "Minimum" }
        if self.contains(.Maximum) { return "Maximum" }
        return "None"
    }
    
    //  This function assumes a single flag set
    public func getShortString() ->String
    {
        if self.contains(.Red) { return "R" }
        if self.contains(.Green) { return "G" }
        if self.contains(.Blue) { return "B" }
        if self.contains(.Average) { return "A" }
        if self.contains(.Minimum) { return "<" }
        if self.contains(.Maximum) { return ">" }
        return " "
    }
}

public class ImageData
{
    let originalImage : NSImage
    var currentSize : Int
    var neededData: ImageDataSource
    
    public var scaledBitmap: NSBitmapImageRep?
    
    //  Data arrays
    var redData : [Float]?
    var greenData : [Float]?
    var blueData : [Float]?
    var averageData : [Float]?
    var minimumData : [Float]?
    var maximumData : [Float]?
    
    public init(image: NSImage, size: Int, sources: ImageDataSource)
    {
        originalImage = image
        currentSize = size
        neededData = sources
        
        setImageSize(size)  //  This will get the initial data
    }
    
    public func setImageSize(size: Int)
    {
        //  Get the bitmap representation
        currentSize = size
        scaledBitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: currentSize, pixelsHigh: currentSize, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSCalibratedRGBColorSpace, bytesPerRow: currentSize * 4, bitsPerPixel: 32)
        if let representation = scaledBitmap {
            if let context = NSGraphicsContext(bitmapImageRep: representation) {
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.setCurrentContext(context)
                context.imageInterpolation = .High
                let scale = CGFloat(currentSize)
                originalImage.drawInRect(CGRectMake(0, 0, scale, scale), fromRect: CGRect(origin: NSZeroPoint, size: originalImage.size), operation: .CompositeCopy, fraction: 1.0 )
                context.flushGraphics()
                NSGraphicsContext.restoreGraphicsState()
            }
        }
        
        //  Get the data from the bitmap
        getData()
    }
    
    public func setRequiredSources(sources: ImageDataSource)
    {
        neededData = sources
        getData()
    }
    
    func getScaledImage() -> NSImage?
    {
        if let representation = scaledBitmap {
            let scaledImage = NSImage(size: CGSize(width: currentSize, height:currentSize))
            scaledImage.addRepresentation(representation)
            return scaledImage
        }
        return nil
    }
    
    func getData()
    {
        //  Start with empty arrays
        redData = neededData.contains(.Red) ? [Float](count: currentSize * currentSize, repeatedValue: 0.0) : nil
        greenData = neededData.contains(.Green) ? [Float](count: currentSize * currentSize, repeatedValue: 0.0) : nil
        blueData = neededData.contains(.Blue) ? [Float](count: currentSize * currentSize, repeatedValue: 0.0) : nil
        averageData = neededData.contains(.Average) ? [Float](count: currentSize * currentSize, repeatedValue: 0.0) : nil
        minimumData = neededData.contains(.Minimum) ? [Float](count: currentSize * currentSize, repeatedValue: 0.0) : nil
        maximumData = neededData.contains(.Maximum) ? [Float](count: currentSize * currentSize, repeatedValue: 0.0) : nil
        
        //  Get the data from the bitmap
        if let representation = scaledBitmap {
            //  Get pointers to each plane of data
            var redPtr = representation.bitmapData
            var greenPtr = redPtr + 1
            var bluePtr = greenPtr + 1
            
            let inverse255 : Float = 1.0 / 255.0
            for pixel in 0..<(currentSize * currentSize) {
                let redValue = Float(redPtr.memory) * inverse255
                let greenValue = Float(greenPtr.memory) * inverse255
                let blueValue = Float(bluePtr.memory) * inverse255
                
                if neededData.contains(.Red) { redData![pixel] = redValue }
                if neededData.contains(.Green) { greenData![pixel] = greenValue }
                if neededData.contains(.Blue) { blueData![pixel] = blueValue }
                if neededData.contains(.Average) { averageData![pixel] = (redValue + greenValue + blueValue) / 3.0 }
                if neededData.contains(.Minimum) { minimumData![pixel] = min(redValue, greenValue, blueValue) }
                if neededData.contains(.Maximum) { maximumData![pixel] = max(redValue, greenValue, blueValue) }
                
                //  Next pixel
                redPtr += 4
                greenPtr += 4
                bluePtr += 4
            }
        }
    }
    
    var size : Int { get { return currentSize } }
    
    public func sourceData(source: ImageDataSource) -> [Float]?
    {
        if source.contains(.Red) { return redData }
        if source.contains(.Green) { return greenData }
        if source.contains(.Blue) { return blueData }
        if source.contains(.Average) { return averageData }
        if source.contains(.Minimum) { return minimumData }
        if source.contains(.Maximum) { return maximumData }
        return nil
    }
    
    public func getDataSourceImage(source: ImageDataSource) ->NSImage?
    {
        if let sourceArray = sourceData(source) {
            
            //  Get a bitmap representation
            if let representation = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: currentSize, pixelsHigh: currentSize, bitsPerSample: 8, samplesPerPixel: 1, hasAlpha: false, isPlanar: false, colorSpaceName: NSCalibratedWhiteColorSpace, bytesPerRow: 0, bitsPerPixel: 8) {
                let rowBytes = representation.bytesPerRow
                let pixels = representation.bitmapData
                var index = 0
                for y in 0..<currentSize {
                    for x in 0..<currentSize {
                        pixels[y * rowBytes + x] = UInt8(sourceArray[index] * 255.0)
                        index += 1
                    }
                }
                
                let image = NSImage(size: NSSize(width: currentSize, height: currentSize))
                image.addRepresentation(representation)
                return image
            }
        }
        return nil
    }
}