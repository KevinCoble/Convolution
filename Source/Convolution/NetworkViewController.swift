//
//  ViewController.swift
//  Convolution
//
//  Created by Kevin Coble on 2/13/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Cocoa

enum ImageSourceSelecton : Int {
    case Image = 0
    case DataSourceImage
    case SelectedItem
}

class NetworkViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var dataImage: NSImageView!
    @IBOutlet weak var imageScale: NSPopUpButton!
    @IBOutlet weak var inputTable: NSTableView!
    @IBOutlet weak var deleteInputButton: NSButton!
    @IBOutlet weak var layersTable: NSTableView!
    @IBOutlet weak var channelTable: NSTableView!
    @IBOutlet weak var operationsTable: NSTableView!
    @IBOutlet weak var deleteDeepLayerButton: NSButton!
    @IBOutlet weak var addChannelButton: NSButton!
    @IBOutlet weak var deleteChannelButton: NSButton!
    @IBOutlet weak var addOperatorButton: NSButton!
    @IBOutlet weak var networkOperatorTypePopUp: NSPopUpButton!
    @IBOutlet weak var editOperatorButton: NSButton!
    @IBOutlet weak var deleteOperatorButton: NSButton!
    @IBOutlet weak var topologyErrorField: NSTextField!
    @IBOutlet weak var generatedTrainingImageRadioButton: NSButton!
    @IBOutlet weak var testImageRadioButton: NSButton!
    @IBOutlet weak var imageDataSelection: NSPopUpButton!
    @IBOutlet weak var trainButton: NSButton!
    @IBOutlet weak var trainProgress: NSProgressIndicator!
    @IBOutlet weak var repeatTrainCheckbox: NSButton!
    @IBOutlet weak var batchSizeTextField: NSTextField!
    @IBOutlet weak var batchSizeStepper: NSStepper!
    @IBOutlet weak var numEpochsTextField: NSTextField!
    @IBOutlet weak var numEpochsStepper: NSStepper!
    @IBOutlet weak var trainingRateField: NSTextField!
    @IBOutlet weak var weightDecayField: NSTextField!
    @IBOutlet weak var outputTable: NSTableView!
    @IBOutlet weak var testButton: NSButton!
    @IBOutlet weak var totalErrorField: NSTextField!
    @IBOutlet weak var classifyPercentField: NSTextField!
    @IBOutlet weak var testPath: NSPathControl!
    @IBOutlet weak var imageClassField: NSTextField!
    @IBOutlet weak var resultingClassField: NSTextField!
    
    //  Settings
    var imageScaledSize = 16
    var requiredDataSources: ImageDataSource = .None
    var imageSourceSelecton : ImageSourceSelecton = .Image
    var addingInput = false
    var addingChannel = false
    var addingOperator = false
    var trainingRate : Float = 0.3
    var weightDecay : Float = 1.0
    var batchSize = 1
    var numEpochs = 100
    var repeatTraining = true
    var autoTest = true
    
    //  Input translation dictionary.  DeepNetwork class doesn't care what types of inputs it has, it just wants labels.  But this application has to know to set them
    var inputDataTypes : [String : ImageDataSource] = [:]
    
    //  Deep network
    var deepNetwork = DeepNetwork()
    
    //  Data
    var currentTestImage : NSImage?
    var currentImageData : ImageData?
    var testFiles : [LabeledImage] = []
    var trainingImageGenerator = LabeledImageGenerator()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  Initialize the operator type popup
        networkOperatorTypePopUp.removeAllItems()
        let operatorTypes = DeepNetworkOperatorType.getAllTypes()
        for type in operatorTypes {
            networkOperatorTypePopUp.addItemWithTitle(type.name)
            networkOperatorTypePopUp.itemWithTitle(type.name)?.tag = type.type.rawValue
        }
        
        //  Load the placeholder test image
        currentTestImage = NSImage(named: "TestImage1")
        if let image = currentTestImage {
            dataImage.image = image
        }
        
        //  Initialize the scale
        imageScale.selectItemWithTag(imageScaledSize)
        
        //  Start with the train images generated
        generatedTrainingImageRadioButton.state = NSOnState
        
        //  Start with the test image viewed
        testImageRadioButton.state = NSOnState
        
        //  Simulate a scale change to get the calculations going
        imageScaleChanged(imageScale);
        
        //  Set the field parameters
        trainingRateField.floatValue = trainingRate
        weightDecayField.floatValue = weightDecay
    }

    @IBAction func imageScaleChanged(sender: NSPopUpButton) {
        imageScaledSize = imageScale.selectedTag()
        if let image = currentTestImage {
            currentImageData = ImageData(image: image, size: imageScaledSize, sources: requiredDataSources)
            
        }
        setDisplayImage()
    }
   
    @IBAction func imageSourceChanged(sender: NSButton) {
        if let newSource = ImageSourceSelecton(rawValue: sender.tag) {
            imageSourceSelecton = newSource
            setDisplayImage()
        }
    }
    
    @IBAction func onImageDataSourceChanged(sender: NSPopUpButton) {
        setDisplayImage()
    }
    
    @IBAction func onTrainRepeatChanged(sender: AnyObject) {
        repeatTraining = (repeatTrainCheckbox.state == NSOnState)
    }
    
    @IBAction func onBatchSizeTextFieldChanged(sender: NSTextField) {
        batchSizeStepper.integerValue = batchSizeTextField.integerValue
        batchSize = batchSizeTextField.integerValue
    }
    
    @IBAction func onBatchSizeStepperChanged(sender: NSStepper) {
        batchSizeTextField.integerValue = batchSizeStepper.integerValue
        batchSize = batchSizeStepper.integerValue
    }
    
    @IBAction func onNumEpochsTextFieldChanged(sender: NSTextField) {
        numEpochsStepper.integerValue = numEpochsTextField.integerValue
        numEpochs = numEpochsTextField.integerValue
    }
    
    @IBAction func onNumEpochsStepperChanged(sender: NSStepper) {
        numEpochsTextField.integerValue = numEpochsStepper.integerValue
        numEpochs = numEpochsStepper.integerValue
    }
    
    @IBAction func onTrainingRateChanged(sender: NSTextField) {
        trainingRate = trainingRateField.floatValue
    }
    
    @IBAction func onWeightDecayChanged(sender: NSTextField) {
        weightDecay = weightDecayField.floatValue
    }
    
    var isTraining = false
    @IBAction func onTrain(sender: NSButton) {
        if (isTraining) {
            //  We are already training, stop now
            trainButton.title = "Stopping"
            isTraining = false
        }
        
        else {
            //  Change the train button to 'stop'
            trainButton.title = "Stop"
            isTraining = true
            trainProgress.maxValue = Double(numEpochs)
            trainProgress.doubleValue = 0.0
            trainProgress.indeterminate = repeatTraining
            trainProgress.startAnimation(self)
            
            //  Start the training in another thread
            dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
                
                //  Train for each of the specified epochs
                self.train()
                self.isTraining = false
                
                dispatch_async(dispatch_get_main_queue()) {
                    //  Set the last training image for viewing
                    self.setDisplayImage()
                    self.imageClassField.integerValue = self.currentTestLabel
                    self.outputTable.reloadData()
                    let resultClass = self.deepNetwork.getResultClass()
                    self.resultingClassField.integerValue = resultClass
                    
                    //  Set the button back to train
                    self.trainButton.title = "Train"
                    self.trainProgress.stopAnimation(self)
                }
            }
        }
    }
    
    var currentTestLabel = 0
    func train() {
        repeat {
            //  Do for each epoch
            for _ in 0..<numEpochs {
                //  Auto-release the image memory - if this is not done we run out!
                autoreleasepool {
                    //  Start the batch
                    deepNetwork.startBatch()
                    
                    //  Do for each training item in the batch
                    for _ in 0..<batchSize {
                        //  See if we have been stopped
                        if (!isTraining) { break }      //  Problem if we 'return' out of the autoreleasepool closure
                        
                        //  Get an image
                        let trainingImage = trainingImageGenerator.getImage()
                        
                        currentTestImage = trainingImage.image
                        currentTestLabel = trainingImage.label
                        
                        //  Get the image data
                        currentImageData = ImageData(image: currentTestImage!, size: imageScaledSize, sources: requiredDataSources)
                        
                        //  Set the inputs into the deep network
                        setNetworkInputs()
                        
                        //  Feed the data forward
                        deepNetwork.feedForward()
                        let resultClass = deepNetwork.getResultClass()
                        resultingClassField.integerValue = resultClass
                        
                        //  Update the output table
                        outputTable.reloadData()
                        
                        //  Backpropagate the error
                        deepNetwork.backPropagate(trainingImage.label)
                    }
                    
                    //  Update the weights based on the training rate and accumulated changes
                    if (isTraining) {
                        deepNetwork.updateWeights(trainingRate, weightDecay: weightDecay)
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.trainProgress.incrementBy(1.0)
                        }
                    }
                }
                if (!isTraining) { return }
            }
            
            //  If auto-testing, test now
            if (self.autoTest) {
                dispatch_sync(dispatch_get_main_queue()) {
                    self.testNetwork(self.testButton)
                }
            }
        } while repeatTraining
    }
    
    func setDisplayImage()
    {
        //  Get the image to be shown
        var image : NSImage?
        switch imageSourceSelecton {
        case .Image:
            image = currentImageData?.getScaledImage()
        case .DataSourceImage:
            image = currentImageData?.getDataSourceImage(ImageDataSource(rawValue: imageDataSelection.selectedTag()))
        case .SelectedItem:
            let layer = layersTable.selectedRow
            if (layer >= 0) {
                let channel = channelTable.selectedRow
                let operationIndex = operationsTable.selectedRow
                image = deepNetwork.GetItemImage(layer, channel: channel, operatorIndex: operationIndex)
            }
        }
        
        //  Scale the image without interpolation
        if let image = image {
            let targetRect = NSRect(x: 0, y: 0, width: 128, height: 128)
            let targetImage = NSImage(size: NSSize(width: 128, height: 128))
            targetImage.lockFocus()
            image.drawInRect(targetRect, fromRect: NSRect(origin: NSZeroPoint, size: image.size), operation: .CompositeCopy, fraction: 1.0, respectFlipped : true,
                hints: [NSImageHintInterpolation : NSImageInterpolation.None.rawValue]);
            targetImage.unlockFocus()
            dataImage.image = targetImage
        }
        else {
            dataImage.image = NSImage(named: "NoData")
        }
    }
    
    @IBAction func onDeleteInput(sender: AnyObject) {
        let row = inputTable.selectedRow
        if (row >= 0) {
            inputDataTypes.removeValueForKey(deepNetwork.inputs[row].inputID)
            deepNetwork.removeInput(row)
            checkDeepNetwork()
        }
        
        //  Update the table
        inputTable.reloadData()
        getRequiredImageData()
    }
    
    func getRequiredImageData()
    {
        var newRequiredDataSources : ImageDataSource = .None
        for input in inputDataTypes {
            newRequiredDataSources.insert(input.1)
        }
        if (newRequiredDataSources != requiredDataSources) {
            requiredDataSources = newRequiredDataSources
            if let image = currentTestImage {
                currentImageData = ImageData(image: image, size: imageScaledSize, sources: requiredDataSources)
                
            }
        }
    }
    
    @IBAction func onAddLayer(sender: AnyObject) {
        //  Add a new layer
        let newLayer = DeepLayer()
        deepNetwork.addLayer(newLayer)
        checkDeepNetwork()
        
        //  Update the table
        layersTable.reloadData()
    }
    
    @IBAction func onDeleteLayer(sender: AnyObject) {
        let row = layersTable.selectedRow
        if (row >= 0) {
            deepNetwork.removeLayer(row)
            checkDeepNetwork()
        }
        
        //  Update the table
        layersTable.reloadData()
    }
    
    @IBAction func onDeleteChannel(sender: AnyObject) {
        let layer = layersTable.selectedRow
        if (layer >= 0) {
            let row = channelTable.selectedRow
            if (row >= 0) {
                deepNetwork.removeChannel(layer, channelIndex: row)
                checkDeepNetwork()
            }
        }
    }
    
    @IBAction func onAddOperator(sender: AnyObject) {
        //  Get the type from the pop-up selection
        if let newOperatorType = DeepNetworkOperatorType(rawValue : networkOperatorTypePopUp.selectedTag()) {
            switch newOperatorType {
            case .Convolution2DOperation:
                addingOperator = true
                performSegueWithIdentifier("configure2DConvolution", sender: self)
                break
            case .PoolingOperation:
                addingOperator = true
                performSegueWithIdentifier("configurePooling", sender: self)
                break
            case .FeedForwardNetOperation:
                addingOperator = true
                performSegueWithIdentifier("configureNeuralNet", sender: self)
                break
            }
            checkDeepNetwork()
        }
    }
    
    @IBAction func onEditOperator(sender: AnyObject) {
    }
    
    @IBAction func onDeleteOperator(sender: AnyObject) {
        let layer = layersTable.selectedRow
        if (layer >= 0) {
            let channel = channelTable.selectedRow
            if (channel >= 0) {
                let row = operationsTable.selectedRow
                if (row >= 0) {
                    deepNetwork.removeNetworkOperator(layer, channelIndex: channel, operatorIndex: row)
                    checkDeepNetwork()
                }
            }
        }
    }
    
    func checkDeepNetwork()
    {
        //  Validate the network
        let errorList = deepNetwork.validateNetwork()
        if let firstError = errorList.first {
            topologyErrorField.stringValue = firstError
        }
        else {
            if (deepNetwork.layers.count > 0) {
                topologyErrorField.stringValue = "Valid network"
                
                //  With a valid network, feedforward the current image for display
                setNetworkInputs()
                deepNetwork.feedForward()
                let resultClass = deepNetwork.getResultClass()
                resultingClassField.integerValue = resultClass
                outputTable.reloadData()
            }
            else {
                topologyErrorField.stringValue = "Empty network"
            }
        }
        
        //  Update the channel view, just in case the sizing changed
        channelTable.reloadData()
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addChannel" {
//!!            let channelVC = segue.destinationController as! ChannelViewController
            addingChannel = true
        }
        if segue.identifier == "addInput" {
//!!            let channelVC = segue.destinationController as! ChannelViewController
            addingInput = true
        }
        if segue.identifier == "configure2DConvolution" {
            let convolutionVC = segue.destinationController as! ConvolutionViewController
            if (addingOperator) {
                convolutionVC.convolution = Convolution2D(usingMatrix: .HorizontalEdge3)
            }
        }
        if segue.identifier == "configurePooling" {
            let poolingVC = segue.destinationController as! PoolingViewController
            if (addingOperator) {
                poolingVC.initialOperation = 0
                poolingVC.initialReduction = 4
            }
        }
        if segue.identifier == "configureNeuralNet" {
//!!            let neuralNetVC = segue.destinationController as! DeepNeuralNetworkController
            if (addingOperator) {
                //  Leave at defaults for now
            }
        }
    }
    
    func inputEditComplete(inputID inputID: String, dataType: ImageDataSource)
    {
        //  Verify the ID is unique
        let idAlreadyUsed = (inputDataTypes[inputID] != nil)
        
        if (addingInput) {
            if (idAlreadyUsed) {
                self.warningAlert("Input ID already in use", information: "Input IDs must be unigue")
            }
            else {
                let size = DeepChannelSize(numDimensions: 2, dimensions: [imageScaledSize, imageScaledSize])
                let newInput = DeepNetworkInput(inputID: inputID, size: size, values: [])
                deepNetwork.addInput(newInput)
                inputDataTypes[inputID] = dataType  //  Store type of data for application
            }
        }
        else {
            //!!
        }
        
        addingInput = false
        inputTable.reloadData()
        getRequiredImageData()
        checkDeepNetwork()
    }
   
    func channelEditComplete(channelID channelID: String, inputSourceID: String)
    {
        let layer = layersTable.selectedRow
        if (layer >= 0) {
            if (addingChannel) {
                let newChannel = DeepChannel(identifier: channelID)
                newChannel.sourceChannelID = inputSourceID
                deepNetwork.addChannel(layer, newChannel: newChannel)
                operationsTable.reloadData()
            }
            else {
                //!!
            }
        }
        
        addingChannel = false
        layersTable.reloadData()
        channelTable.reloadData()
        checkDeepNetwork()
    }
    
    func convolution2DEditComplete(editedConvolution: Convolution2D)
    {
        let layer = layersTable.selectedRow
        if (layer >= 0) {
            let channelIndex = channelTable.selectedRow
            if (channelIndex >= 0) {
                if (addingOperator) {
                    deepNetwork.addNetworkOperator(layer, channelIndex: channelIndex, newOperator: editedConvolution)
                }
                else {
                    //!!
                }
                
                //  Update the table
                checkDeepNetwork()
                operationsTable.reloadData()
            }
        }
    }
    
    func poolingEditComplete(operation: Int, reduction: Int)
    {
        if let operation = PoolingType(rawValue: operation) {
            let layer = layersTable.selectedRow
            if (layer >= 0) {
                let channelIndex = channelTable.selectedRow
                if (channelIndex >= 0) {
                    if (addingOperator) {
                        let pooling = Pooling(type: operation, dimension: 2)
                        pooling.setReductionLevel(0, newLevel: reduction)
                        pooling.setReductionLevel(1, newLevel: reduction)
                        deepNetwork.addNetworkOperator(layer, channelIndex: channelIndex, newOperator: pooling)
                    }
                    else {
//!!            let row = poolingTable.selectedRow
//            let row = 0
//            if (row >= 0) {
//                poolings[row].poolType = operation!
//                let sizeChanged = (poolings[row].reduceLevel == reduction)
//                poolings[row].reduceLevel = reduction
//                //  Get the pooling
//                poolings[row].producePool(convolutions)
//                
//                //  Update any network layer that uses the pooling as the source
//                if sizeChanged { updateLayerInputCounts() }
//                
//                //  layers use image, convolutions and poolings, update them
//                updateLayers()
//            }
                    }
                }
            }
        }
        
        //  Update the table
        checkDeepNetwork()
        operationsTable.reloadData()
    }
    
    func neuralNetworkEditComplete(dimension : Int, numNodes: [Int], activation: NeuralActivationFunction)
    {
        //  Create the size element for the network
        let size = DeepChannelSize(numDimensions: dimension, dimensions: numNodes)
        let layer = layersTable.selectedRow
        if (layer >= 0) {
            if (layer >= 0) {
                let channelIndex = channelTable.selectedRow
                if (channelIndex >= 0) {
                    if (addingOperator) {
                        let neuralNet = DeepNeuralNetwork(activation: activation, size: size)
                        deepNetwork.addNetworkOperator(layer, channelIndex: channelIndex, newOperator: neuralNet)
                    }
                }
            }
        }
        
        //  Update the table
        checkDeepNetwork()
        operationsTable.reloadData()
    }

    @IBAction func selectTestPath(sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose a test configuration file"
        openPanel.beginWithCompletionHandler(){(result:Int) -> Void in
            if (result == NSFileHandlingPanelOKButton) {
                do {
                    //  Show the selected path
                    self.testPath.URL = openPanel.URL
                    
                    //  Load the test files
                    if let path = openPanel.URL?.path {
                        try self.loadTestFiles(path)
                        self.testButton.enabled = true;
                    }
                }
                catch {
                    self.warningAlert("Unable to load test files", information: "Test File Load Error")
                }
            }
        }
    }
    
    //  This function sets the inputs to the deep network from the image data
    func setNetworkInputs()
    {
        if let imageData = currentImageData {
            for (identifier, dataType) in inputDataTypes {
                if let values = imageData.sourceData(dataType) {
                    deepNetwork.setInputValues(identifier, values: values)
                }
            }
        }
    }
    
    func loadTestFiles(path: String) throws  {
        testFiles = []
        
        //  Load the property list with the labels and image file names
        let pList = NSDictionary(contentsOfFile: path)
        if pList == nil { throw ConvolutionReadErrors.fileNotFoundOrNotPList }
        let dictionary : Dictionary = pList! as! Dictionary<String, AnyObject>
        
        //  Iterate through each item
        let array = dictionary["elements"] as! NSArray
        let nspath = NSString(string: path).stringByDeletingLastPathComponent
        for element in array {
            let elementDict = element as! [String: AnyObject]
            if let label = elementDict["result"] as? Int {
                if let imageName = elementDict["file"] as? NSString {
                    let imagePath = nspath + "/" + (imageName as String)
                    if let image = NSImage(byReferencingFile: imagePath) {
                        let labeledImage = LabeledImage(initLabel: label, initImage: image)
                        testFiles.append(labeledImage)
                    }
                }
            }
        }
    }
    
    @IBAction func testNetwork(sender: NSButton) {
        //  Make sure we have test data
        if testFiles.count == 0 { return }
        
        //  Make sure we have a deep network
        if (!deepNetwork.validated) { return }
        
        //  Iterate across all the test images
        var errorSum: Float = 0.0
        var classifyCount = 0
        for testImage in testFiles {
            //  Set the image
            currentTestImage = testImage.image
            
            //  Get the image data
            currentImageData = ImageData(image: currentTestImage!, size: imageScaledSize, sources: requiredDataSources)
            
            //  Set the inputs into the deep network
            setNetworkInputs()
            
            //  Feed the data forward
            deepNetwork.feedForward()
            let resultClass = deepNetwork.getResultClass()
            
            //  Accumulate the error
            errorSum += deepNetwork.getTotalError(testImage.label)
            if (resultClass == testImage.label) { classifyCount += 1 }
        }
        
        totalErrorField.floatValue = errorSum
        classifyPercentField.floatValue = Float(classifyCount) * 100.0 / Float(testFiles.count)
    }
    
    @IBAction func onAutoTestChange(sender: NSButton) {
        autoTest = (sender.state == NSOnState)
    }
    
    //  TableView methods
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int
    {
        if (aTableView == inputTable) {
            return deepNetwork.inputs.count
        }
        else if (aTableView == layersTable) {
            return deepNetwork.layers.count
        }
        else if (aTableView == channelTable) {
            let layer = layersTable.selectedRow
            if (layer < 0) { return 0 }
            return deepNetwork.layers[layer].channels.count
        }
        else if (aTableView == operationsTable) {
            let layer = layersTable.selectedRow
            if (layer < 0) { return 0 }
            let channelIndex = channelTable.selectedRow
            if (channelIndex < 0) { return 0 }
            return deepNetwork.layers[layer].channels[channelIndex].networkOperators.count
        }
        else if (aTableView == outputTable) {
            if let lastLayer = deepNetwork.layers.last {
                if let lastChannel = lastLayer.channels.last {
                    let results = lastChannel.getFinalResult()
                    return results.count
                }
            }
        }
        return 0
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject?
    {
        if (tableView == inputTable) {
            if let columnIdentifier = tableColumn?.identifier {
                let inputID = deepNetwork.inputs[row].inputID
                switch columnIdentifier {
                case "Name":
                    return inputID
                case "Data":
                    if let dataType = inputDataTypes[inputID] {
                        return dataType.getString()
                    }
                    else {
                        return "* Error! *"
                    }
                default:
                    break
                }
            }
        }
        else if (tableView == layersTable) {
            if let columnIdentifier = tableColumn?.identifier {
                switch columnIdentifier {
                    case "Index":
                        return String(row)
                    case "Channels":
                        return String(deepNetwork.layers[row].channels.count)
                    default:
                        break
                }
            }
        }
        else if (tableView == channelTable) {
            let layer = layersTable.selectedRow
            if (layer < 0) { return "" }
            if let columnIdentifier = tableColumn?.identifier {
                switch columnIdentifier {
                case "Index":
                    return String(row)
                case "Identifier":
                    return deepNetwork.layers[layer].channels[row].idString
                case "SourceID":
                    return deepNetwork.layers[layer].channels[row].sourceChannelID
                case "Output":
                    return deepNetwork.layers[layer].channels[row].resultSize.asString()
                default:
                    break
                }
            }
        }
        else if (tableView == operationsTable) {
            let layer = layersTable.selectedRow
            if (layer < 0) { return "" }
            let channelIndex = channelTable.selectedRow
            if (channelIndex < 0) { return "" }
            if let columnIdentifier = tableColumn?.identifier {
                switch columnIdentifier {
                case "Type":
                    return deepNetwork.layers[layer].channels[channelIndex].networkOperators[row].getType().getString()
                case "Details":
                    return deepNetwork.layers[layer].channels[channelIndex].networkOperators[row].getDetails()
                default:
                    break
                }
            }
        }
        else if (tableView == outputTable) {
            if let lastLayer = deepNetwork.layers.last {
                if let lastChannel = lastLayer.channels.last {
                    let results = lastChannel.getFinalResult()
                    if let columnIdentifier = tableColumn?.identifier {
                        switch columnIdentifier {
                        case "Node":
                            return String(row)
                        case "Output":
                            return String(results[row])
                        default:
                            break
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        let tableView = notification.object as! NSTableView
        if (tableView == inputTable) {
            let row = layersTable.selectedRow
            if (row >= 0) {
                deleteInputButton.enabled = true
            }
            else {
                deleteInputButton.enabled = false
            }
        }
        if (tableView == layersTable) {
            let row = layersTable.selectedRow
            if (row >= 0) {
                deleteDeepLayerButton.enabled = true
                addChannelButton.enabled = true
            }
            else {
                deleteDeepLayerButton.enabled = false
                addChannelButton.enabled = false
                deleteChannelButton.enabled = false
                addOperatorButton.enabled = false
                networkOperatorTypePopUp.enabled = false
                editOperatorButton.enabled = false
                deleteOperatorButton.enabled = false
            }
            channelTable.reloadData()
            operationsTable.reloadData()
        }
        else if (tableView == channelTable) {
            let row = channelTable.selectedRow
            if (row >= 0) {
                deleteChannelButton.enabled = true
                addOperatorButton.enabled = true
                networkOperatorTypePopUp.enabled = true
            }
            else {
                deleteChannelButton.enabled = false
                addOperatorButton.enabled = false
                networkOperatorTypePopUp.enabled = false
                editOperatorButton.enabled = false
                deleteOperatorButton.enabled = false
            }
            operationsTable.reloadData()
        }
        else if (tableView == operationsTable) {
            let row = operationsTable.selectedRow
            if (row >= 0) {
                editOperatorButton.enabled = true
                deleteOperatorButton.enabled = true
            }
            else {
                editOperatorButton.enabled = false
                deleteOperatorButton.enabled = false
            }
        }
        
        //  Update the image shown
        setDisplayImage()
    }
    
    //  Save/Load functions
    enum ConvolutionWriteErrors: ErrorType { case failedWriting }
    func saveToFile(path: String) throws
    {
        //  Create a property list of the model
        var modelDictionary = [String: AnyObject]()
        
        //  Add the image scaling size
        modelDictionary["size"] = imageScaledSize
        
        //  Add the input sources
        var inputArray : [[String: AnyObject]] = []
        for input in inputDataTypes {
            var inputDictionary = [String: AnyObject]()
            inputDictionary["id"] = input.0
            inputDictionary["imageData"] = input.1.rawValue
            inputArray.append(inputDictionary)
        }
        modelDictionary["inputs"] = inputArray
        
        //  Add the deep network
        modelDictionary["network"] = deepNetwork.getPersistenceDictionary()
        
        //  Add the training parameters
        modelDictionary["trainingRate"] = trainingRate
        modelDictionary["weightDecay"] = weightDecay
        modelDictionary["batchSize"] = batchSize
        modelDictionary["numEpochs"] = numEpochs
       
        //  Convert to a property list (NSDictionary) and write
        let pList = NSDictionary(dictionary: modelDictionary)
        if !pList.writeToFile(path, atomically: false) { throw ConvolutionWriteErrors.failedWriting }
    }
    
    enum ConvolutionReadErrors: ErrorType { case fileNotFoundOrNotPList; case badFormat }
    func loadFile(path: String) throws
    {
        //  Read the property list
        let pList = NSDictionary(contentsOfFile: path)
        if pList == nil { throw ConvolutionReadErrors.fileNotFoundOrNotPList }
        let dictionary : Dictionary = pList! as! Dictionary<String, AnyObject>
        
        //  Get the image size setting
        let sizeValue = dictionary["size"] as? NSInteger
        if sizeValue == nil { throw ConvolutionReadErrors.badFormat }
        imageScaledSize = sizeValue!
        imageScale.selectItemWithTag(imageScaledSize)
        
        //  Get the input sources
        inputDataTypes = [:]
        let inputArray = dictionary["inputs"] as! NSArray
        for inputDict in inputArray {
            let idValue = inputDict["id"] as? NSString
            if idValue == nil { throw ConvolutionReadErrors.badFormat }
            let dataSourceValue = inputDict["imageData"] as? NSInteger
            if dataSourceValue == nil { throw ConvolutionReadErrors.badFormat }
            let dataSource = ImageDataSource(rawValue: dataSourceValue!)
            inputDataTypes[idValue! as String] = dataSource
        }
        getRequiredImageData()
        
        //  Get the deep network
        let modelDict = dictionary["network"] as? [String: AnyObject]
        if modelDict == nil { throw ConvolutionReadErrors.badFormat }
        if let tempNetwork = DeepNetwork(fromDictionary: modelDict!) {
            deepNetwork = tempNetwork
            checkDeepNetwork()
            
            //  Update all the tables
            inputTable.reloadData()
            layersTable.reloadData()
            channelTable.reloadData()
            operationsTable.reloadData()
        }
        else {
            throw ConvolutionReadErrors.badFormat
        }
        
        //  Training constants
        let rateValue = dictionary["trainingRate"] as? NSNumber
        if rateValue == nil { throw ConvolutionReadErrors.badFormat }
        trainingRate = rateValue!.floatValue
        trainingRateField.floatValue = trainingRate
        let decayValue = dictionary["weightDecay"] as? NSNumber
        if decayValue == nil { throw ConvolutionReadErrors.badFormat }
        weightDecay = decayValue!.floatValue
        weightDecayField.floatValue = weightDecay
        let batchValue = dictionary["batchSize"] as? NSInteger
        if batchValue == nil { throw ConvolutionReadErrors.badFormat }
        batchSize = batchValue!
        batchSizeStepper.integerValue = batchSize
        batchSizeTextField.integerValue = batchSize
        let epochValue = dictionary["numEpochs"] as? NSInteger
        if epochValue == nil { throw ConvolutionReadErrors.badFormat }
        numEpochs = epochValue!
        numEpochsStepper.integerValue = numEpochs
        numEpochsTextField.integerValue = numEpochs
    }
    
    @IBAction func saveDocument(sender: AnyObject) {
        let saveDialog = NSSavePanel();
        saveDialog.title = "Select path for model save"
        saveDialog.beginWithCompletionHandler() { (result: Int) -> Void in
            if result == NSFileHandlingPanelOKButton {
                do {
                    try self.saveToFile(saveDialog.URL!.path!)
                }
                catch {
                    self.warningAlert("Unable to save model", information: "Error writing file")
                }
            }
        }
    }
    
    @IBAction func openDocument(sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose a model file"
        openPanel.beginWithCompletionHandler(){(result:Int) -> Void in
            if (result == NSFileHandlingPanelOKButton) {
                do {
                    try self.loadFile(openPanel.URL!.path!)
                }
                catch {
                    self.warningAlert("Unable to load selected file", information: "File Load Error")
                }
            }
        }
    }
    
    func warningAlert(message: String, information: String) {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = message
        myPopup.informativeText = information
        myPopup.alertStyle = NSAlertStyle.WarningAlertStyle
        myPopup.addButtonWithTitle("OK")
        myPopup.runModal()
    }

}

