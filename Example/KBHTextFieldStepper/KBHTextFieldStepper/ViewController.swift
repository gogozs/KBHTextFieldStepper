//
//  ViewController.swift
//  KBHTextFieldStepper
//
//  Created by Keith Hunter on 8/9/15.
//  Copyright © 2015 Keith Hunter. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        let textFieldStepper = KBHTextFieldStepper(frame: CGRect(x: 16, y: 28, width: 150, height: 29))
        self.view.addSubview(textFieldStepper)
    }
    
}

