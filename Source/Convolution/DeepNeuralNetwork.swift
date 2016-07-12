//
//  DeepNeuralNetwork.swift
//  AIToolbox
//
//  Created by Kevin Coble on 7/1/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Foundation


import Foundation
import Accelerate

public enum NeuralActivationFunction : Int {
    case None = 0
    case HyberbolicTangent
    case Sigmoid
    case SigmoidWithCrossEntropy
    case RectifiedLinear
    case SoftSign
    case SoftMax        //  Only valid on output (last) layer
    
    func getString() ->String
    {
        switch self {
        case .None:
            return "None"
        case .HyberbolicTangent:
            return "tanh"
        case .Sigmoid:
            return "Sigmoid"
        case .SigmoidWithCrossEntropy:
            return "Sigmoid with X-entropy"
        case .RectifiedLinear:
            return "Rect. Linear"
        case .SoftSign:
            return "Soft-sign"
        case .SoftMax:
            return "Soft-Max"
        }
    }
}


final public class DeepNeuralNetwork : DeepNetworkOperator
{
    var activation : NeuralActivationFunction
    var numInputs = 0
    var numNodes : Int
    var resultSize : DeepChannelSize
    var weights : [Float] = []
    var lastNodeSums : [Float]
    var lastOutputs : [Float]
    private var inputsWithBias : [Float] = []
    var weightAccumulations : [Float] = []
    
    public init(activation : NeuralActivationFunction, size: DeepChannelSize)
    {
        self.activation = activation
        self.resultSize = size
        
        //  Get the number of nodes
        numNodes = resultSize.totalSize
        
        //  Allocate the arrays for results
        lastNodeSums = [Float](count: numNodes, repeatedValue: 0.0)
        lastOutputs = [Float](count: numNodes, repeatedValue: 0.0)
    }
    
    public init?(fromDictionary: [String: AnyObject])
    {
        //  Init for nil return (hopefully Swift 3 removes this need)
        resultSize = DeepChannelSize(numDimensions: 0, dimensions: [])
        numNodes = 0
        weights = []
        lastNodeSums = []
        lastOutputs = []
        
        //  Get the activation type
        let activationTypeValue = fromDictionary["activation"] as? NSInteger
        if activationTypeValue == nil { return nil }
        let tempActivationType = NeuralActivationFunction(rawValue: activationTypeValue!)
        if (tempActivationType == nil) { return nil }
        activation = tempActivationType!
        
        //  Get the number of dimension
        let dimensionValue = fromDictionary["numDimension"] as? NSInteger
        if dimensionValue == nil { return nil }
        let numDimensions = dimensionValue!
        
        //  Get the dimensions levels
        let tempArray = getIntArray(fromDictionary, identifier: "dimensions")
        if (tempArray == nil) { return nil }
        let dimensions = tempArray!
        resultSize = DeepChannelSize(numDimensions: numDimensions, dimensions: dimensions)
        
        //  Get the number of nodes
        numNodes = resultSize.totalSize
        
        //  Get the weights
        let tempWeights = getFloatArray(fromDictionary, identifier: "weights")
        if (tempWeights == nil) { return nil }
        weights = tempWeights!
        numInputs = (weights.count / numNodes) - 1
        
        //  Allocate the arrays for results
        lastNodeSums = [Float](count: numNodes, repeatedValue: 0.0)
        lastOutputs = [Float](count: numNodes, repeatedValue: 0.0)
    }
    
    public func getType() -> DeepNetworkOperatorType
    {
        return .FeedForwardNetOperation
    }
    
    public func getDetails() -> String
    {
        var result = activation.getString() + " ["
        if (resultSize.numDimensions > 0) { result += "\(resultSize.dimensions[0])" }
        if (resultSize.numDimensions > 1) {
            for i in 1..<resultSize.numDimensions {
                result += ", \(resultSize.dimensions[i])"
            }
        }
        result += "]"
        return result
    }
    
    public func getResultingSize(inputSize: DeepChannelSize) -> DeepChannelSize
    {
        //  Input size does not affect output size.  However, it does change the weight sizing
        let newInputCount = inputSize.totalSize
        if (newInputCount != numInputs) {
            numInputs = newInputCount
            allocateAndInitWeights()
        }
        
        return resultSize
    }
    
    public func feedForward(inputs: [Float], inputSize: DeepChannelSize) -> [Float]
    {
        //  Get inputs with a bias term
        inputsWithBias = inputs
        inputsWithBias.append(1.0)
        
        //  Multiply the weight matrix by the inputs to get the node sum values
        vDSP_mmul(weights, 1, inputsWithBias, 1, &lastNodeSums, 1, vDSP_Length(numNodes), 1, vDSP_Length(numInputs+1))
        
        //  Perform the non-linearity
        switch (activation) {
        case .None:
            lastOutputs = lastNodeSums
            break
        case .HyberbolicTangent:
            lastOutputs = lastNodeSums.map({ tanh($0) })
            break
        case .SigmoidWithCrossEntropy:
            fallthrough
        case .Sigmoid:
            lastOutputs = lastNodeSums.map( { 1.0 / (1.0 + exp(-$0)) } )
            break
        case .RectifiedLinear:
            lastOutputs = lastNodeSums.map( { $0 < 0 ? 0.0 : $0 } )
            break
        case .SoftSign:
            lastOutputs = lastNodeSums.map( { $0 / (1.0 + exp($0)) } )
            break
        case .SoftMax:
            lastOutputs = lastNodeSums.map( { exp($0) } )
            break
        }
        
        return lastOutputs
    }
    
    public func getResults() -> [Float]
    {
        return lastOutputs
    }
    
    public func getResultSize() -> DeepChannelSize
    {
        return resultSize
    }
    
    public func getResultRange() ->(minimum: Float, maximum: Float)
    {
        if activation == .HyberbolicTangent {
            return (minimum: -1.0, maximum: 1.0)
        }
        return (minimum: 0.0, maximum: 1.0)
    }
    
    public func startBatch()
    {
        //  Clear the weight accumulations
        weightAccumulations = [Float](count: weights.count, repeatedValue: 0.0)
    }
    
    //  𝟃E/𝟃h comes in, 𝟃E/𝟃x goes out
    public func backPropogateGradient(upStreamGradient: [Float]) -> [Float]
    {
        //  Forward equation is h = fn(Wx), where fn is the activation function
        //  The 𝟃E/𝟃h comes in, we need to calculate 𝟃E/𝟃W and 𝟃E/𝟃x
        //       𝟃E/𝟃W = 𝟃E/𝟃h ⋅ 𝟃h/𝟃z ⋅ 𝟃z/𝟃W
        //             = upStreamGradient ⋅ activation' ⋅ input
        
        //  Get 𝟃E/𝟃z
        var 𝟃E𝟃z : [Float]
        switch (activation) {
        case .None:
            𝟃E𝟃z = upStreamGradient
            break
        case .HyberbolicTangent:
            𝟃E𝟃z = upStreamGradient
            for index in 0..<lastOutputs.count {
                𝟃E𝟃z[index] *= (1 - lastOutputs[index] * lastOutputs[index])
            }
            break
        case .SigmoidWithCrossEntropy:
            fallthrough
        case .Sigmoid:
            𝟃E𝟃z = upStreamGradient
            for index in 0..<lastOutputs.count {
                𝟃E𝟃z[index] *= (lastOutputs[index] - (lastOutputs[index] * lastOutputs[index]))
            }
            break
        case .RectifiedLinear:
            𝟃E𝟃z = upStreamGradient
            for index in 0..<lastOutputs.count {
                if (lastOutputs[index] < 0.0) { 𝟃E𝟃z[index] = 0.0 }
            }
            break
        case .SoftSign:
            𝟃E𝟃z = upStreamGradient
            var z : Float
            //  Reconstitute z from h
            for index in 0..<lastOutputs.count {
                if (lastOutputs[index] < 0) {        //  Negative z
                    z = lastOutputs[index] / (1.0 + lastOutputs[index])
                    𝟃E𝟃z[index] /= -((1.0 + z) * (1.0 + z))
                }
                else {              //  Positive z
                    z = lastOutputs[index] / (1.0 - lastOutputs[index])
                    𝟃E𝟃z[index] /= ((1.0 + z) * (1.0 + z))
                }
            }
            break
        case .SoftMax:
            //  Should not get here - softmax is not allowed except on final layer
            𝟃E𝟃z = upStreamGradient
            break
        }
        
        //  Get 𝟃E/𝟃W.  𝟃E/𝟃W = 𝟃E/𝟃z ⋅ 𝟃z/𝟃W = 𝟃E𝟃z ⋅ inputsWithBias
        var weightChange = [Float](count: weights.count, repeatedValue: 0.0)
        vDSP_mmul(𝟃E𝟃z, 1, inputsWithBias, 1, &weightChange, 1, vDSP_Length(numNodes), vDSP_Length(numInputs+1), 1)
        vDSP_vadd(weightChange, 1, weightAccumulations, 1, &weightAccumulations, 1, vDSP_Length(weightChange.count))

        
        //  Get 𝟃E/𝟃x.  𝟃E/𝟃x = 𝟃E/𝟃z ⋅ 𝟃z/𝟃x = 𝟃E𝟃z ⋅ weights
        var downStreamGradient = [Float](count: numInputs, repeatedValue: 0.0)
        for index in 0..<numInputs {
            vDSP_dotpr(&weights[index], vDSP_Stride(numInputs+1), 𝟃E𝟃z, 1, &downStreamGradient[index], vDSP_Length(numNodes))
        }
        
        return downStreamGradient
    }
    
    public func updateWeights(trainingRate : Float, weightDecay: Float)
    {
        //  If there is a decay factor, use it
        if (weightDecay != 1.0) {
            var λ = weightDecay     //  Needed for unsafe pointer conversion
            vDSP_vsmul(weights, 1, &λ, &weights, 1, vDSP_Length(weights.count))
        }
        
        //  Add the weight changes to the weights
        var η = trainingRate     //  Needed for unsafe pointer conversion
        vDSP_vsma(weightAccumulations, 1, &η, weights, 1, &weights, 1, vDSP_Length(weights.count))
    }

    
    func allocateAndInitWeights()
    {
        //  Allocate the weight array
        let numWeights = (numInputs + 1) * numNodes   //  Add bias offset
        weights = []
        for _ in 0..<numWeights {
            weights.append(DeepNeuralNetwork.floatGaussianRandom(0.0, standardDeviation : 1.0))
        }
    }
    
    public func getPersistenceDictionary() -> [String: AnyObject]
    {
        var resultDictionary : [String: AnyObject] = [:]
        
        //  Set the activation type
        resultDictionary["activation"] = activation.rawValue
        
        //  Set the number of dimension
        resultDictionary["numDimension"] = resultSize.numDimensions
        
        //  Set the dimensions levels
        resultDictionary["dimensions"] = resultSize.dimensions
        
        //  Set the weights
        resultDictionary["weights"] = weights
        
        return resultDictionary
    }
    
    static var y2 : Float = 0.0
    static var use_last = false
    static func floatGaussianRandom(mean : Float, standardDeviation : Float) -> Float
    {
        var y1 : Float
        if (use_last)		        /* use value from previous call */
        {
            y1 = y2
            use_last = false
        }
        else
        {
            var w : Float = 1.0
            var x1 : Float = 0.0
            var x2 : Float = 0.0
            repeat {
                x1 = 2.0 * (Float(arc4random()) / Float(UInt32.max)) - 1.0
                x2 = 2.0 * (Float(arc4random()) / Float(UInt32.max)) - 1.0
                w = x1 * x1 + x2 * x2
            } while ( w >= 1.0 )
            
            w = sqrt( (-2.0 * log( w ) ) / w )
            y1 = x1 * w
            y2 = x2 * w
            use_last = true
        }
        
        return( mean + y1 * standardDeviation )
    }
}
