//
//  DeepChannel.swift
//  AIToolbox
//
//  Created by Kevin Coble on 6/25/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Foundation

public struct DeepChannelSize {
    let numDimensions : Int
    var dimensions : [Int]
    
    var totalSize: Int {
        get {
            var result = 1
            for i in 0..<numDimensions {
                result *= dimensions[i]
            }
            return result
        }
    }
    
    public func asString() ->String
    {
        var result = "\(numDimensions)D - ["
        if (numDimensions > 0) { result += "\(dimensions[0])" }
        if (numDimensions > 1) {
            for i in 1..<numDimensions {
                result += ", \(dimensions[i])"
            }
        }
        result += "]"
        
        return result
    }
}

///  Class for a single channel of a deep layer
///  A deep channel manages a network topology for a single data-stream within a deep layer
///  It contains an ordered array of 'network operators' that manipulate the channel data (convolutions, poolings, feedforward nets, etc.)
final public class DeepChannel : MLPersistence
{
    let idString : String           //  The string ID for the channel.  i.e. "red component"
    var sourceChannelID : String    //  ID of the channel that is the source for this channel from the previous layer
    var resultSize : DeepChannelSize    //  Size of the result of this channel
    
    var networkOperators : [DeepNetworkOperator] = []
    
    private var inputErrorGradient : [Float] = []
    
    init(identifier: String) {
        idString = identifier
        sourceChannelID = ""
        resultSize = DeepChannelSize(numDimensions: 1, dimensions: [0])
    }
    
    public init?(fromDictionary: [String: AnyObject])
    {
        //  Init for nil return (hopefully Swift 3 removes this need)
        resultSize = DeepChannelSize(numDimensions: 1, dimensions: [0])
        
        //  Get the id string type
        let id = fromDictionary["idString"] as? NSString
        if id == nil { return nil }
        idString = id! as String
        
        //  Get the source ID
        let source = fromDictionary["sourceChannelID"] as? NSString
        if source == nil { return nil }
        sourceChannelID = source! as String
        
        //  Get the array of network operators
        let networkOpArray = fromDictionary["networkOperators"] as? NSArray
        if (networkOpArray == nil)  { return nil }
        for item in networkOpArray! {
            let element = item as? [String: AnyObject]
            if (element == nil)  { return nil }
            let netOperator = DeepNetworkOperatorType.getDeepNetworkOperatorFromDict(element!)
            if (netOperator == nil)  { return nil }
            networkOperators.append(netOperator!)
        }
    }
    
    ///  Function to add a network operator to the channel
    public func addNetworkOperator(newOperator: DeepNetworkOperator)
    {
        networkOperators.append(newOperator)
    }
    
    ///  Functions to remove a network operator from the channel
    public func removeNetworkOperator(operatorIndex: Int)
    {
        if (operatorIndex >= 0 && operatorIndex < networkOperators.count) {
            networkOperators.removeAtIndex(operatorIndex)
        }
    }
    
    //  Method to determine the output size based on the input size and the operation layers
    func updateOutputSize(inputSize : DeepChannelSize)
    {
        //  Iterate through each operator, adjusting the size
        var currentSize = inputSize
        for networkOperator in networkOperators {
            currentSize = networkOperator.getResultingSize(currentSize)
        }
        resultSize = currentSize
    }
    
    
    func getResultRange() ->(minimum: Float, maximum: Float)
    {
        if let lastOperator = networkOperators.last {
            return lastOperator.getResultRange()
        }
        return (minimum: 0.0, maximum: 1.0)
    }

    
    //  Method to feed values forward through the channel
    func feedForward(inputSource: DeepNetworkInputSource)
    {
        //  Get the inputs from the previous layer
        var inputs = inputSource.getValuesForID(sourceChannelID)
        var inputSize = inputSource.getInputDataSize(sourceChannelID)
        if (inputSize == nil) { return }
        
        //  Process each operator
        for networkOperator in networkOperators {
            inputs = networkOperator.feedForward(inputs, inputSize: inputSize!)
            inputSize = networkOperator.getResultSize()
        }
    }
    
    //  Function to clear weight-change accumulations for the start of a batch
    public func startBatch()
    {
        for networkOperator in networkOperators {
            networkOperator.startBatch()
        }
    }
    
    func backPropagate(gradientSource: DeepNetworkOutputDestination)
    {
        //  Get the gradients from the previous layer
        inputErrorGradient = gradientSource.getGradientForSource(idString)
        
        //  Process the gradient backwards through all the operators
        for operatorIndex in (networkOperators.count - 1).stride(through: 0, by: -1) {
            inputErrorGradient = networkOperators[operatorIndex].backPropogateGradient(inputErrorGradient)
        }
    }
    
    public func updateWeights(trainingRate : Float, weightDecay: Float)
    {
        for networkOperator in networkOperators {
            networkOperator.updateWeights(trainingRate, weightDecay: weightDecay)
        }
    }

    func getGradient() -> [Float]
    {
        return inputErrorGradient
    }
    
    ///  Function to get the result of the last operation
    public func getFinalResult() -> [Float]
    {
        if let lastOperator = networkOperators.last {
            return lastOperator.getResults()
        }
        return []
    }
    
    public func getResultOfItem(operatorIndex: Int) ->(values : [Float], size: DeepChannelSize)?
    {
        if (operatorIndex >= 0 && operatorIndex < networkOperators.count) {
            let values = networkOperators[operatorIndex].getResults()
            let size = networkOperators[operatorIndex].getResultSize()
            return (values : values, size: size)
        }
        return nil
    }
    
    public func getPersistenceDictionary() -> [String: AnyObject]
    {
        var resultDictionary : [String: AnyObject] = [:]
        
        //  Set the id string type
        resultDictionary["idString"] = idString
        
        //  Set the source ID
        resultDictionary["sourceChannelID"] = sourceChannelID
        
        //  Set the array of network operators
        var operationsArray : [[String: AnyObject]] = []
        for networkOperator in networkOperators {
            operationsArray.append(networkOperator.getOperationPersistenceDictionary())
        }
        resultDictionary["networkOperators"] = operationsArray
        
        return resultDictionary
    }

}