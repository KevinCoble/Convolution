//
//  LabeledImageGeneratorViewController.swift
//  Convolution
//
//  Created by Kevin Coble on 9/19/16.
//  Copyright © 2016 Kevin Coble. All rights reserved.
//

import Cocoa

class LabeledImageGeneratorViewController: NSViewController {

    @IBOutlet weak var noiseItemCountSelection: NSPopUpButton!
    @IBOutlet weak var horzRedLineNone: NSButton!
    @IBOutlet weak var horzRedLineInclude: NSButton!
    @IBOutlet weak var horzRedLineNoise: NSButton!
    @IBOutlet weak var horzGreenLineNone: NSButton!
    @IBOutlet weak var horzGreenLineInclude: NSButton!
    @IBOutlet weak var horzGreenLineNoise: NSButton!
    @IBOutlet weak var horzBlueLineNone: NSButton!
    @IBOutlet weak var horzBlueLineInclude: NSButton!
    @IBOutlet weak var horzBlueLineNoise: NSButton!
    @IBOutlet weak var vertRedLineNone: NSButton!
    @IBOutlet weak var vertRedLineInclude: NSButton!
    @IBOutlet weak var vertRedLineNoise: NSButton!
    @IBOutlet weak var vertGreenLineNone: NSButton!
    @IBOutlet weak var vertGreenLineInclude: NSButton!
    @IBOutlet weak var vertGreenLineNoise: NSButton!
    @IBOutlet weak var vertBlueLineNone: NSButton!
    @IBOutlet weak var vertBlueLineInclude: NSButton!
    @IBOutlet weak var vertBlueLineNoise: NSButton!
    @IBOutlet weak var redCircleNone: NSButton!
    @IBOutlet weak var redCircleInclude: NSButton!
    @IBOutlet weak var redCircleNoise: NSButton!
    @IBOutlet weak var greenCircleNone: NSButton!
    @IBOutlet weak var greenCircleInclude: NSButton!
    @IBOutlet weak var greenCircleNoise: NSButton!
    @IBOutlet weak var blueCircleNone: NSButton!
    @IBOutlet weak var blueCircleInclude: NSButton!
    @IBOutlet weak var blueCircleNoise: NSButton!
    
    var generator : LabeledImageGenerator!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  If we have a generator assigned, initialize from it
        if let generator = generator {
            noiseItemCountSelection.selectItem(withTag: generator.numNoiseItems)
            horzRedLineNone.state = NSOnState
            horzGreenLineNone.state = NSOnState
            horzBlueLineNone.state = NSOnState
            vertRedLineNone.state = NSOnState
            vertGreenLineNone.state = NSOnState
            vertBlueLineNone.state = NSOnState
            redCircleNone.state = NSOnState
            greenCircleNone.state = NSOnState
            blueCircleNone.state = NSOnState
            for component in generator.includeComponents {
                switch component {
                case .redHorizontalLine:
                    horzRedLineInclude.state = NSOnState
                case .greenHorizontalLine:
                    horzGreenLineInclude.state = NSOnState
                case .blueHorizontalLine:
                    horzBlueLineInclude.state = NSOnState
                case .redVerticalLine:
                    vertRedLineInclude.state = NSOnState
                case .greenVerticalLine:
                    vertGreenLineInclude.state = NSOnState
                case .blueVerticalLine:
                    vertBlueLineInclude.state = NSOnState
                case .redCircle:
                    redCircleInclude.state = NSOnState
                case .greenCircle:
                    greenCircleInclude.state = NSOnState
                case .blueCircle:
                    blueCircleInclude.state = NSOnState
                }
            }
            for component in generator.noiseComponents {
                switch component {
                case .redHorizontalLine:
                    horzRedLineNoise.state = NSOnState
                case .greenHorizontalLine:
                    horzGreenLineNoise.state = NSOnState
                case .blueHorizontalLine:
                    horzBlueLineNoise.state = NSOnState
                case .redVerticalLine:
                    vertRedLineNoise.state = NSOnState
                case .greenVerticalLine:
                    vertGreenLineNoise.state = NSOnState
                case .blueVerticalLine:
                    vertBlueLineNoise.state = NSOnState
                case .redCircle:
                    redCircleNoise.state = NSOnState
                case .greenCircle:
                    greenCircleNoise.state = NSOnState
                case .blueCircle:
                    blueCircleNoise.state = NSOnState
                }
            }
            
            //  Create a new generator, so we can cancel without affecting the original
            self.generator = LabeledImageGenerator(initIncludes: generator.includeComponents, initNoise: generator.noiseComponents, initNumNoiseItems: generator.numNoiseItems)
        }
    }
    
    @IBAction func onHorizontalRedLineChange(_ sender: NSButton) {
        processEntry(forComponent: .redHorizontalLine, withSender: sender)
    }
    
    @IBAction func onHorizontalGreenLineChange(_ sender: NSButton) {
        processEntry(forComponent: .greenHorizontalLine, withSender: sender)
    }
    
    @IBAction func onHorizontalBlueLineChange(_ sender: NSButton) {
        processEntry(forComponent: .blueHorizontalLine, withSender: sender)
    }
    
    @IBAction func onVerticalRedLineChange(_ sender: NSButton) {
        processEntry(forComponent: .redVerticalLine, withSender: sender)
    }
    
    @IBAction func onVerticalGreenLineChange(_ sender: NSButton) {
        processEntry(forComponent: .greenVerticalLine, withSender: sender)
    }
    
    @IBAction func onVerticalBlueLineChange(_ sender: NSButton) {
        processEntry(forComponent: .blueVerticalLine, withSender: sender)
    }
    
    @IBAction func onRedCircleChange(_ sender: NSButton) {
        processEntry(forComponent: .redCircle, withSender: sender)
    }
    
    @IBAction func onGreenCircleChange(_ sender: NSButton) {
        processEntry(forComponent: .greenCircle, withSender: sender)
    }
    
    @IBAction func onBlueCircleChange(_ sender: NSButton) {
        processEntry(forComponent: .blueCircle, withSender: sender)
    }
    
    func processEntry(forComponent: LabeledImageComponent, withSender: NSButton)
    {
        removeFromInclude(component: forComponent)
        removeFromNoise(component: forComponent)
        if (withSender.tag == 1) { generator.includeComponents.append(forComponent) }
        if (withSender.tag == 2) { generator.noiseComponents.append(forComponent) }
    }
    
    func removeFromInclude(component : LabeledImageComponent)
    {
        let index = generator.includeComponents.index(of: component)
        if let index = index {
            generator.includeComponents.remove(at: index)
        }
    }
    
    func removeFromNoise(component : LabeledImageComponent)
    {
        let index = generator.noiseComponents.index(of: component)
        if let index = index {
            generator.noiseComponents.remove(at: index)
        }
    }
    
    @IBAction func onCancel(_ sender: NSButton) {
        presenting?.dismissViewController(self)
    }
    
    @IBAction func onOK(_ sender: NSButton) {
        let networkVC = presenting as! NetworkViewController
        networkVC.setImageGenerator(generator)
        presenting?.dismissViewController(self)
    }
}
