//
//  LabeledImage.swift
//  Convolution
//
//  Created by Kevin Coble on 3/6/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Cocoa


public class LabeledImage
{
    let label : Int
    let scaledBitmap : NSBitmapImageRep?
    var image: NSImage?
    let imageSize = 256
    
    init(initLabel: Int, initImage: NSImage)
    {
        //  Save the label
        label = initLabel
        
        //  Scale to the appropriate size
        scaledBitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: imageSize, pixelsHigh: imageSize, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSCalibratedRGBColorSpace, bytesPerRow: imageSize * 4, bitsPerPixel: 32)
        if let representation = scaledBitmap {
            if let context = NSGraphicsContext(bitmapImageRep: representation) {
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.setCurrentContext(context)
                context.imageInterpolation = .High
                let scale = CGFloat(imageSize)
                initImage.drawInRect(CGRectMake(0, 0, scale, scale), fromRect: CGRect(origin: NSZeroPoint, size: initImage.size), operation: .CompositeCopy, fraction: 1.0 )
                context.flushGraphics()
                NSGraphicsContext.restoreGraphicsState()
                image = NSImage(size: NSSize(width: imageSize, height: imageSize))
                image!.addRepresentation(representation)
            }
        }
    }
}

public class LabeledImageGenerator
{
    public func getImage(withLabel : Float? = nil) ->LabeledImage
    {
        //  Get the label we are going to return
        let classIndex = Int(arc4random_uniform(2))

        //  Create a blank image to draw onto
        let image = NSImage(size: NSSize(width: 256, height: 256))
        image.lockFocus()
        
        //  Clear to a white color
        NSColor.whiteColor().set()
        NSRectFill(NSRect(x: 0, y: 0, width: 256, height: 256))
        
        //  Draw a line into the image
        let position = CGFloat(arc4random_uniform(200)+28)
        NSColor.redColor().set()
        let path = NSBezierPath()
        path.lineWidth = 5.0
        if (classIndex == 0) {      //  Vertical
            path.moveToPoint(CGPoint(x: position, y: 10.0))
            path.lineToPoint(CGPoint(x: position, y: 246.0))
        }
        else {      //  Horizontal
            path.moveToPoint(CGPoint(x: 10.0, y: position))
            path.lineToPoint(CGPoint(x: 246.0, y: position))
        }
        path.stroke()
        
        //  Stop the drawing into the image
        image.unlockFocus()
        
        //  Create the labeled image and return it
        return LabeledImage(initLabel: classIndex, initImage: image)
    }
}