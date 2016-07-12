//
//  Convolution.swift
//  AIToolbox
//
//  Created by Kevin Coble on 2/13/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Foundation
import Accelerate

public enum Convolution2DMatrix : Int
{
    case VerticalEdge3 = 0
    case HorizontalEdge3
    case Custom3
    
    public func getString() ->String
    {
        switch self {
        case .VerticalEdge3:
            return "Vertical Edge 3x3"
        case .HorizontalEdge3:
            return "Horizontal Edge 3x3"
        case .Custom3:
            return "Custom 3x3"
        }
    }
    
    public func getMatrix() ->[Float]?
    {
        var matrix : [Float]
        switch self {
        case .VerticalEdge3:
            matrix = [-1, 0, 1, -2, 0, 2, -1, 0 , 1]
        case .HorizontalEdge3:
            matrix =  [-1, -2, -1, 0, 0, 0, 1, 2 , 1]
        case .Custom3:
            matrix =  [0, 0, 0, 0, 1, 0, 0, 0, 0]      //  Default to the identity convolution
        }
        
        return matrix
    }
    
    public func getMatrixSize() ->Int
    {
        switch self {
        case .VerticalEdge3, .HorizontalEdge3, .Custom3:
            return 3
        }
    }
    
    public func getCustomOfSameSize() ->Convolution2DMatrix
    {
        switch self {
        case .VerticalEdge3, .HorizontalEdge3, .Custom3:
            return .Custom3
        }
    }
}

final public class Convolution2D : DeepNetworkOperator
{
    var matrixType : Convolution2DMatrix
    var matrix : [Float] {
        didSet {
            determineResultRange()
        }
    }
    var minResult : Float = -1.0
    var maxResult : Float = 1.0
    var convolution : [Float] = []
    var resultSize : DeepChannelSize

    public init(usingMatrix : Convolution2DMatrix)
    {
        matrixType = usingMatrix
        if matrixType != .Custom3 {
            matrix = matrixType.getMatrix()!
        }
        else {
            matrix = [0, 0, 0, 0, 1, 0, 0, 0 , 0]
        }
        resultSize = DeepChannelSize(numDimensions: 0, dimensions: [])
        determineResultRange()
    }
    
    public init?(fromDictionary: [String: AnyObject])
    {
        //  Init for nil return (hopefully Swift 3 removes this need)
        resultSize = DeepChannelSize(numDimensions: 0, dimensions: [])
        matrix = []

        //  Get the matrix type
        let matrixTypeValue = fromDictionary["matrixType"] as? NSInteger
        if matrixTypeValue == nil { return nil }
        let tempMatrixType = Convolution2DMatrix(rawValue: matrixTypeValue!)
        if (tempMatrixType == nil) { return nil }
        matrixType = tempMatrixType!
        
        //  Get the matrix
        let tempArray = getFloatArray(fromDictionary, identifier: "matrix")
        if (tempArray == nil) { return nil }
        matrix = tempArray!
        determineResultRange()
    }

    public func determineResultRange()
    {
        minResult = 0.0
        maxResult = 0.0
        for element in matrix {
            if element < 0 {
                minResult += element
            }
            else {
                maxResult += element
            }
        }
    }
    
    public func getType() -> DeepNetworkOperatorType
    {
        return .Convolution2DOperation
    }
    
    public func getDetails() -> String
    {
        return matrixType.getString()
    }

    public func getResultingSize(inputSize: DeepChannelSize) -> DeepChannelSize
    {
        //  A convolution doesn't change the size
        resultSize = inputSize
        return inputSize
    }
    
    public func feedForward(inputs: [Float], inputSize: DeepChannelSize) -> [Float]
    {
        let matrixSize = UInt32(matrixType.getMatrixSize())

        //  Get the source data as a vImage buffer
        var source = vImage_Buffer(data: UnsafeMutablePointer<Void>(inputs), height: vImagePixelCount(inputSize.dimensions[1]), width: vImagePixelCount(inputSize.dimensions[0]), rowBytes: inputSize.dimensions[0] * sizeof(Float))

        //  Create a destination as a vImage buffer
        convolution = [Float](count: inputs.count, repeatedValue: 0.0)
        var dest = vImage_Buffer(data: UnsafeMutablePointer<Void>(convolution), height: vImagePixelCount(inputSize.dimensions[1]), width: vImagePixelCount(inputSize.dimensions[0]), rowBytes: inputSize.dimensions[0] * sizeof(Float))

        //  Convolve
        let error = vImageConvolve_PlanarF(&source, &dest, nil, 0, 0, matrix, matrixSize, matrixSize, 0.0, UInt32(kvImageEdgeExtend))
        if (error != kvImageNoError) {
            convolution = []
        }
        
        return convolution
    }
    
    public func getResults() -> [Float]
    {
        return convolution
    }

    public func getResultSize() -> DeepChannelSize
    {
        return resultSize
    }
    
    
    public func getResultRange() ->(minimum: Float, maximum: Float)
    {
        return (minimum: minResult, maximum: maxResult)
    }
    
    public func startBatch()
    {
        //!!  No weights to modify yet
    }
    
    //  𝟃E/𝟃h comes in, 𝟃E/𝟃x goes out
    public func backPropogateGradient(upStreamGradient: [Float]) -> [Float]
    {
        //!!  This will work for initial testing, but is wrong
        return upStreamGradient
    }
    
    public func updateWeights(trainingRate : Float, weightDecay: Float)
    {
        //!!  No weights to modify yet
    }

    
    
    public func getPersistenceDictionary() -> [String: AnyObject]
    {
        var resultDictionary : [String: AnyObject] = [:]
        
        //  Set the matrix type
        resultDictionary["matrixType"] = matrixType.rawValue
        
        //  Get the matrix
        resultDictionary["matrix"] = matrix
        
        return resultDictionary
    }
}
