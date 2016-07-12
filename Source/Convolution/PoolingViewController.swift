//
//  PoolingViewController.swift
//  Convolution
//
//  Created by Kevin Coble on 2/21/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Cocoa

class PoolingViewController: NSViewController {

    @IBOutlet weak var operationSelection: NSPopUpButton!
    @IBOutlet weak var reductionSelection: NSPopUpButton!
    
    //  Initialization information
    var editMode = false
    var initialOperation = 0
    var initialReduction = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  Initialize the values
        operationSelection.selectItemWithTag(initialOperation)
        reductionSelection.selectItemWithTag(initialReduction)
    }
    
    @IBAction func onCancel(sender: NSButton) {
        presentingViewController?.dismissViewController(self)
    }
    
    @IBAction func onOK(sender: NSButton) {
        //  Pass results back to the invoking controller
        let networkVC = presentingViewController as! NetworkViewController
        networkVC.poolingEditComplete(operationSelection.selectedTag(),
                            reduction: reductionSelection.selectedTag())
        
        presentingViewController?.dismissViewController(self)
    }
}
