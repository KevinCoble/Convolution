//
//  Pooling.swift
//  Convolution
//
//  Created by Kevin Coble on 2/20/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Cocoa
import Accelerate

public enum PoolingType : Int {
    case Average = 0
    case Minimum
    case Maximum
    
    public func getString() ->String
    {
        switch self {
        case .Average:
            return "Average"
        case .Minimum:
            return "Minimum"
        case .Maximum:
            return "Maximum"
        }
    }
}

final public class Pooling : DeepNetworkOperator
{
    var poolType : PoolingType
    var dimension: Int
    var reductionLevels: [Int]
    var pool : [Float] = []
    var resultSize : DeepChannelSize
    private var inputSize = DeepChannelSize(numDimensions: 0, dimensions: [])
    
    public init(type : PoolingType, dimension: Int)
    {
        poolType = type
        self.dimension = dimension      //  Max of 4 at this time - we will add error handling later
        reductionLevels = [Int](count: dimension, repeatedValue: 1)
        resultSize = DeepChannelSize(numDimensions: 0, dimensions: [])
    }
    
    public init?(fromDictionary: [String: AnyObject])
    {
        //  Init for nil return (hopefully Swift 3 removes this need)
        reductionLevels = []
        resultSize = DeepChannelSize(numDimensions: 0, dimensions: [])
        
        //  Get the pooling type
        let poolTypeValue = fromDictionary["poolingType"] as? NSInteger
        if poolTypeValue == nil { return nil }
        let tempPoolType = PoolingType(rawValue: poolTypeValue!)
        if (tempPoolType == nil) { return nil }
        poolType = tempPoolType!
        
        //  Get the dimension
        let dimensionValue = fromDictionary["dimension"] as? NSInteger
        if dimensionValue == nil { return nil }
        dimension = dimensionValue!
        
        //  Get the reduction levels
        let tempArray = getIntArray(fromDictionary, identifier: "reductionLevels")
        if (tempArray == nil) { return nil }
        reductionLevels = tempArray!
        
        resultSize = DeepChannelSize(numDimensions: dimension, dimensions: reductionLevels)
    }
    
    public func setReductionLevel(forDimension: Int, newLevel: Int)
    {
        if (forDimension >= 0 && forDimension < dimension) {
            reductionLevels[forDimension] = newLevel
        }
    }
    
    public func getType() -> DeepNetworkOperatorType
    {
        return .PoolingOperation
    }
    
    public func getDetails() -> String
    {
        var result : String
        switch poolType {
        case .Average:
            result = "Avg ["
        case .Minimum:
            result = "Min ["
        case .Maximum:
            result = "Max ["
        }
        if (dimension > 0) { result += "\(reductionLevels[0])" }
        if (dimension > 1) {
            for i in 1..<dimension {
                result += ", \(reductionLevels[i])"
            }
        }
        result += "]"
        return result
    }
    
    public func getResultingSize(inputSize: DeepChannelSize) -> DeepChannelSize
    {
        //  Reduce each of the dimensions by the specified reduction levels
        resultSize = inputSize
        for i in 0..<dimension {
            resultSize.dimensions[i] /= reductionLevels[i]
        }
        
        return resultSize
    }
    
    public func feedForward(inputs: [Float], inputSize: DeepChannelSize) -> [Float]
    {
        self.inputSize = inputSize
        
        //  Limit reduction to a 1 pixel value in each dimension
        var sourceSize = inputSize.dimensions
        sourceSize += [1, 1, 1]     //  Add size for missing dimensions
        var resultSize = inputSize.dimensions
        resultSize += [1, 1, 1]     //  Add size for missing dimensions
        var reduction = [Int](count:4, repeatedValue: 1)
        var sourceStride = [Int](count:4, repeatedValue: 1)
        var resultStride = [Int](count:4, repeatedValue: 1)
        var totalSize = 1
        for index in 0..<dimension {
            reduction[index] = reductionLevels[index]
            if (inputSize.dimensions[index]  < reduction[index]) { reduction[index] = inputSize.dimensions[index] }
            resultSize[index] = inputSize.dimensions[index] / reductionLevels[index]
            totalSize *= resultSize[index]
        }
        
        //  Determine the stride for each dimension
        for index in 0..<4 {
            if (index > 0) {
                for i in 0..<index { sourceStride[index] *= sourceSize[i] }
                for i in 0..<index { resultStride[index] *= resultSize[i] }
            }
        }
        
        //  Allocate the result array
        switch poolType {
        case .Minimum:
            pool = [Float](count:totalSize, repeatedValue: Float.infinity)
        case .Maximum:
            pool = [Float](count:totalSize, repeatedValue: -Float.infinity)
        case .Average:
            pool = [Float](count:totalSize, repeatedValue: 0.0)
        }
        
        //  Reduce each dimension
        for w in 0..<resultSize[3] {
            let wResultStart = w * resultStride[3]
            for wGroup in 0..<reduction[3] {
                let wSourceStart = ((w*reduction[3] + wGroup) * sourceStride[3])
                for z in 0..<resultSize[2] {
                    let zResultStart = wResultStart + (z * resultStride[2])
                    for zGroup in 0..<reduction[2] {
                        let zSourceStart = wSourceStart + ((z*reduction[2] + zGroup) * sourceStride[2])
                        for y in 0..<resultSize[1] {
                            let yResultStart = zResultStart + (y * resultStride[1])
                            for yGroup in 0..<reduction[1] {
                                let ySourceStart = zSourceStart + ((y*reduction[1] + yGroup) * sourceStride[1])
                                for x in 0..<resultSize[0] {
                                    let resultIndex = yResultStart + x
                                    let xSourceStart = ySourceStart + x*reduction[0]
                                    for xGroup in 0..<reduction[0] {
                                        let sourceIndex = xSourceStart + xGroup
                                        switch poolType {
                                        case .Minimum:
                                            if (inputs[sourceIndex] < pool[resultIndex]) { pool[resultIndex] = inputs[sourceIndex] }
                                        case .Maximum:
                                            if (inputs[sourceIndex] > pool[resultIndex]) { pool[resultIndex] = inputs[sourceIndex] }
                                        case .Average:
                                            pool[resultIndex] += inputs[sourceIndex]
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if (poolType == .Average) {
            var totalCells = 1
            for index in 0..<4 { totalCells *= reduction[index] }
            var multiplier : Float = 1.0 / Float(totalCells)
            vDSP_vsmul(pool, 1, &multiplier, &pool, 1, vDSP_Length(pool.count))
        }
        
        return pool
    }
    
    public func getResults() -> [Float]
    {
        return pool
    }
    
    public func getResultSize() -> DeepChannelSize
    {
        return resultSize
    }
    
    public func getResultRange() ->(minimum: Float, maximum: Float)
    {
        //  Result range is a function of the input range.  Default to a value that will work, even if not optimum
        return (minimum: 0.0, maximum: 1.0)
    }
    
    public func startBatch()
    {
        //  No weights in a pooling operation
    }
    
    //  𝟃E/𝟃h comes in, 𝟃E/𝟃x goes out
    public func backPropogateGradient(upStreamGradient: [Float]) -> [Float]
    {
        //  The gradient just gets spread over the input space that was pooled
        var downstreamGradient = [Float](count:inputSize.totalSize, repeatedValue: 0.0)
        
        //  Get spread factor for each dimension
        var sourceSize = resultSize.dimensions
        sourceSize += [1, 1, 1]     //  Add size for missing dimensions
        var destSize = inputSize.dimensions
        destSize += [1, 1, 1]     //  Add size for missing dimensions
        let spreadW = destSize[3] / sourceSize[3]
        let spreadZ = destSize[2] / sourceSize[2]
        let spreadY = destSize[1] / sourceSize[1]
        let spreadX = destSize[0] / sourceSize[0]
        let multiplier = 1.0 / Float(spreadW + spreadZ + spreadY + spreadX)
        
        //  Determine the stride for each dimension
        var sourceStride = [Int](count:4, repeatedValue: 1)
        var destStride = [Int](count:4, repeatedValue: 1)
        for index in 0..<4 {
            if (index > 0) {
                for i in 0..<index { sourceStride[index] *= sourceSize[i] }
                for i in 0..<index { destStride[index] *= destSize[i] }
            }
        }
        
        //  Spread each dimension
        for w in 0..<sourceSize[3] {
            let wSourceStart = w * sourceStride[3]
            let wDestStart = w * destStride[3]
            for wGroup in 0..<spreadW {
                let wDestGroupStart = wDestStart + (wGroup * destStride[3])
                for z in 0..<sourceSize[2] {
                    let zSourceStart = wSourceStart + (z * sourceStride[2])
                    let zDestStart = wDestGroupStart + (z * destStride[2])
                    for zGroup in 0..<spreadZ {
                        let zDestGroupStart = zDestStart + (zGroup * destStride[2])
                        for y in 0..<sourceSize[1] {
                            let ySourceStart = zSourceStart + (y * sourceStride[1])
                            let yDestStart = zDestGroupStart + (y * destStride[1])
                            for yGroup in 0..<spreadY {
                                let yDestGroupStart = yDestStart + (yGroup * destStride[1])
                                for x in 0..<sourceSize[0] {
                                    let sourceIndex = ySourceStart + x
                                    let xDestStart = yDestGroupStart + (x * spreadX)
                                    for xGroup in 0..<spreadX {
                                        downstreamGradient[xDestStart + xGroup] = upStreamGradient[sourceIndex] * multiplier
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return downstreamGradient
    }
    
    public func updateWeights(trainingRate : Float, weightDecay: Float)
    {
        //  No weights in a pooling operation
    }
    
    public func getPersistenceDictionary() -> [String: AnyObject]
    {
        var resultDictionary : [String: AnyObject] = [:]
        
        //  Set the pooling type
        resultDictionary["poolingType"] = poolType.rawValue
        
        //  Set the dimension
        resultDictionary["dimension"] = dimension
        
        //  Set the reduction levels
        resultDictionary["reductionLevels"] = reductionLevels
        
        return resultDictionary
    }
}
