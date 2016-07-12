//
//  ChannelViewController.swift
//  Convolution
//
//  Created by Kevin Coble on 6/25/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Cocoa

class ChannelViewController: NSViewController {

    @IBOutlet weak var channelIDTextField: NSTextField!
    @IBOutlet weak var inputSourceIDTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func onCancel(sender: NSButton) {
        presentingViewController?.dismissViewController(self)
    }
    
    @IBAction func onOK(sender: NSButton) {
        //  Pass results back to the invoking controller
        let networkVC = presentingViewController as! NetworkViewController
        networkVC.channelEditComplete(channelID: channelIDTextField.stringValue, inputSourceID: inputSourceIDTextField.stringValue)
        
        presentingViewController?.dismissViewController(self)
    }
}
