//
//  InputViewController.swift
//  Convolution
//
//  Created by Kevin Coble on 6/25/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Cocoa

class InputViewController: NSViewController {

    @IBOutlet weak var inputIdentifierTextField: NSTextField!
    @IBOutlet weak var dataTypePopUp: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func onCancel(_ sender: NSButton) {
        presenting?.dismissViewController(self)
    }
    
    @IBAction func onOK(_ sender: NSButton) {
        //  Pass results back to the invoking controller
        let networkVC = presenting as! NetworkViewController
        networkVC.inputEditComplete(inputID: inputIdentifierTextField.stringValue, dataType: ImageDataSource(rawValue: dataTypePopUp.selectedTag()))
        
        presenting?.dismissViewController(self)
    }
    
}
