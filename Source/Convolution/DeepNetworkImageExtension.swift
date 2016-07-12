//
//  DeepNetworkImageExtension.swift
//  Convolution
//
//  Created by Kevin Coble on 6/28/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Cocoa
import Accelerate

//  This extension gets an NSImage from the specified DeepNetwork sub-object

extension DeepNetwork {
    
    public func GetItemImage(layer: Int, channel: Int, operatorIndex: Int) -> NSImage?
    {
        
        //  Get the item's data and result size
        if let results = getResultOfItem(layer, channelIndex: channel, operatorIndex: operatorIndex) {
            //  Ignore if the size is not 2D
            if (results.size.numDimensions != 2) { return nil }
            if (results.values.count < results.size.dimensions[0] * results.size.dimensions[1]) { return nil }
            
            //  Get the minimum and maximum representation of the data
            var minResult : Float = 0.0
            vDSP_minv(results.values, 1, &minResult, vDSP_Length(results.values.count))
            var maxResult : Float = 0.0
            vDSP_maxv(results.values, 1, &maxResult, vDSP_Length(results.values.count))
            
            //  Get a bitmap representation
            let scaling = (maxResult != minResult) ? 255.0 / (maxResult - minResult) : 0.0
            if let representation = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: results.size.dimensions[0], pixelsHigh: results.size.dimensions[1], bitsPerSample: 8, samplesPerPixel: 1, hasAlpha: false, isPlanar: false, colorSpaceName: NSCalibratedWhiteColorSpace, bytesPerRow: 0, bitsPerPixel: 8) {
                let rowBytes = representation.bytesPerRow
                let pixels = representation.bitmapData
                var index = 0
                for y in 0..<results.size.dimensions[1] {
                    for x in 0..<results.size.dimensions[0] {
                        pixels[y * rowBytes + x] = UInt8(Int((results.values[index] - minResult) * scaling + 0.5))
                        index += 1
                    }
                }
    
                let image = NSImage(size: NSSize(width: results.size.dimensions[0], height: results.size.dimensions[1]))
                image.addRepresentation(representation)
                return image
            }
        }
        
        return nil
    }
    
}
