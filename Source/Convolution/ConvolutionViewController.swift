//
//  ConvolutionViewController.swift
//  Convolution
//
//  Created by Kevin Coble on 2/16/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Cocoa

class ConvolutionViewController: NSViewController, NSTextFieldDelegate {
    
    @IBOutlet weak var matrixType: NSPopUpButton!
    
    @IBOutlet weak var HorzLabelM3: NSTextField!
    @IBOutlet weak var HorzLabelM2: NSTextField!
    @IBOutlet weak var HorzLabel2: NSTextField!
    @IBOutlet weak var HorzLabel3: NSTextField!
    @IBOutlet weak var VertLabelM3: NSTextField!
    @IBOutlet weak var VertLabelM2: NSTextField!
    @IBOutlet weak var VertLabel2: NSTextField!
    @IBOutlet weak var VertLabel3: NSTextField!
    @IBOutlet weak var EntryM3M3: NSTextField!
    @IBOutlet weak var EntryM3M2: NSTextField!
    @IBOutlet weak var EntryM3M1: NSTextField!
    @IBOutlet weak var EntryM30: NSTextField!
    @IBOutlet weak var EntryM31: NSTextField!
    @IBOutlet weak var EntryM32: NSTextField!
    @IBOutlet weak var EntryM33: NSTextField!
    @IBOutlet weak var EntryM2M3: NSTextField!
    @IBOutlet weak var EntryM2M2: NSTextField!
    @IBOutlet weak var EntryM2M1: NSTextField!
    @IBOutlet weak var EntryM20: NSTextField!
    @IBOutlet weak var EntryM21: NSTextField!
    @IBOutlet weak var EntryM22: NSTextField!
    @IBOutlet weak var EntryM23: NSTextField!
    @IBOutlet weak var EntryM1M3: NSTextField!
    @IBOutlet weak var EntryM1M2: NSTextField!
    @IBOutlet weak var EntryM1M1: NSTextField!
    @IBOutlet weak var EntryM10: NSTextField!
    @IBOutlet weak var EntryM11: NSTextField!
    @IBOutlet weak var EntryM12: NSTextField!
    @IBOutlet weak var EntryM13: NSTextField!
    @IBOutlet weak var Entry0M3: NSTextField!
    @IBOutlet weak var Entry0M2: NSTextField!
    @IBOutlet weak var Entry0M1: NSTextField!
    @IBOutlet weak var Entry00: NSTextField!
    @IBOutlet weak var Entry01: NSTextField!
    @IBOutlet weak var Entry02: NSTextField!
    @IBOutlet weak var Entry03: NSTextField!
    @IBOutlet weak var Entry1M3: NSTextField!
    @IBOutlet weak var Entry1M2: NSTextField!
    @IBOutlet weak var Entry1M1: NSTextField!
    @IBOutlet weak var Entry10: NSTextField!
    @IBOutlet weak var Entry11: NSTextField!
    @IBOutlet weak var Entry12: NSTextField!
    @IBOutlet weak var Entry13: NSTextField!
    @IBOutlet weak var Entry2M3: NSTextField!
    @IBOutlet weak var Entry2M2: NSTextField!
    @IBOutlet weak var Entry2M1: NSTextField!
    @IBOutlet weak var Entry20: NSTextField!
    @IBOutlet weak var Entry21: NSTextField!
    @IBOutlet weak var Entry22: NSTextField!
    @IBOutlet weak var Entry23: NSTextField!
    @IBOutlet weak var Entry3M3: NSTextField!
    @IBOutlet weak var Entry3M2: NSTextField!
    @IBOutlet weak var Entry3M1: NSTextField!
    @IBOutlet weak var Entry30: NSTextField!
    @IBOutlet weak var Entry31: NSTextField!
    @IBOutlet weak var Entry32: NSTextField!
    @IBOutlet weak var Entry33: NSTextField!
    
    var currentMatrixType : Convolution2DMatrix = .Custom3
    var entryMatrix : [[NSTextField!]] = [[]]
    var fillingEntries = false
    
    var convolution : Convolution2D?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  Set up the matrix of entry fields
        entryMatrix = [[EntryM3M3, EntryM3M2, EntryM3M1, EntryM30, EntryM31, EntryM32, EntryM33],
                       [EntryM2M3, EntryM2M2, EntryM2M1, EntryM20, EntryM21, EntryM22, EntryM23],
                       [EntryM1M3, EntryM1M2, EntryM1M1, EntryM10, EntryM11, EntryM12, EntryM13],
                       [Entry0M3,  Entry0M2,  Entry0M1,  Entry00,  Entry01,  Entry02,  Entry03],
                       [Entry1M3,  Entry1M2,  Entry1M1,  Entry10,  Entry11,  Entry12,  Entry13],
                       [Entry2M3,  Entry2M2,  Entry2M1,  Entry20,  Entry21,  Entry22,  Entry23],
                       [Entry3M3,  Entry3M2,  Entry3M1,  Entry30,  Entry31,  Entry32,  Entry33]]
        
        //  Extract the matrix setting from the convolution
        currentMatrixType = convolution!.matrixType
        
        //  Initialize the dialog based on the convolution
        matrixType.selectItemWithTag(currentMatrixType.rawValue)
        setMatrixSize(currentMatrixType.getMatrixSize())
        fillMatrixEntries(convolution!.matrix)
        
        //  Set the controller as the delegate for all the entries
        for row in 0...6 {
            for column in 0...6 {
                entryMatrix[row][column].delegate = self
            }
        }
    }
    
    func setMatrixSize(size : Int)
    {
        var newState: Bool
        
        newState = (size < 7)
        //  Remove or add the outer ring of the matrix
        HorzLabelM3.hidden = newState
        for entry in entryMatrix[0] { entry.hidden = newState }
        HorzLabel3.hidden = newState
        for entry in entryMatrix[6] { entry.hidden = newState }
        VertLabelM3.hidden = newState
        for index in 1..<6 { entryMatrix[index][0].hidden = newState }
        VertLabel3.hidden = newState
        for index in 1..<6 { entryMatrix[index][6].hidden = newState }

        newState = (size < 5)
        //  Remove/enable the next ring of the matrix
        HorzLabelM2.hidden = newState
        for entry in entryMatrix[1] { entry.hidden = newState }
        HorzLabel2.hidden = newState
        for entry in entryMatrix[5] { entry.hidden = newState }
        VertLabelM2.hidden = newState
        for index in 2..<5 { entryMatrix[index][1].hidden = newState }
        VertLabel2.hidden = newState
        for index in 2..<5 { entryMatrix[index][5].hidden = newState }
    }
    
    func fillMatrixEntries(matrix : [Float])
    {
        fillingEntries = true
        var start = 0
        var end = 6
        let size = currentMatrixType.getMatrixSize()
        if (size == 5) {
            start = 1
            end = 5
        }
        if (size == 3) {
            start = 2
            end = 4
        }
        
        var index = 0
        for row in start...end {
            for column in start...end {
                entryMatrix[row][column].stringValue = "\(matrix[index])"
                index += 1
            }
        }
        fillingEntries = false
    }
    
    func fillMatrixFromEntries()
    {
        var start = 0
        var end = 6
        let size = currentMatrixType.getMatrixSize()
        if (size == 5) {
            start = 1
            end = 5
        }
        if (size == 3) {
            start = 2
            end = 4
        }
        
        var index = 0
        for row in start...end {
            for column in start...end {
                convolution!.matrix[index] = entryMatrix[row][column].floatValue
                index += 1
            }
        }
    }
    
    @IBAction func onMatrixTypeChanged(sender: NSPopUpButton) {
        //  Set up the matrix entry for the size
        let selectedTag = matrixType.selectedTag()
        if (selectedTag >= 0) {
            if let newType = Convolution2DMatrix(rawValue: selectedTag) {
                if newType != currentMatrixType {
                    currentMatrixType = newType
                    setMatrixSize(newType.getMatrixSize())
                    if let newMatrix = newType.getMatrix() {
                        fillMatrixEntries(newMatrix)
                    }
                }
            }
        }
    }
    
    override func controlTextDidChange(obj: NSNotification)
    {
        //  Ignore if filling from initial setting or a matrix type change
        if (fillingEntries) { return }
        
        //  Assume we are now a custom matrix
        let newMatrixType = currentMatrixType.getCustomOfSameSize()
        if (currentMatrixType != newMatrixType) {
            currentMatrixType = newMatrixType
            matrixType.selectItemWithTag(newMatrixType.rawValue)
        }
    }
    
    @IBAction func onCancel(sender: NSButton) {
        presentingViewController?.dismissViewController(self)
    }
    
    @IBAction func onOK(sender: NSButton) {
        //  Fill the convolution with the entries
        convolution?.matrixType = currentMatrixType
        fillMatrixFromEntries()
        
        //  Pass back to the invoking controller
        let networkVC = presentingViewController as! NetworkViewController
        networkVC.convolution2DEditComplete(convolution!)
        presentingViewController?.dismissViewController(self)
    }
}
