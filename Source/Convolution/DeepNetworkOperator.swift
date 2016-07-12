//
//  DeepNetworkOperator.swift
//  AIToolbox
//
//  Created by Kevin Coble on 6/26/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Foundation


public enum DeepNetworkOperatorType : Int
{
    case Convolution2DOperation = 0
    case PoolingOperation
    case FeedForwardNetOperation
    
    public func getString() ->String
    {
        switch self {
        case .Convolution2DOperation:
            return "2D Convolution"
        case .PoolingOperation:
            return "Pooling"
        case .FeedForwardNetOperation:
            return "FeedForward NN"
        }
    }
    
    public static func getAllTypes() -> [(name: String, type: DeepNetworkOperatorType)]
    {
        var raw = 0
        var results : [(name: String, type: DeepNetworkOperatorType)] = []
        while let type = DeepNetworkOperatorType(rawValue: raw) {
            results.append((name: type.getString(), type: type))
            raw += 1
        }
        return results
    }
    
    public static func getDeepNetworkOperatorFromDict(sourceDictionary: [String: AnyObject]) -> DeepNetworkOperator?
    {
        if let type = sourceDictionary["operatorType"] as? NSInteger {
            if let opType = DeepNetworkOperatorType(rawValue: type) {
                if let opDefinition = sourceDictionary["operatorDefinition"] as? [String: AnyObject] {
                    switch opType {
                    case .Convolution2DOperation:
                        return Convolution2D(fromDictionary: opDefinition)
                    case .PoolingOperation:
                        return Pooling(fromDictionary: opDefinition)
                    case .FeedForwardNetOperation:
                        return DeepNeuralNetwork(fromDictionary: opDefinition)
                    }
                }
            }
        }
        return nil
    }
}


public protocol DeepNetworkOperator : MLPersistence {
    func getType() -> DeepNetworkOperatorType
    func getDetails() -> String
    func getResultingSize(inputSize: DeepChannelSize) -> DeepChannelSize
    func feedForward(inputs: [Float], inputSize: DeepChannelSize) -> [Float]
    func getResults() -> [Float]
    func getResultSize() -> DeepChannelSize
    func getResultRange() ->(minimum: Float, maximum: Float)
    func startBatch()
    func backPropogateGradient(upStreamGradient: [Float]) -> [Float]
    func updateWeights(trainingRate : Float, weightDecay: Float)
}


extension DeepNetworkOperator {
    
    public func getOperationPersistenceDictionary() -> [String : AnyObject] {
        var resultDictionary : [String: AnyObject] = [:]
        
        //  Set the operator type
        resultDictionary["operatorType"] = getType().rawValue
        
        //  Set the definition
        resultDictionary["operatorDefinition"] = getPersistenceDictionary()
        
        return resultDictionary
    }
}