//
//  LabeledImage.swift
//  Convolution
//
//  Created by Kevin Coble on 3/6/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Cocoa
import AIToolbox

open class LabeledImage
{
    let label : Int
    let scaledBitmap : NSBitmapImageRep?
    var image: NSImage?
    let imageSize : Int
    
    init(initLabel: Int, initImage: NSImage)
    {
        //  Save the labels
        label = initLabel
        
        //  Get the multiple of 2 that fits the image coming in
        var fitSize = 4
        let largerDimension = Int(max(initImage.size.width, initImage.size.height))
        for power in 2..<8 {
            if (1 << power) >= largerDimension {
                fitSize = (1 << power)
                break
            }
        }
        imageSize = fitSize
        
        //  Scale to the appropriate size
        scaledBitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: imageSize, pixelsHigh: imageSize, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSCalibratedRGBColorSpace, bytesPerRow: imageSize * 4, bitsPerPixel: 32)
        if let representation = scaledBitmap {
            if let context = NSGraphicsContext(bitmapImageRep: representation) {
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.setCurrent(context)
                context.imageInterpolation = .high
                let scale = CGFloat(imageSize)
                initImage.draw(in: CGRect(x: 0, y: 0, width: scale, height: scale), from: CGRect(origin: NSZeroPoint, size: initImage.size), operation: .copy, fraction: 1.0 )
                context.flushGraphics()
                NSGraphicsContext.restoreGraphicsState()
                image = NSImage(size: NSSize(width: imageSize, height: imageSize))
                image!.addRepresentation(representation)
            }
        }
    }
}

public enum LabeledImageComponent : Int {
    case redHorizontalLine = 0
    case greenHorizontalLine
    case blueHorizontalLine
    case redVerticalLine
    case greenVerticalLine
    case blueVerticalLine
    case redCircle
    case greenCircle
    case blueCircle
}

open class LabeledImageGenerator : MLPersistence
{
    var includeComponents : [LabeledImageComponent]
    var noiseComponents : [LabeledImageComponent]
    var numNoiseItems : Int
    
    public init(initIncludes: [LabeledImageComponent], initNoise: [LabeledImageComponent], initNumNoiseItems: Int)
    {
        includeComponents = initIncludes
        noiseComponents = initNoise
        numNoiseItems = initNumNoiseItems
    }
    
    public required init?(fromDictionary: [String: AnyObject])
    {
        //  Get the number of noise items
        let numNoiseValue = fromDictionary["numNoise"] as? NSInteger
        if numNoiseValue == nil { return nil }
        numNoiseItems = numNoiseValue!
        
        //  Get the include items
        includeComponents = []
        noiseComponents = []
        let tempIncludeArray = getIntArray(fromDictionary, identifier: "include")
        if (tempIncludeArray == nil) { return nil }
        for includeItem in tempIncludeArray! {
            let include = LabeledImageComponent(rawValue: includeItem)
            if (include == nil) { return nil }
            includeComponents.append(include!)
        }
        
        //  Get the noise items
        let tempNoiseArray = getIntArray(fromDictionary, identifier: "noise")
        if (tempNoiseArray == nil) { return nil }
        for noiseItem in tempNoiseArray! {
            let noise = LabeledImageComponent(rawValue: noiseItem)
            if (noise == nil) { return nil }
            noiseComponents.append(noise!)
        }
    }
    
    open func getImage(_ withLabel : Int? = nil) ->LabeledImage
    {
        //  Get the label we are going to return
        let classIndex = Int(arc4random_uniform(UInt32(includeComponents.count)))

        //  Create a blank image to draw onto
        let image = NSImage(size: NSSize(width: 256, height: 256))
        image.lockFocus()
        
        //  Clear to a white color
        NSColor.white.set()
        NSRectFill(NSRect(x: 0, y: 0, width: 256, height: 256))
        
        //  Get a position/size number for each item
        let diff = 1.0 * CGFloat(0.1)
        var itemParameter: [(parameter: CGFloat, order: UInt32)] = []
        for index in 0..<8 {       //  Max of 7 noise items
            itemParameter.append((parameter: diff * CGFloat(index+1), order: arc4random()))
        }
        itemParameter.sort(by: {$0.order < $1.order})
        
        //  Draw each item into the image
        for index in 0..<(numNoiseItems+1) {
            //  Get the item to be drawn
            var itemToDraw : LabeledImageComponent
            if (index == 0) {
                itemToDraw = includeComponents[classIndex]
            }
            else {
                let noiseIndex = Int(arc4random_uniform(UInt32(noiseComponents.count)))
                itemToDraw = noiseComponents[noiseIndex]
            }
            
            //  Get the color for the item
            switch (itemToDraw) {
            case .redHorizontalLine, .redVerticalLine, .redCircle:
                NSColor.red.set()
            case .greenHorizontalLine, .greenVerticalLine, .greenCircle:
                NSColor.green.set()
            case .blueHorizontalLine, .blueVerticalLine, .blueCircle:
                NSColor.blue.set()
            }
            
            let position = itemParameter[index].parameter * 256.0
            let path = NSBezierPath()
            path.lineWidth = 5.0
            switch (itemToDraw) {
            case .redHorizontalLine, .greenHorizontalLine, .blueHorizontalLine:
                path.move(to: CGPoint(x: 10.0, y: position))
                path.line(to: CGPoint(x: 246.0, y: position))
            case .redVerticalLine, .greenVerticalLine, .blueVerticalLine:
                path.move(to: CGPoint(x: position, y: 10.0))
                path.line(to: CGPoint(x: position, y: 246.0))
            case .redCircle, .greenCircle, .blueCircle:
                let size = CGFloat(arc4random_uniform(UInt32(256 - position)))
                let rect = CGRect(x: position, y: position, width: size, height: size)
                path.appendOval(in: rect)
            }
            path.stroke()
        }
        
        //  Stop the drawing into the image
        image.unlockFocus()
        
        //  Create the labeled image and return it
        return LabeledImage(initLabel: classIndex, initImage: image)
    }
    
    public func getPersistenceDictionary() -> [String: AnyObject]
    {
        var resultDictionary : [String: AnyObject] = [:]
        
        //  Set the number of noise items
        resultDictionary["numNoise"] = numNoiseItems as AnyObject?
        
        //  Set the include components
        var includeArray : [Int] = []
        for includeItem in includeComponents {
            includeArray.append(includeItem.rawValue)
        }
        resultDictionary["include"] = includeArray as AnyObject?
        
        //  Set the noise components
        var noiseArray : [Int] = []
        for noiseItem in noiseComponents {
            noiseArray.append(noiseItem.rawValue)
        }
        resultDictionary["noise"] = noiseArray as AnyObject?
        
        return resultDictionary
    }
}
