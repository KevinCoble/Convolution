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
        operationSelection.selectItem(withTag: initialOperation)
        reductionSelection.selectItem(withTag: initialReduction)
    }
    
    @IBAction func onCancel(_ sender: NSButton) {
        presenting?.dismissViewController(self)
    }
    
    @IBAction func onOK(_ sender: NSButton) {
        //  Pass results back to the invoking controller
        let networkVC = presenting as! NetworkViewController
        networkVC.poolingEditComplete(operationSelection.selectedTag(),
                            reduction: reductionSelection.selectedTag())
        
        presenting?.dismissViewController(self)
    }
}
