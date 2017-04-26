//
//  ViewController.swift
//  Convolution
//
//  Created by Kevin Coble on 2/13/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Cocoa
import AIToolbox

enum ImageSourceSelection : Int {
    case image = 0
    case dataSourceImage
    case selectedItem
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
    @IBOutlet weak var loadedTrainingImageRadioButton: NSButton!
    @IBOutlet weak var trainPath: NSPathControl!
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
    @IBOutlet weak var trainingErrorField: NSTextField!
    @IBOutlet weak var resultingClassField: NSTextField!
    @IBOutlet weak var useGeneratedImagesCheckbox: NSButton!
    @IBOutlet weak var autoTestCheckbox: NSButton!
    
    //  Settings
    var usingGeneratedData = true
    var imageScaledSize = 16
    var requiredDataSources: ImageDataSource = .None
    var imageSourceSelection : ImageSourceSelection = .image
    var addingInput = false
    var addingChannel = false
    var addingOperator = false
    var editOperator : DeepNetworkOperator?
    var trainingRate : Float = 0.3
    var weightDecay : Float = 1.0
    var batchSize = 1
    var numEpochs = 100
    var repeatTraining = true
    var autoTest = true
    var useGeneratedImageForTesting = false
    
    //  Input translation dictionary.  DeepNetwork class doesn't care what types of inputs it has, it just wants labels.  But this application has to know to set them
    var inputDataTypes : [String : ImageDataSource] = [:]
    
    //  Deep network
    var deepNetwork = DeepNetwork()
    
    //  Data
    var currentTestImage : NSImage?
    var currentImageData : ImageData?
    var testFiles : [LabeledImage] = []
    var trainingFiles : [LabeledImage] = []
    var trainingImageGenerator = LabeledImageGenerator(initIncludes: [.redHorizontalLine, .redVerticalLine], initNoise: [], initNumNoiseItems: 0)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  Initialize the operator type popup
        networkOperatorTypePopUp.removeAllItems()
        let operatorTypes = DeepNetworkOperatorType.getAllTypes()
        for type in operatorTypes {
            networkOperatorTypePopUp.addItem(withTitle: type.name)
            networkOperatorTypePopUp.item(withTitle: type.name)?.tag = type.type.rawValue
        }
        
        //  Load the placeholder test image
        currentTestImage = NSImage(named: "TestImage1")
        if let image = currentTestImage {
            dataImage.image = image
        }
        
        //  Initialize the scale
        imageScale.selectItem(withTag: imageScaledSize)
        
        //  Start with the train images generated
        generatedTrainingImageRadioButton.state = NSOnState
        useGeneratedImagesCheckbox.isEnabled = true
        
        //  Start with the test image viewed
        testImageRadioButton.state = NSOnState
        
        //  Simulate a scale change to get the calculations going
        imageScaleChanged(imageScale);
        
        //  Set the field parameters
        trainingRateField.floatValue = trainingRate
        weightDecayField.floatValue = weightDecay
    }
    
    func setImageGenerator(_ newGenerator: LabeledImageGenerator) {
        trainingImageGenerator = newGenerator
    }

    @IBAction func trainingImageSourceChanged(_ sender: NSButton) {
        usingGeneratedData = (sender.tag == 0)
        if (usingGeneratedData) {
            useGeneratedImagesCheckbox.isEnabled = true
        }
        else {
            useGeneratedImageForTesting = false
            useGeneratedImagesCheckbox.isEnabled = false
            self.testButton.isEnabled = false
        }
    }
    
    @IBAction func onLoadTrainImages(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose a training configuration file"
        openPanel.begin(){(result:Int) -> Void in
            if (result == NSFileHandlingPanelOKButton) {
                do {
                    //  Show the selected path
                    self.trainPath.url = openPanel.url
                    
                    //  Load the training files
                    if let path = openPanel.url?.path {
                        try self.loadTrainingFiles(path)
                        self.trainButton.isEnabled = true
                    }
                }
                catch {
                    self.warningAlert("Unable to load training files", information: "Training File Load Error")
                }
            }
        }
    }
    
    
    func loadTrainingFiles(_ path: String) throws  {
        if (!usingGeneratedData) { trainButton.isEnabled = false }
        
        do {
            trainingFiles = try loadFileSet(path)
        }
        catch {
            trainingFiles = []
            throw ConvolutionReadErrors.fileNotFoundOrNotPList
        }
        
        if trainingFiles.count > 0 { trainButton.isEnabled = true }
    }
    
    func loadFileSet(_ path: String) throws ->[LabeledImage] {
        var loadedFiles : [LabeledImage] = []
        
        //  Load the property list with the labels and image file names
        let pList = NSDictionary(contentsOfFile: path)
        if pList == nil { throw ConvolutionReadErrors.fileNotFoundOrNotPList }
        let dictionary : Dictionary = pList! as! Dictionary<String, AnyObject>
        
        //  Check the type
        let fileType = dictionary["type"] as? NSString
        if fileType == nil { throw ConvolutionReadErrors.badFormat }
        if (fileType! != "images" && fileType! != "MNIST" && fileType! != "cifar") {
            throw ConvolutionReadErrors.unrecognizedFormat
        }
        
        //  If a cifar file, get the parameters
        var cifarSize = 32
        var cifarSubclass = false
        if (fileType! == "cifar") {
            if let readCifarSize = dictionary["size"] as? Int {
                cifarSize = readCifarSize
            }
            if let readCifarSubclass = dictionary["subclass"] as? Int {
                if readCifarSubclass > 0 { cifarSubclass = true }
            }
        }
        
        //  Iterate through each item
        let array = dictionary["elements"] as! NSArray
        let nspath = NSString(string: path).deletingLastPathComponent
        for element in array {
            let elementDict = element as! [String: AnyObject]
            if (fileType! == "images") {
                if let label = elementDict["result"] as? Int {
                    if let imageName = elementDict["file"] as? NSString {
                        let imagePath = nspath + "/" + (imageName as String)
                        if let image = NSImage(byReferencingFile: imagePath) {
                            let labeledImage = LabeledImage(initLabel: label, initImage: image)
                            loadedFiles.append(labeledImage)
                        }
                    }
                }
            }
                
            else if (fileType! == "MNIST") {
                if let imagefileName = elementDict["images"] as? NSString {
                    if let labelsfileName = elementDict["labels"] as? NSString {
                        let imagePath = nspath + "/" + (imagefileName as String)
                        let labelPath = nspath + "/" + (labelsfileName as String)
                        if let imageData = NSData(contentsOfFile: imagePath) {
                            if let labelData = NSData(contentsOfFile: labelPath) {
                                var imageOffset = 16
                                var labelOffset = 8
                                //  Check the initial magic words
                                var rng = NSRange(location: 0, length: 4)
                                var magicWord : UInt32 = 0
                                imageData.getBytes(&magicWord, range: rng)
                                if (magicWord.bigEndian != 0x00000803) { throw ConvolutionReadErrors.badFormat }
                                labelData.getBytes(&magicWord, range: rng)
                                if (magicWord.bigEndian != 0x00000801) { throw ConvolutionReadErrors.badFormat }
                                //  Get the counts
                                var imageCount : UInt32 = 0
                                var labelCount : UInt32 = 0
                                rng = NSRange(location: 4, length: 4)
                                imageData.getBytes(&imageCount, range: rng)
                                labelData.getBytes(&labelCount, range: rng)
                                if (imageCount.bigEndian != labelCount.bigEndian) { throw ConvolutionReadErrors.badFormat }
                                //  Get the image size
                                var numRows : UInt32 = 0
                                var numColumns : UInt32 = 0
                                rng = NSRange(location: 8, length: 4)
                                imageData.getBytes(&numRows, range: rng)
                                rng = NSRange(location: 8, length: 4)
                                imageData.getBytes(&numColumns, range: rng)
                                let columns = Int(numColumns.bigEndian)
                                let rows = Int(numRows.bigEndian)
                                var pixel : UInt8 = 0
                                
                                var imagePixels = [UInt8](repeating: 0, count: Int(imageCount.bigEndian) * columns * rows)
                                rng = NSRange(location: imageOffset, length: Int(imageCount.bigEndian) * columns * rows)
                                imageData.getBytes(&imagePixels, range: rng)
                                imageOffset = 0
                                
                                //  Get each labeled image
                                for _ in 0..<imageCount.bigEndian {
                                    //  Get a bitmap representation
                                    if let representation = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: columns, pixelsHigh: rows, bitsPerSample: 8, samplesPerPixel: 1, hasAlpha: false, isPlanar: false, colorSpaceName: NSCalibratedWhiteColorSpace, bytesPerRow: 0, bitsPerPixel: 8) {
                                        let rowBytes = representation.bytesPerRow
                                        let pixels = representation.bitmapData
                                        for y in 0..<columns {
                                            for x in 0..<rows {
                                                pixels?[y * rowBytes + x] = imagePixels[imageOffset]
                                                imageOffset += 1
                                            }
                                        }
                                        rng = NSRange(location: labelOffset, length: 1)
                                        labelData.getBytes(&pixel, range: rng)
                                        labelOffset += 1
                                        
                                        let image = NSImage(size: NSSize(width: columns, height: rows))
                                        image.addRepresentation(representation)
                                        let labeledImage = LabeledImage(initLabel: Int(pixel), initImage: image)
                                        loadedFiles.append(labeledImage)
                                    }
                                }
                                return loadedFiles
                            }
                        }
                    }
                }
                throw ConvolutionReadErrors.badFormat
            }
                
            else if (fileType! == "cifar") {
                if let imagefileName = elementDict["file"] as? NSString {
                    let imagePath = nspath + "/" + (imagefileName as String)
                    if let count = elementDict["count"] as? Int {
                        var numBytes = (cifarSize * cifarSize * 3) + 1
                        if (cifarSubclass) { numBytes += 1 }
                        numBytes *= count
                        if let imageData = NSData(contentsOfFile: imagePath) {
                            var imagePixels = [UInt8](repeating: 0, count: numBytes)
                            let rng = NSRange(location: 0, length: numBytes)
                            imageData.getBytes(&imagePixels, range: rng)
                            var imageOffset = 0
                            var destOffset = 0
                            let planeOffset = cifarSize * cifarSize
                            for _ in 0..<count {
                                var label = Int(imagePixels[imageOffset])
                                if (cifarSubclass) {
                                    label *= 10
                                    imageOffset += 1
                                    label += Int(imagePixels[imageOffset])
                                }
                                imageOffset += 1
                                if let representation = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: cifarSize, pixelsHigh: cifarSize, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSCalibratedRGBColorSpace, bytesPerRow: cifarSize * 4, bitsPerPixel: 32) {
                                    let pixels = representation.bitmapData
                                    for y in 0..<cifarSize {
                                        for x in 0..<cifarSize {
                                            destOffset = (y * cifarSize + x) * 4
                                            pixels?[destOffset] = imagePixels[imageOffset]  //  Red
                                            destOffset += 1
                                            pixels?[destOffset] = imagePixels[imageOffset + planeOffset]  //  Green
                                            destOffset += 1
                                            pixels?[destOffset] = imagePixels[imageOffset + planeOffset + planeOffset]  //  Blue
                                            imageOffset += 1
                                            destOffset += 1
                                            pixels?[destOffset] = 255       //  Alpha
                                        }
                                    }
                                    imageOffset += planeOffset + planeOffset
                                    
                                    let image = NSImage(size: NSSize(width: cifarSize, height: cifarSize))
                                    image.addRepresentation(representation)
                                    let labeledImage = LabeledImage(initLabel: label, initImage: image)
                                    loadedFiles.append(labeledImage)
                                }
                            }
                        }
                    }
                }
            }
        }
        return loadedFiles
    }

    
    @IBAction func imageScaleChanged(_ sender: NSPopUpButton) {
        imageScaledSize = imageScale.selectedTag()
        if let image = currentTestImage {
            currentImageData = ImageData(image: image, size: imageScaledSize, sources: requiredDataSources)
            
        }
        setDisplayImage()
    }
   
    @IBAction func imageSourceChanged(_ sender: NSButton) {
        if let newSource = ImageSourceSelection(rawValue: sender.tag) {
            imageSourceSelection = newSource
            setDisplayImage()
        }
    }
    
    @IBAction func onImageDataSourceChanged(_ sender: NSPopUpButton) {
        setDisplayImage()
    }
    
    @IBAction func onTrainRepeatChanged(_ sender: AnyObject) {
        repeatTraining = (repeatTrainCheckbox.state == NSOnState)
    }
    
    @IBAction func onBatchSizeTextFieldChanged(_ sender: NSTextField) {
        batchSizeStepper.integerValue = batchSizeTextField.integerValue
        batchSize = batchSizeTextField.integerValue
    }
    
    @IBAction func onBatchSizeStepperChanged(_ sender: NSStepper) {
        batchSizeTextField.integerValue = batchSizeStepper.integerValue
        batchSize = batchSizeStepper.integerValue
    }
    
    @IBAction func onNumEpochsTextFieldChanged(_ sender: NSTextField) {
        numEpochsStepper.integerValue = numEpochsTextField.integerValue
        numEpochs = numEpochsTextField.integerValue
    }
    
    @IBAction func onNumEpochsStepperChanged(_ sender: NSStepper) {
        numEpochsTextField.integerValue = numEpochsStepper.integerValue
        numEpochs = numEpochsStepper.integerValue
    }
    
    @IBAction func onTrainingRateChanged(_ sender: NSTextField) {
        trainingRate = trainingRateField.floatValue
    }
    
    @IBAction func onWeightDecayChanged(_ sender: NSTextField) {
        weightDecay = weightDecayField.floatValue
    }
    
    var isTraining = false
    @IBAction func onTrain(_ sender: NSButton) {
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
            trainProgress.isIndeterminate = repeatTraining
            trainProgress.startAnimation(self)
            
            //  Start the training in another thread
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
                
                //  Train for each of the specified epochs
                self.train()
                self.isTraining = false
                
                DispatchQueue.main.async {
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
            var errorSum: Float = 0.0
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
                        var trainingImage : LabeledImage
                        if (usingGeneratedData) {
                            trainingImage = trainingImageGenerator.getImage()
                        }
                        else {
                            trainingImage = randomTrainingImage()
                        }
                        
                        currentTestImage = trainingImage.image
                        currentTestLabel = trainingImage.label
                        
                        //  Get the image data
                        currentImageData = ImageData(image: currentTestImage!, size: imageScaledSize, sources: requiredDataSources)
                        
                        //  Set the inputs into the deep network
                        setNetworkInputs()
                        
                        //  Feed the data forward
                        deepNetwork.feedForward()
                        errorSum += deepNetwork.getTotalError(trainingImage.label)
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
                        
                        DispatchQueue.main.async {
                            self.trainProgress.increment(by: 1.0)
                        }
                    }
                }
                if (!isTraining) { return }
            }
            
            //  Write the total error to the display
            DispatchQueue.main.sync {
                trainingErrorField.floatValue = errorSum
            }
            
            //  If auto-testing, test now
            if (self.autoTest) {
                DispatchQueue.main.sync {
                    self.testNetwork(self.testButton)
                }
            }
        } while repeatTraining
    }
    
    func randomTrainingImage() -> LabeledImage
    {
        let index = Int(arc4random_uniform(UInt32(trainingFiles.count)))
        
        return trainingFiles[index]
    }
    
    func setDisplayImage()
    {
        //  Get the image to be shown
        var image : NSImage?
        switch imageSourceSelection {
        case .image:
            image = currentImageData?.getScaledImage()
        case .dataSourceImage:
            image = currentImageData?.getDataSourceImage(ImageDataSource(rawValue: imageDataSelection.selectedTag()))
        case .selectedItem:
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
            image.draw(in: targetRect, from: NSRect(origin: NSZeroPoint, size: image.size), operation: .copy, fraction: 1.0, respectFlipped : true,
                hints: [NSImageHintInterpolation : NSImageInterpolation.none.rawValue]);
            targetImage.unlockFocus()
            dataImage.image = targetImage
        }
        else {
            dataImage.image = NSImage(named: "NoData")
        }
    }
    
    @IBAction func onDeleteInput(_ sender: AnyObject) {
        let row = inputTable.selectedRow
        if (row >= 0) {
            inputDataTypes.removeValue(forKey: deepNetwork.getInput(atIndex: row).inputID)
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
    
    @IBAction func onAddLayer(_ sender: AnyObject) {
        //  Add a new layer
        let newLayer = DeepLayer()
        deepNetwork.addLayer(newLayer)
        checkDeepNetwork()
        
        //  Update the table
        layersTable.reloadData()
    }
    
    @IBAction func onDeleteLayer(_ sender: AnyObject) {
        let row = layersTable.selectedRow
        if (row >= 0) {
            deepNetwork.removeLayer(row)
            checkDeepNetwork()
        }
        
        //  Update the table
        layersTable.reloadData()
    }
    
    @IBAction func onDeleteChannel(_ sender: AnyObject) {
        let layer = layersTable.selectedRow
        if (layer >= 0) {
            let row = channelTable.selectedRow
            if (row >= 0) {
                deepNetwork.removeChannel(layer, channelIndex: row)
                checkDeepNetwork()
            }
        }
    }
    
    @IBAction func onAddOperator(_ sender: AnyObject) {
        //  Get the type from the pop-up selection
        if let newOperatorType = DeepNetworkOperatorType(rawValue : networkOperatorTypePopUp.selectedTag()) {
            switch newOperatorType {
            case .convolution2DOperation:
                addingOperator = true
                performSegue(withIdentifier: "configure2DConvolution", sender: self)
                break
            case .poolingOperation:
                addingOperator = true
                performSegue(withIdentifier: "configurePooling", sender: self)
                break
            case .feedForwardNetOperation:
                addingOperator = true
                performSegue(withIdentifier: "configureNeuralNet", sender: self)
                break
            case .nonLinearityOperation:
                addingOperator = true
                performSegue(withIdentifier: "configureNonLinearity", sender: self)
                break
            }
            checkDeepNetwork()
        }
    }
    
    @IBAction func onEditOperator(_ sender: AnyObject) {
        //  Get the selected operator
        let layer = layersTable.selectedRow
        if (layer >= 0) {
            let channel = channelTable.selectedRow
            if (channel >= 0) {
                let row = operationsTable.selectedRow
                if (row >= 0) {
                    if let networkOperator = deepNetwork.getNetworkOperator(layer, channelIndex: channel, operatorIndex: row) {
                        editOperator = networkOperator
                        addingOperator = false
                        switch (networkOperator.getType()) {
                        case .convolution2DOperation:
                            performSegue(withIdentifier: "configure2DConvolution", sender: self)
                            break
                        case .poolingOperation:
                            performSegue(withIdentifier: "configurePooling", sender: self)
                            break
                        case .feedForwardNetOperation:
                            performSegue(withIdentifier: "configureNeuralNet", sender: self)
                            break
                        case .nonLinearityOperation:
                            performSegue(withIdentifier: "configureNonLinearity", sender: self)
                            break
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func onDeleteOperator(_ sender: AnyObject) {
        let layer = layersTable.selectedRow
        if (layer >= 0) {
            let channel = channelTable.selectedRow
            if (channel >= 0) {
                let row = operationsTable.selectedRow
                if (row >= 0) {
                    deepNetwork.removeNetworkOperator(layer, channelIndex: channel, operatorIndex: row)
                    operationsTable.reloadData()
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
            if (deepNetwork.numLayers > 0) {
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
    
    @IBAction func initializeDeepNetwork(_ sender: AnyObject)
    {
        //  Have the network re-randomize the any learning parameters
        deepNetwork.initializeParameters()
    }
    
    @IBAction func gradientCheckDeepNetwork(_ sender: AnyObject)
    {
        //  Clear the gradient accumulations
        deepNetwork.startBatch()
        
        //  Get a training example
        let trainingImage = trainingImageGenerator.getImage()
        
        //  Get the image data
        currentImageData = ImageData(image: trainingImage.image!, size: imageScaledSize, sources: requiredDataSources)
        
        //  Set the inputs into the deep network
        setNetworkInputs()
        
        //  Feed the data forward
        deepNetwork.feedForward()
        
        //  Backpropagate the error
        deepNetwork.backPropagate(trainingImage.label)
        
        //  Have the network do a gradient check
        if deepNetwork.gradientCheck(ε: 1.0E-04, Δ: 0.01)
        {
            infoAlert("Gradient Check Successful", information: "Gradient Check")
        }
        else {
            warningAlert("Gradient Check Unsuccessful", information: "Gradient Check")
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "addChannel" {
            addingChannel = true
        }
        if segue.identifier == "addInput" {
            addingInput = true
        }
        if segue.identifier == "configure2DConvolution" {
            let convolutionVC = segue.destinationController as! ConvolutionViewController
            if (addingOperator) {
                convolutionVC.convolution = Convolution2D(usingMatrix: .horizontalEdge3)
            }
            else {
                convolutionVC.convolution = (editOperator as! Convolution2D)
            }
        }
        if segue.identifier == "configurePooling" {
            let poolingVC = segue.destinationController as! PoolingViewController
            if (addingOperator) {
                poolingVC.initialOperation = 0
                poolingVC.initialReduction = 4
            }
            else {
                if let pool = editOperator as? Pooling {
                    poolingVC.initialOperation = pool.poolType.rawValue
                    poolingVC.initialReduction = pool.reductionLevels[0]
                }
            }
        }
        if segue.identifier == "configureNeuralNet" {
            if (addingOperator) {
                //  Leave at defaults for now
            }
            else {
                let neuralNetVC = segue.destinationController as! DeepNeuralNetworkController
                if let net = editOperator as? DeepNeuralNetwork {
                    neuralNetVC.editSize = net.getResultSize()
                }
            }
        }
        if segue.identifier == "configureNonLinearity" {
            let neuralNetVC = segue.destinationController as! DeepNeuralNetworkController
            neuralNetVC.activationOnly = true
            if (addingOperator) {
                //  Leave at defaults for now
            }
            else {
                if let nonLinearity = editOperator as? DeepNonLinearity {
                    neuralNetVC.activation = nonLinearity.activation
                }
            }
        }
        if segue.identifier == "imageGenerator" {
            let imageGeneratorVC = segue.destinationController as! LabeledImageGeneratorViewController
            imageGeneratorVC.generator = trainingImageGenerator
        }
    }
    
    func inputEditComplete(inputID: String, dataType: ImageDataSource)
    {
        //  Verify the ID is unique
        let idAlreadyUsed = (inputDataTypes[inputID] != nil)
        
        if (addingInput) {
            if (idAlreadyUsed) {
                self.warningAlert("Input ID already in use", information: "Input IDs must be unigue")
            }
            else {
                let size = DeepChannelSize(dimensionCount: 2, dimensionValues: [imageScaledSize, imageScaledSize])
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
   
    func channelEditComplete(channelID: String, inputSourceIDs: [String])
    {
        let layer = layersTable.selectedRow
        if (layer >= 0) {
            if (addingChannel) {
                let newChannel = DeepChannel(identifier: channelID, sourceChannels: inputSourceIDs)
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
    
    func convolution2DEditComplete(_ editedConvolution: Convolution2D)
    {
        let layer = layersTable.selectedRow
        if (layer >= 0) {
            let channelIndex = channelTable.selectedRow
            if (channelIndex >= 0) {
                if (addingOperator) {
                    deepNetwork.addNetworkOperator(layer, channelIndex: channelIndex, newOperator: editedConvolution)
                }
                else {
                    let row = operationsTable.selectedRow
                    if (row >= 0) {
                        deepNetwork.replaceNetworkOperator(layer, channelIndex: channelIndex, operatorIndex: row, newOperator: editedConvolution)
                    }
                }
                
                //  Update the table
                checkDeepNetwork()
                operationsTable.reloadData()
            }
        }
    }
    
    func poolingEditComplete(_ operation: Int, reduction: Int)
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
                        let poolingOperator = editOperator as! Pooling
                        poolingOperator.setReductionLevel(0, newLevel: reduction)
                        poolingOperator.setReductionLevel(1, newLevel: reduction)
                    }
                }
            }
        }
        
        //  Update the table
        checkDeepNetwork()
        operationsTable.reloadData()
    }
    
    func neuralNetworkEditComplete(_ dimension : Int, numNodes: [Int], activation: NeuralActivationFunction)
    {
        //  Create the size element for the network
        let size = DeepChannelSize(dimensionCount: dimension, dimensionValues: numNodes)
        let layer = layersTable.selectedRow
        if (layer >= 0) {
            if (layer >= 0) {
                let channelIndex = channelTable.selectedRow
                if (channelIndex >= 0) {
                    if (addingOperator) {
                        let neuralNet = DeepNeuralNetwork(activation: activation, size: size)
                        deepNetwork.addNetworkOperator(layer, channelIndex: channelIndex, newOperator: neuralNet)
                    }
                    else {
                        let row = operationsTable.selectedRow
                        if (row >= 0) {
                            let neuralNet = DeepNeuralNetwork(activation: activation, size: size)
                            deepNetwork.replaceNetworkOperator(layer, channelIndex: channelIndex, operatorIndex: row, newOperator: neuralNet)
                        }
                    }
                }
            }
        }
        
        //  Update the table
        checkDeepNetwork()
        operationsTable.reloadData()
    }
    
    func nonLinearityEditComplete(activation: NeuralActivationFunction) {
        let layer = layersTable.selectedRow
        if (layer >= 0) {
            if (layer >= 0) {
                let channelIndex = channelTable.selectedRow
                if (channelIndex >= 0) {
                    if (addingOperator) {
                        let nonLinearity = DeepNonLinearity(activation: activation)
                        deepNetwork.addNetworkOperator(layer, channelIndex: channelIndex, newOperator: nonLinearity)
                    }
                    else {
                        let row = operationsTable.selectedRow
                        if (row >= 0) {
                            let nonLinearity = DeepNonLinearity(activation: activation)
                            deepNetwork.replaceNetworkOperator(layer, channelIndex: channelIndex, operatorIndex: row, newOperator: nonLinearity)
                        }
                    }
                }
            }
        }
        
        //  Update the table
        checkDeepNetwork()
        operationsTable.reloadData()
    }

    @IBAction func selectTestPath(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose a test configuration file"
        openPanel.begin(){(result:Int) -> Void in
            if (result == NSFileHandlingPanelOKButton) {
                do {
                    //  Show the selected path
                    self.testPath.url = openPanel.url
                    
                    //  Load the test files
                    if let path = openPanel.url?.path {
                        try self.loadTestFiles(path)
                        self.testButton.isEnabled = true
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
    
    func loadTestFiles(_ path: String) throws  {
        if (!useGeneratedImageForTesting) { testButton.isEnabled = false }
        
        do {
            testFiles = try loadFileSet(path)
        }
        catch {
            testFiles = []
            throw ConvolutionReadErrors.fileNotFoundOrNotPList
        }
        
        if testFiles.count > 0 { testButton.isEnabled = true }
    }
    
    @IBAction func testNetwork(_ sender: NSButton) {
        //  Make sure we have a deep network
        if (!deepNetwork.isValidated) { return }
        
        var errorSum: Float = 0.0
        var classifyCount = 0
        var totalTestFiles = 1
        if (!useGeneratedImageForTesting) {
            //  Make sure we have test data
            totalTestFiles = testFiles.count
            if (totalTestFiles == 0 ){ return }
            
            //  Iterate across all the test images
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
        }
        else {
            //  Generate 100 images for testing
            totalTestFiles = 100
            for _ in 0..<totalTestFiles {
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
                
                //  Accumulate the error
                errorSum += deepNetwork.getTotalError(trainingImage.label)
                if (resultClass == trainingImage.label) { classifyCount += 1 }
            }
        }
        
        totalErrorField.floatValue = errorSum
        classifyPercentField.floatValue = Float(classifyCount) * 100.0 / Float(totalTestFiles)
    }
    
    @IBAction func onAutoTestChange(_ sender: NSButton) {
        autoTest = (sender.state == NSOnState)
    }
    
    @IBAction func onUseGeneratedImageChange(_ sender: NSButton) {
        useGeneratedImageForTesting = (sender.state == NSOnState)
        if useGeneratedImageForTesting {
            self.testButton.isEnabled = true
        }
    }
    
    //  TableView methods
    func numberOfRows(in aTableView: NSTableView) -> Int
    {
        if (aTableView == inputTable) {
            return deepNetwork.numInputs
        }
        else if (aTableView == layersTable) {
            return deepNetwork.numLayers
        }
        else if (aTableView == channelTable) {
            let layerIndex = layersTable.selectedRow
            if (layerIndex < 0 || layerIndex >= deepNetwork.numLayers) { return 0 }
            let layer = deepNetwork.getLayer(atIndex: layerIndex)
            return layer.numChannels
        }
        else if (aTableView == operationsTable) {
            let layerIndex = layersTable.selectedRow
            if (layerIndex < 0 || layerIndex > deepNetwork.numLayers) { return 0 }
            let layer = deepNetwork.getLayer(atIndex: layerIndex)
            let channelIndex = channelTable.selectedRow
            if (channelIndex < 0 || channelIndex >= layer.numChannels) { return 0 }
            let channel = layer.getChannel(atIndex: channelIndex)
            return channel.numOperators
        }
        else if (aTableView == outputTable) {
            if (deepNetwork.numLayers <= 0) { return 0 }
            let lastLayer = deepNetwork.getLayer(atIndex: deepNetwork.numLayers-1)
            if (lastLayer.numChannels <= 0) { return 0 }
            let lastChannel = lastLayer.getChannel(atIndex: lastLayer.numChannels-1)
            let results = lastChannel.getFinalResult()
            return results.count
        }
        return 0
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any?
    {
        if (tableView == inputTable) {
            if let columnIdentifier = tableColumn?.identifier {
                let input = deepNetwork.getInput(atIndex: row)
                let inputID = input.inputID
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
                        let layer = deepNetwork.getLayer(atIndex: row)
                        return String(layer.numChannels)
                    default:
                        break
                }
            }
        }
        else if (tableView == channelTable) {
            let layerIndex = layersTable.selectedRow
            if (layerIndex < 0 || layerIndex >= deepNetwork.numLayers) { return "" }
            let layer = deepNetwork.getLayer(atIndex: layerIndex)
            let channel = layer.getChannel(atIndex: row)
            if let columnIdentifier = tableColumn?.identifier {
                switch columnIdentifier {
                case "Index":
                    return String(row)
                case "Identifier":
                    return channel.idString
                case "SourceID":
                    var string = channel.sourceChannelIDs[0]
                    if (channel.sourceChannelIDs.count > 1) {
                        for index in 1..<channel.sourceChannelIDs.count {
                            string += ", " + channel.sourceChannelIDs[index]
                        }
                    }
                    return string
                case "Output":
                    return channel.resultSize.asString()
                default:
                    break
                }
            }
        }
        else if (tableView == operationsTable) {
            let layerIndex = layersTable.selectedRow
            if (layerIndex < 0 || layerIndex >= deepNetwork.numLayers) { return "" }
            let layer = deepNetwork.getLayer(atIndex: layerIndex)
            let channelIndex = channelTable.selectedRow
            if (channelIndex < 0 || channelIndex >= layer.numChannels) { return "" }
            let channel = layer.getChannel(atIndex: channelIndex)
            if let networkOperator = channel.getNetworkOperator(row) {
                if let columnIdentifier = tableColumn?.identifier {
                    switch columnIdentifier {
                    case "Type":
                        return networkOperator.getType().getString()
                    case "Details":
                        return networkOperator.getDetails()
                    default:
                        break
                    }
                }
            }
            else {
                return ""
            }
        }
        else if (tableView == outputTable) {
            if (deepNetwork.numLayers <= 0) { return 0 }
            let lastLayer = deepNetwork.getLayer(atIndex: deepNetwork.numLayers-1)
            if (lastLayer.numChannels <= 0) { return 0 }
            let lastChannel = lastLayer.getChannel(atIndex: lastLayer.numChannels-1)
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
        
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let tableView = notification.object as! NSTableView
        if (tableView == inputTable) {
            let row = layersTable.selectedRow
            if (row >= 0) {
                deleteInputButton.isEnabled = true
            }
            else {
                deleteInputButton.isEnabled = false
            }
        }
        if (tableView == layersTable) {
            let row = layersTable.selectedRow
            if (row >= 0) {
                deleteDeepLayerButton.isEnabled = true
                addChannelButton.isEnabled = true
            }
            else {
                deleteDeepLayerButton.isEnabled = false
                addChannelButton.isEnabled = false
                deleteChannelButton.isEnabled = false
                addOperatorButton.isEnabled = false
                networkOperatorTypePopUp.isEnabled = false
                editOperatorButton.isEnabled = false
                deleteOperatorButton.isEnabled = false
            }
            channelTable.reloadData()
            operationsTable.reloadData()
        }
        else if (tableView == channelTable) {
            let row = channelTable.selectedRow
            if (row >= 0) {
                deleteChannelButton.isEnabled = true
                addOperatorButton.isEnabled = true
                networkOperatorTypePopUp.isEnabled = true
            }
            else {
                deleteChannelButton.isEnabled = false
                addOperatorButton.isEnabled = false
                networkOperatorTypePopUp.isEnabled = false
                editOperatorButton.isEnabled = false
                deleteOperatorButton.isEnabled = false
            }
            operationsTable.reloadData()
        }
        else if (tableView == operationsTable) {
            let row = operationsTable.selectedRow
            if (row >= 0) {
                editOperatorButton.isEnabled = true
                deleteOperatorButton.isEnabled = true
            }
            else {
                editOperatorButton.isEnabled = false
                deleteOperatorButton.isEnabled = false
            }
        }
        
        //  Update the image shown
        setDisplayImage()
    }
    
    //  Save/Load functions
    enum ConvolutionWriteErrors: Error { case failedWriting }
    func saveToFile(_ path: String) throws
    {
        //  Create a property list of the model
        var modelDictionary = [String: AnyObject]()
        
        //  Add the image scaling size
        modelDictionary["size"] = imageScaledSize as AnyObject?
        
        //  Add the test image generator settings
        modelDictionary["trainGeneratorSettings"] = trainingImageGenerator.getPersistenceDictionary() as AnyObject?
        
        //  Add the input sources
        var inputArray : [[String: AnyObject]] = []
        for input in inputDataTypes {
            var inputDictionary = [String: AnyObject]()
            inputDictionary["id"] = input.0 as AnyObject?
            inputDictionary["imageData"] = input.1.rawValue as AnyObject?
            inputArray.append(inputDictionary)
        }
        modelDictionary["inputs"] = inputArray as AnyObject?
        
        //  Add the deep network
        modelDictionary["network"] = deepNetwork.getPersistenceDictionary() as AnyObject?
        
        //  Add the training parameters
        modelDictionary["trainingRate"] = trainingRate as AnyObject?
        modelDictionary["weightDecay"] = weightDecay as AnyObject?
        modelDictionary["batchSize"] = batchSize as AnyObject?
        modelDictionary["numEpochs"] = numEpochs as AnyObject?
        let genImageAsInt = usingGeneratedData ? 1 : 0
        modelDictionary["generatedImages"] = genImageAsInt as AnyObject?
        let repeatTrainAsInt = repeatTraining ? 1 : 0
        modelDictionary["repeatTraining"] = repeatTrainAsInt as AnyObject?
        if let path = trainPath.url?.path {
            modelDictionary["trainPath"] = path as AnyObject?
        }
        
        //  Add the testing settings
        if let path = testPath.url?.path {
            modelDictionary["testPath"] = path as AnyObject?
        }
        let useGeneratedDataAsInt = useGeneratedImageForTesting ? 1 : 0
        modelDictionary["useGenTestImages"] = useGeneratedDataAsInt as AnyObject?
        let autoTestAsInt = autoTest ? 1 : 0
        modelDictionary["autoTest"] = autoTestAsInt as AnyObject?
       
        //  Convert to a property list (NSDictionary) and write
        let pList = NSDictionary(dictionary: modelDictionary)
        if !pList.write(toFile: path, atomically: false) { throw ConvolutionWriteErrors.failedWriting }
    }
    
    enum ConvolutionReadErrors: Error { case fileNotFoundOrNotPList; case badFormat ; case unrecognizedFormat}
    func loadFile(_ path: String) throws
    {
        //  Read the property list
        let pList = NSDictionary(contentsOfFile: path)
        if pList == nil { throw ConvolutionReadErrors.fileNotFoundOrNotPList }
        let dictionary : Dictionary = pList! as! Dictionary<String, AnyObject>
        
        //  Get the image size setting
        let sizeValue = dictionary["size"] as? NSInteger
        if sizeValue == nil { throw ConvolutionReadErrors.badFormat }
        imageScaledSize = sizeValue!
        imageScale.selectItem(withTag: imageScaledSize)
        
        //  Read the image generator settings
        let trainingImageGeneratorDict = dictionary["trainGeneratorSettings"] as? [String: AnyObject]
        if trainingImageGeneratorDict == nil { throw ConvolutionReadErrors.badFormat }
        let tempGen = LabeledImageGenerator(fromDictionary: trainingImageGeneratorDict!)
        if tempGen == nil { throw ConvolutionReadErrors.badFormat }
        trainingImageGenerator = tempGen!
        
        //  Get the input sources
        inputDataTypes = [:]
        let inputArray = dictionary["inputs"] as! NSArray
        for input in inputArray {
            let inputDict = input as? [String : AnyObject]
            if inputDict == nil { throw ConvolutionReadErrors.badFormat }
            let idValue = inputDict!["id"] as? NSString
            if idValue == nil { throw ConvolutionReadErrors.badFormat }
            let dataSourceValue = inputDict!["imageData"] as? NSInteger
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
        if let path = dictionary["trainPath"] as? NSString {
            trainPath.url = URL(fileURLWithPath: path as String)
            //  Load the training files
            do {
                if let path = trainPath.url?.path {
                    try self.loadTrainingFiles(path)
                    trainButton.isEnabled = true
                }
            }
            catch {
                trainButton.isEnabled = false
            }
        }
        let genImageAsInt = dictionary["generatedImages"] as? NSInteger
        if genImageAsInt == nil { throw ConvolutionReadErrors.badFormat }
        if (genImageAsInt! != 0) {
            usingGeneratedData = true
            generatedTrainingImageRadioButton.state =  NSOnState
            trainButton.isEnabled = true
        }
        else {
            usingGeneratedData = false
            loadedTrainingImageRadioButton.state = NSOnState
        }
        let repeatTrainAsInt = dictionary["repeatTraining"] as? NSInteger
        if repeatTrainAsInt == nil { throw ConvolutionReadErrors.badFormat }
        if (genImageAsInt! != 0) {
            repeatTraining = true
            repeatTrainCheckbox.state = NSOnState
        }
        else {
            repeatTraining = false
            repeatTrainCheckbox.state = NSOffState
        }
        
        //  Testing settings
        if let path = dictionary["testPath"] as? NSString {
            testPath.url = URL(fileURLWithPath: path as String)
            //  Attempt to load the training files
            do {
                if let path = testPath.url?.path {
                    try self.loadTestFiles(path)
                }
                testButton.isEnabled = true
            }
            catch {
                testButton.isEnabled = false
            }
        }
        let useGeneratedDataAsInt = dictionary["useGenTestImages"] as? NSInteger
        if useGeneratedDataAsInt == nil { throw ConvolutionReadErrors.badFormat }
        if (useGeneratedDataAsInt! != 0) {
            useGeneratedImageForTesting = true
            useGeneratedImagesCheckbox.state = NSOnState
            self.testButton.isEnabled = true
        }
        else {
            useGeneratedImageForTesting = false
            useGeneratedImagesCheckbox.state = NSOffState
            if (trainingFiles.count <= 0) { self.testButton.isEnabled = false }
        }
        let autoTestAsInt = dictionary["autoTest"] as? NSInteger
        if autoTestAsInt == nil { throw ConvolutionReadErrors.badFormat }
        autoTest = (autoTestAsInt != 0)
        autoTestCheckbox.state = autoTest ? NSOnState : NSOffState
    }
    
    @IBAction func saveDocument(_ sender: AnyObject) {
        let saveDialog = NSSavePanel();
        saveDialog.title = "Select path for model save"
        saveDialog.begin() { (result: Int) -> Void in
            if result == NSFileHandlingPanelOKButton {
                do {
                    try self.saveToFile(saveDialog.url!.path)
                }
                catch {
                    self.warningAlert("Unable to save model", information: "Error writing file")
                }
            }
        }
    }
    
    @IBAction func openDocument(_ sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose a model file"
        openPanel.begin(){(result:Int) -> Void in
            if (result == NSFileHandlingPanelOKButton) {
                do {
                    try self.loadFile(openPanel.url!.path)
                }
                catch {
                    self.warningAlert("Unable to load selected file", information: "File Load Error")
                }
            }
        }
    }
    
    func warningAlert(_ message: String, information: String) {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = message
        myPopup.informativeText = information
        myPopup.alertStyle = NSAlertStyle.warning
        myPopup.addButton(withTitle: "OK")
        myPopup.runModal()
    }
    
    func infoAlert(_ message: String, information: String) {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = message
        myPopup.informativeText = information
        myPopup.alertStyle = NSAlertStyle.informational
        myPopup.addButton(withTitle: "OK")
        myPopup.runModal()
    }

}

