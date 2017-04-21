//
//  ChannelViewController.swift
//  Convolution
//
//  Created by Kevin Coble on 6/25/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Cocoa

class ChannelViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var channelIDTextField: NSTextField!
    @IBOutlet weak var inputSourceIDTextField: NSTextField!
    @IBOutlet weak var sourceListTable: NSTableView!
    @IBOutlet weak var deleteButton: NSButton!
    
    var currentSourceList : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func onCancel(_ sender: NSButton) {
        presenting?.dismissViewController(self)
    }
    
    @IBAction func onAddNewSource(_ sender: NSButton) {
        //  Make sure we have an identifier for this channel
        if inputSourceIDTextField.stringValue.isEmpty {
            warningAlert("No source ID entry", information: "The source identifier field is empty")
            return
        }
        
        currentSourceList.append(inputSourceIDTextField.stringValue)
        sourceListTable.reloadData()
    }
    
    @IBAction func onDeleteSource(_ sender: NSButton) {
        let row = sourceListTable.selectedRow
        if (row >= 0) {
            currentSourceList.remove(at: row)
            sourceListTable.reloadData()
        }
    }
    
    @IBAction func onOK(_ sender: NSButton) {
        //  Make sure we have an identifier for this channel
        if channelIDTextField.stringValue.isEmpty {
            warningAlert("A channel identifier is required", information: "The channel identifier field is empty")
            return
        }
        
        //  Make sure we have at least one source
        if currentSourceList.count <= 0 {
            warningAlert("At least one input source is needed", information: "The input source list is empty")
            return
        }
        
        //  Pass results back to the invoking controller
        let networkVC = presenting as! NetworkViewController
        networkVC.channelEditComplete(channelID: channelIDTextField.stringValue, inputSourceIDs: currentSourceList)
        
        presenting?.dismissViewController(self)
    }
    
    func warningAlert(_ message: String, information: String) {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = message
        myPopup.informativeText = information
        myPopup.alertStyle = NSAlertStyle.warning
        myPopup.addButton(withTitle: "OK")
        myPopup.runModal()
    }
    
    //  TableView methods
    func numberOfRows(in aTableView: NSTableView) -> Int
    {
        return currentSourceList.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any?
    {
        return currentSourceList[row]
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = sourceListTable.selectedRow
        if (row >= 0) {
            deleteButton.isEnabled = true
        }
        else {
            deleteButton.isEnabled = false
        }
    }
}
