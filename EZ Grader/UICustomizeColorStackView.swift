//
//  UICustomizeColorStackView.swift
//  EZ Grader
//
//  Created by Akshay Kalbhor on 12/5/18.
//  Copyright © 2018 RIT. All rights reserved.
//

import UIKit

class UICustomizeColorStackView: UIStackView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    @IBOutlet var colorPreviewView: UIView!
    @IBOutlet var redValueSlider: UISlider!
    @IBOutlet var blueValueSlider: UISlider!
    @IBOutlet var greenValueSlider: UISlider!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        print(colorPreviewView)
    }
    
    
    override func didMoveToSuperview() {
        //self.customizeView()
    }
    
    override func didAddSubview(_ subview: UIView) {
        
        if subview.tag == 9 {
            print(subview)
            self.colorPreviewView.layer.cornerRadius = min(self.frame.size.width/2, self.frame.size.height/2)
        }
    }
    
    
    
    private func customizeView() {
        self.colorPreviewView.layer.cornerRadius = min(self.frame.size.width/2, self.frame.size.height/2)
        redValueSlider.value = 0.75
        blueValueSlider.value = 0.2
        greenValueSlider.value = 0.2
         self.colorPreviewView.backgroundColor = UIColor.init(red: CGFloat(redValueSlider.value), green: CGFloat(greenValueSlider.value), blue: CGFloat(blueValueSlider.value), alpha: 1.0)
    }

    @IBAction func redSliderMoved(_ sender: UISlider) {
        print("BABABABA")
        self.colorPreviewView.backgroundColor = UIColor.init(red: CGFloat(sender.value), green: CGFloat(greenValueSlider.value), blue: CGFloat(blueValueSlider.value), alpha: 1.0)
    }
    
    @IBAction func blueSliderMoved(_ sender: UISlider) {
        self.colorPreviewView.backgroundColor = UIColor.init(red: CGFloat(redValueSlider.value), green: CGFloat(greenValueSlider.value), blue: CGFloat(sender.value), alpha: 1.0)
    }
    
    @IBAction func greenSliderMoved(_ sender: UISlider) {
        self.colorPreviewView.backgroundColor = UIColor.init(red: CGFloat(redValueSlider.value), green: CGFloat(sender.value), blue: CGFloat(blueValueSlider.value), alpha: 1.0)
        
    }
    
}
