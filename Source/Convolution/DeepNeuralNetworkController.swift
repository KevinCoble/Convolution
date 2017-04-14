//
//  DeepNeuralNetworkController
//  Convolution
//
//  Created by Kevin Coble on 2/21/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Cocoa
import AIToolbox

class DeepNeuralNetworkController: NSViewController  {

    @IBOutlet weak var activationFunctionPopup: NSPopUpButton!
    @IBOutlet weak var oneDOutputRadioButton: NSButton!
    @IBOutlet weak var twoDOutputRadioButton: NSButton!
    @IBOutlet weak var threeDOutputRadioButton: NSButton!
    @IBOutlet weak var fourDOutputRadioButton: NSButton!
    @IBOutlet weak var node1TextField: NSTextField!
    @IBOutlet weak var node2TextField: NSTextField!
    @IBOutlet weak var node3TextField: NSTextField!
    @IBOutlet weak var node4TextField: NSTextField!
    @IBOutlet weak var node1Stepper: NSStepper!
    @IBOutlet weak var node2Stepper: NSStepper!
    @IBOutlet weak var node3Stepper: NSStepper!
    @IBOutlet weak var node4Stepper: NSStepper!
    
    //  Inputs
    var dimension = 2
    var numNodes = [16, 16, 1, 1]
    var activation = NeuralActivationFunction.sigmoid
    
    var editSize : DeepChannelSize?
    
    var addingInput = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  Set the initial values into the dialog
        activationFunctionPopup.selectItem(withTag: activation.rawValue)
        
        if let editSize = editSize {
            switch (editSize.numDimensions) {
            case 1:
                onDimensionChange(oneDOutputRadioButton)
            case 2:
                onDimensionChange(twoDOutputRadioButton)
            case 3:
                onDimensionChange(threeDOutputRadioButton)
            case 4:
                onDimensionChange(fourDOutputRadioButton)
            default:
                break
            }
            setFromResultSize(editSize)
        }
    }
    
    func setFromResultSize(_ size: DeepChannelSize)
    {
        //  Set the radio button selection
        var  selectButton = oneDOutputRadioButton
        dimension = size.numDimensions
        if (dimension == 2) { selectButton = twoDOutputRadioButton }
        if (dimension == 3) { selectButton = threeDOutputRadioButton }
        if (dimension == 4) { selectButton = fourDOutputRadioButton }
        selectButton?.state = NSOnState
        
        //  Set the node size amounts
        node1TextField.integerValue = size.dimensions[0]
        node1Stepper.integerValue = size.dimensions[0]
        if (dimension > 1) {
            node2TextField.integerValue = size.dimensions[1]
            node2Stepper.integerValue = size.dimensions[1]
        }
        if (dimension > 2) {
            node3TextField.integerValue = size.dimensions[2]
            node3Stepper.integerValue = size.dimensions[2]
        }
        if (dimension > 3) {
            node4TextField.integerValue = size.dimensions[3]
            node4Stepper.integerValue = size.dimensions[3]
        }
    }
    
    @IBAction func onDimensionChange(_ sender: NSButton) {
        //  Get the dimension from the radio button tag
        dimension = sender.tag
        if (dimension < 4) {
            node4TextField.integerValue = 1
            node4Stepper.integerValue = 1
            node4TextField.isEnabled = false
            node4Stepper.isEnabled = false
        }
        else {
            node4TextField.isEnabled = true
            node4Stepper.isEnabled = true
        }
        if (dimension < 3) {
            node3TextField.integerValue = 1
            node3Stepper.integerValue = 1
            node3TextField.isEnabled = false
            node3Stepper.isEnabled = false
        }
        else {
            node3TextField.isEnabled = true
            node3Stepper.isEnabled = true
        }
        if (dimension < 2) {
            node2TextField.integerValue = 1
            node2Stepper.integerValue = 1
            node2TextField.isEnabled = false
            node2Stepper.isEnabled = false
        }
        else {
            node2TextField.isEnabled = true
            node2Stepper.isEnabled = true
        }
    }
    
    @IBAction func onNode1TextFieldChanged(_ sender: NSTextField) {
        node1Stepper.integerValue = node1TextField.integerValue
    }
    
    @IBAction func onNode1StepperChanged(_ sender: NSStepper) {
        node1TextField.integerValue = node1Stepper.integerValue
    }
    
    @IBAction func onNode2TextFieldChanged(_ sender: NSTextField) {
        node2Stepper.integerValue = node2TextField.integerValue
    }
    
    @IBAction func onNode2StepperChanged(_ sender: NSStepper) {
        node2TextField.integerValue = node2Stepper.integerValue
    }
    
    @IBAction func onNode3TextFieldChanged(_ sender: NSTextField) {
        node3Stepper.integerValue = node3TextField.integerValue
    }
    
    @IBAction func onNode3StepperChanged(_ sender: NSStepper) {
        node3TextField.integerValue = node3Stepper.integerValue
    }
    
    @IBAction func onNode4TextFieldChanged(_ sender: NSTextField) {
        node4Stepper.integerValue = node4TextField.integerValue
    }
    
    @IBAction func onNode4StepperChanged(_ sender: NSStepper) {
        node4TextField.integerValue = node4Stepper.integerValue
    }
    
    @IBAction func onCancel(_ sender: NSButton) {
        presenting?.dismissViewController(self)
    }
    
    @IBAction func onOK(_ sender: NSButton) {
        let networkVC = presenting as! NetworkViewController
        numNodes[0] = node1TextField.integerValue
        numNodes[1] = node2TextField.integerValue
        numNodes[2] = node3TextField.integerValue
        numNodes[3] = node4TextField.integerValue
        activation = NeuralActivationFunction(rawValue: activationFunctionPopup.selectedTag())!
        networkVC.neuralNetworkEditComplete(dimension, numNodes: numNodes, activation: activation)
        presenting?.dismissViewController(self)
    }
}
