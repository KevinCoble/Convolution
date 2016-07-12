//
//  DeepNetwork.swift
//  AIToolbox
//
//  Created by Kevin Coble on 6/25/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Foundation

protocol DeepNetworkInputSource {
    func getInputDataSize(inputID : String) -> DeepChannelSize?
    func getValuesForID(inputID : String) -> [Float]
    func getAllValues() -> [Float]
}

protocol DeepNetworkOutputDestination {
    func getGradientForSource(sourceID : String) -> [Float]
}


public struct DeepNetworkInput : MLPersistence {
    let inputID : String
    var size : DeepChannelSize
    var values : [Float]
    
    public init(inputID: String, size: DeepChannelSize, values: [Float])
    {
        self.inputID = inputID
        self.size = size
        self.values = values
    }
    
    //  Persistence assumes values are set later, and only ID and size need to be saved
    public init?(fromDictionary: [String: AnyObject])
    {
        //  Init for nil return (hopefully Swift 3 removes this need)
        size = DeepChannelSize(numDimensions: 0, dimensions: [])
        values = []
        
        //  Get the id string
        let id = fromDictionary["inputID"] as? NSString
        if id == nil { return nil }
        inputID = id! as String
        
        //  Get the number of dimension
        let dimensionValue = fromDictionary["numDimension"] as? NSInteger
        if dimensionValue == nil { return nil }
        let numDimensions = dimensionValue!
        
        //  Get the dimensions values
        let tempArray = getIntArray(fromDictionary, identifier: "dimensions")
        if (tempArray == nil) { return nil }
        let dimensions = tempArray!
        size = DeepChannelSize(numDimensions: numDimensions, dimensions: dimensions)
    }
    
    public func getPersistenceDictionary() -> [String: AnyObject]
    {
        var resultDictionary : [String: AnyObject] = [:]
        
        //  Set the identifier
        resultDictionary["inputID"] = inputID
        
        //  Set the number of dimension
        resultDictionary["numDimension"] = size.numDimensions
        
        //  Set the dimensions levels
        resultDictionary["dimensions"] = size.dimensions
        
        return resultDictionary
    }
}

///  Top-level class for a deep neural network definition
final public class DeepNetwork : DeepNetworkInputSource, DeepNetworkOutputDestination, MLPersistence
{
    var inputs : [DeepNetworkInput] = []
    
    var layers : [DeepLayer] = []
    
    var validated = false
    
    private var finalResultMin : Float = 0.0
    private var finalResultMax : Float = 1.0
    
    private var finalResults : [Float] = []
    private var errorVector : [Float] = []
    
    init() {
    }
    
    public init?(fromDictionary: [String: AnyObject])
    {
        //  Get the array of inputs
        let inputArray = fromDictionary["inputs"] as? NSArray
        if (inputArray == nil)  { return nil }
        for item in inputArray! {
            let element = item as? [String: AnyObject]
            if (element == nil)  { return nil }
            let input = DeepNetworkInput(fromDictionary: element!)
            if (input == nil)  { return nil }
            inputs.append(input!)
        }
        
        //  Get the array of layers
        let layerArray = fromDictionary["layers"] as? NSArray
        if (layerArray == nil)  { return nil }
        for item in layerArray! {
            let element = item as? [String: AnyObject]
            if (element == nil)  { return nil }
            let layer = DeepLayer(fromDictionary: element!)
            if (layer == nil)  { return nil }
            layers.append(layer!)
        }
    }
    
    ///  Function to add an input to the network
    public func addInput(newInput: DeepNetworkInput)
    {
        inputs.append(newInput)
    }
    
    ///  Function to remove an input from the network
    public func removeInput(inputIndex: Int)
    {
        if (inputIndex >= 0 && inputIndex < inputs.count) {
            inputs.removeAtIndex(inputIndex)
        }
        validated = false
    }
    
    //  Function to get the index from an input ID
    public func getInputIndex(idString: String) -> Int?
    {
        for index in 0..<inputs.count {
            if (inputs[index].inputID == idString) { return index }
        }
        return nil
    }
    
    ///  Function to set the values for an input
    public func setInputValues(forInput: String, values : [Float])
    {
        //  Get the input to process
        if let index = getInputIndex(forInput) {
            inputs[index].values = values
        }
    }
    
    ///  Function to get the size of an input set
    public func getInputDataSize(inputID : String) -> DeepChannelSize?
    {
        //  Get the index
        if let index = getInputIndex(inputID) {
            return inputs[index].size
        }
        return nil
    }

    
    ///  Function to add a layer to the network
    public func addLayer(newLayer: DeepLayer)
    {
        layers.append(newLayer)
        validated = false
    }
    
    ///  Function to remove a layer from the network
    public func removeLayer(layerIndex: Int)
    {
        if (layerIndex >= 0 && layerIndex < layers.count) {
            layers.removeAtIndex(layerIndex)
            validated = false
        }
    }
    
    ///  Function to add a channel to the network
    public func addChannel(toLayer: Int, newChannel: DeepChannel)
    {
        if (toLayer >= 0 && toLayer < layers.count) {
            layers[toLayer].addChannel(newChannel)
            validated = false
        }
    }
    
    ///  Functions to remove a channel from the network
    public func removeChannel(layer: Int, channelIndex: Int)
    {
        if (layer >= 0 && layer < layers.count) {
            layers[layer].removeChannel(channelIndex)
            validated = false
        }
    }
    public func removeChannel(layer: Int, channelID: String)
    {
        if let index = layers[layer].getChannelIndex(channelID) {
            removeChannel(layer, channelIndex: index)
        }
    }
    
    ///  Functions to add a network operator to the network
    public func addNetworkOperator(toLayer: Int, channelIndex: Int, newOperator: DeepNetworkOperator)
    {
        if (toLayer >= 0 && toLayer < layers.count) {
            layers[toLayer].addNetworkOperator(channelIndex, newOperator: newOperator)
            validated = false
        }
    }
    public func addNetworkOperator(toLayer: Int, channelID: String, newOperator: DeepNetworkOperator)
    {
        if (toLayer >= 0 && toLayer < layers.count) {
            if let index = layers[toLayer].getChannelIndex(channelID) {
                layers[toLayer].addNetworkOperator(index, newOperator: newOperator)
                validated = false
            }
        }
    }
    
    ///  Functions to remove a network operator from the network
    public func removeNetworkOperator(layer: Int, channelIndex: Int, operatorIndex: Int)
    {
        if (layer >= 0 && layer < layers.count) {
            layers[layer].removeNetworkOperator(channelIndex, operatorIndex: operatorIndex)
            validated = false
        }
    }
    public func removeNetworkOperator(layer: Int, channelID: String, operatorIndex: Int)
    {
        if let index = layers[layer].getChannelIndex(channelID) {
            layers[layer].removeNetworkOperator(index, operatorIndex: operatorIndex)
            validated = false
        }
    }
    
    ///  Function to validate a DeepNetwork
    ///  This method checks that the inputs to each layer are available, returning an array of strings describing any errors
    ///  The resulting size of each channel is updated as well
    public func validateNetwork() -> [String]
    {
        var errorStrings: [String] = []
        
        var prevLayer : DeepNetworkInputSource = self
        
        for layer in 0..<layers.count {
            errorStrings += layers[layer].validateAgainstPreviousLayer(prevLayer, layerIndex: layer)
            prevLayer = layers[layer]
        }
        
        validated = (errorStrings.count == 0)
        
        finalResultMin = 0.0
        finalResultMax = 1.0
        if let lastLayer = layers.last {
            let range = lastLayer.getResultRange()
            finalResultMin = range.minimum
            finalResultMax = range.maximum
        }
        
        return errorStrings
    }
    
    ///  Function to run the network forward.  Assumes inputs have been set
    ///  Returns the values from the last layer
    public func feedForward() -> [Float]
    {
        //  Make sure we are validated
        if (!validated) {
            validateNetwork()
            if !validated { return [] }
        }
        
        var prevLayer : DeepNetworkInputSource = self
        
        for layer in 0..<layers.count {
            layers[layer].feedForward(prevLayer)
            prevLayer = layers[layer]
        }
        
        //  Keep track of the number of outputs from the final layer, so we can generate an error term later
        finalResults = prevLayer.getAllValues()
        
        return finalResults
    }
    
    public func getResultClass() -> Int
    {
        if finalResults.count == 1 {
            if finalResults[0] > ((finalResultMax + finalResultMin) * 0.5) { return 1 }
            return 0
        }
        else {
            var bestClass = 0
            var highestResult = -Float.infinity
            for classIndex in 0..<finalResults.count {
                if (finalResults[classIndex] > highestResult) {
                    highestResult = finalResults[classIndex]
                    bestClass = classIndex
                }
            }
            return bestClass
        }
    }
    
    ///  Function to clear weight-change accumulations for the start of a batch
    public func startBatch()
    {
        for layer in layers {
            layer.startBatch()
        }
    }
    
    ///  Function to run the network backward, propagating the error term.  Assumes inputs have been set
    public func backPropagate(expectedResultClass: Int)
    {
        if (layers.count < 1) { return }  //  Can't backpropagate through non-existant layers
            
        //  Get an error vector to pass to the final layer.  This is the gradient if using least-squares error
        errorVector = [Float](count: finalResults.count, repeatedValue: finalResultMin)
        if (finalResults.count == 1) {
            if (expectedResultClass == 1) {
                errorVector[0] = finalResultMax - finalResults[0]
            }
            else {
                errorVector[0] = finalResultMin - finalResults[0]
            }
        }
        else {
            for index in 0..<finalResults.count {
                if (index == expectedResultClass) {
                    errorVector[index] = finalResultMax - finalResults[index]
                }
                else {
                    errorVector[index] = finalResultMin - finalResults[index]
                }
            }
        }
        
        layers.last!.backPropagate(self)
        
        for layerIndex in (layers.count - 2).stride(through: 0, by: -1) {
            layers[layerIndex].backPropagate(layers[layerIndex+1])
        }
    }
    
    ///  Function to get the expected network output for a given class
    public func getExpectedOutput(forClass: Int) ->[Float]
    {
        var expectedOutputVector = [Float](count: finalResults.count, repeatedValue: finalResultMin)
        if (finalResults.count == 1) {
            if (forClass == 1) { expectedOutputVector[0] = finalResultMax }
        }
        else {
            if (forClass >= 0 && forClass < finalResults.count) {
                expectedOutputVector[forClass] = finalResultMax
            }
        }
        
        return expectedOutputVector
    }
    
    ///  Function to get the total error with respect to an expected output class
    public func getTotalError(expectedClass: Int) ->Float
    {
        var result : Float = 0.0
        
        let expectedOutput = getExpectedOutput(expectedClass)
        for index in 0..<expectedOutput.count {
            result += abs(expectedOutput[index] - finalResults[index])
        }
        
        return result
    }
    
    public func updateWeights(trainingRate : Float, weightDecay: Float)
    {
        for layer in layers {
            layer.updateWeights(trainingRate, weightDecay: weightDecay)
        }
    
    }
    
    public func getValuesForID(inputID : String) -> [Float]
    {
        //  Get the index
        if let index = getInputIndex(inputID) {
            return inputs[index].values
        }
        return []
    }
    
    public func getAllValues() -> [Float]
    {
        var result : [Float] = []
        for input in inputs {
            result += input.values
        }
        return result
    }
    
    func getGradientForSource(sourceID : String) -> [Float]
    {
        //  We only have one 'channel', so just return the error
        return errorVector
    }

    public func getResultOfItem(layer: Int, channelIndex: Int, operatorIndex: Int) ->(values : [Float], size: DeepChannelSize)?
    {
        if (layer >= 0 && layer < layers.count) {
            return layers[layer].getResultOfItem(channelIndex, operatorIndex: operatorIndex)
        }
        return nil
    }
    
    public func getPersistenceDictionary() -> [String: AnyObject]
    {
        var resultDictionary : [String: AnyObject] = [:]
        
        //  Set the array of inputs
        var inputArray : [[String: AnyObject]] = []
        for input in inputs {
            inputArray.append(input.getPersistenceDictionary())
        }
        resultDictionary["inputs"] = inputArray
        
        //  Set the array of layers
        var layerArray : [[String: AnyObject]] = []
        for layer in layers {
            layerArray.append(layer.getPersistenceDictionary())
        }
        resultDictionary["layers"] = layerArray
        
        return resultDictionary
    }
}