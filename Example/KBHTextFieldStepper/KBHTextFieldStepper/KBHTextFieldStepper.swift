//
//  KBHTextFieldStepper.swift
//  KBHTextFieldStepper
//
//  Created by Keith Hunter on 8/9/15.
//  Copyright © 2015 Keith Hunter. All rights reserved.
//

import UIKit


public class KBHTextFieldStepper: UIControl, UITextFieldDelegate {
    
    // MARK: Public Properties
    
    public var value: Double {
        get { return _value }
        set { self.setValue(value: newValue) }
    }
    public var minimumValue: Double = 0 {
        didSet {
            if self.value < self.minimumValue {
                self.value = self.minimumValue
            }
        }
    }
    public var maximumValue: Double = 100 {
        didSet {
            if self.value > self.maximumValue {
                self.value = self.maximumValue
            }
        }
    }
    public var stepValue: Double = 1
    public var textFieldDelegate: UITextFieldDelegate? {
        didSet { self.textField.delegate = self.textFieldDelegate }
    }
    public var wraps: Bool = false
    public var autorepeat: Bool = true
    public var continuous: Bool = true
    
    
    // MARK: Private Properties
    
    /// This is private so that no one can mess with the text field's configuration. Use value and textFieldDelegate to control text field customization.
    private var textField: UITextField!
    private let numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()
    
    private var _value: Double = 0
    
    /// A timer to implement the functionality of holding down one of the KBHTextFieldStepperButtons. Once started, the run loop will hold a strong reference to the timer, so this property can be weak. The timer is allocated once a button is pressed and deallocated once the button is unpressed.
    private weak var timer: Timer?
    
    
    // MARK: Initializers
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    private func setup() {
        self.backgroundColor = UIColor.white

        // Buttons
        let minus = KBHTextFieldStepperButton(origin: CGPoint(x: 0, y: 0), type: .Minus)
        let plus = KBHTextFieldStepperButton(origin: CGPoint(x: self.frame.size.width - minus.frame.size.width, y: 0), type: .Plus)
        
        minus.addTarget(self, action: #selector(minusTouchDown(sender:)), for: .touchDown)
        minus.addTarget(self, action: #selector(minusTouchUp(sender:)), for: .touchUpInside)
        plus.addTarget(self, action: #selector(plusTouchDown(sender:)), for: .touchDown)
        plus.addTarget(self, action: #selector(plusTouchUp(sender:)), for: .touchUpInside)
        
        // Dividers
        let leftDivider = UIView(frame: CGRect(x: minus.frame.size.width, y:0, width: 1.5, height: 29))
        let rightDivider = UIView(frame: CGRect(x: self.frame.size.width - plus.frame.size.width, y: 0, width: 1.5, height: 29))
        leftDivider.backgroundColor = self.tintColor
        rightDivider.backgroundColor = self.tintColor
        
        // Text Field
        self.textField = UITextField(frame: CGRect(x: leftDivider.frame.origin.x + leftDivider.frame.size.width, y: 0, width: rightDivider.frame.origin.x - (leftDivider.frame.origin.x + leftDivider.frame.size.width), height: 29))
        self.textField.textAlignment = .center
        self.textField.text = "0"
        self.textField.keyboardType = UIKeyboardType.numbersAndPunctuation
        self.textField.delegate = self
        
        // Layout:  - | textField | +
        self.addSubview(minus)
        self.addSubview(leftDivider)
        self.addSubview(self.textField)
        self.addSubview(rightDivider)
        self.addSubview(plus)
        
        // Border
        self.layer.borderWidth = 1
        self.layer.borderColor = self.tintColor.cgColor
        self.layer.cornerRadius = 5
        self.clipsToBounds = true
        
        self.value = self.minimumValue
    }
    
    
    // MARK: Getters/Setters
    
    private func setValue(value: Double) {
        if value > self.maximumValue {
            _value = self.wraps ? self.minimumValue : self.maximumValue
        } else if value < self.minimumValue {
            _value = self.wraps ? self.maximumValue : self.minimumValue
        } else {
            _value = value
        }
        
        self.textField.text = self.numberFormatter.string(from: NSNumber(value: _value))
    }
    
    
    // MARK: Actions
    
    @objc internal func minusTouchDown(sender: KBHTextFieldStepperButton) { self.buttonTouchDown(sender: sender, selector: #selector(decrement)) }
    @objc internal func plusTouchDown(sender: KBHTextFieldStepperButton) { self.buttonTouchDown(sender: sender, selector: #selector(increment)) }
    
    private func buttonTouchDown(sender: KBHTextFieldStepperButton, selector: Selector) {
        sender.backgroundColor = self.tintColor.withAlphaComponent(0.15)
        self.sendSubview(toBack: sender)
        self.perform(selector)
        
        if self.autorepeat {
            self.timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: selector, userInfo: nil, repeats: true)
        }
    }
    
    @objc internal func minusTouchUp(sender: KBHTextFieldStepperButton) { self.buttonTouchUp(sender: sender) }
    @objc internal func plusTouchUp(sender: KBHTextFieldStepperButton) { self.buttonTouchUp(sender: sender) }
    
    private func buttonTouchUp(sender: KBHTextFieldStepperButton) {
        sender.backgroundColor = self.backgroundColor
        self.sendSubview(toBack: sender)
        
        guard let timer = self.timer else { return }
        timer.invalidate()
        
        // autorepeat is on since we used a timer. If not continuous, send the only value changed event
        if !self.continuous {
            self.sendActions(for: .valueChanged)
        }
    }
    
    @objc internal func decrement() {
        self.value -= self.stepValue
        self.sendValueChangedEvent()
    }
    
    @objc internal func increment() {
        self.value += self.stepValue
        self.sendValueChangedEvent()
    }
    
    private func sendValueChangedEvent() {
        if self.autorepeat && self.continuous {
            self.sendActions(for: .valueChanged)
        } else if !self.autorepeat {
            // If not using autorepeat, this is only called once. Send value changed updates
            self.sendActions(for: .valueChanged)
        }
    }
    
    
    // MARK: UITextFieldDelegate
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        if string == "\n" {
            textField.resignFirstResponder()
            return false
        }
        
        // Allow deleting characters
        if string.isEmpty {
            return true
        }
        
        let legalCharacters = NSMutableCharacterSet.decimalDigits as! NSMutableCharacterSet
        legalCharacters.addCharacters(in: ".")
        legalCharacters.addCharacters(in: "")
        
        if let char = string.utf16.first, legalCharacters.characterIsMember(char) {
            let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
            _value = Double(newString)!
            return true
        } else {
            return false
        }
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if (textField.text?.isEmpty)! {
            self.value = 0
        } else {
            self.value = Double(textField.text!)!
        }
    }

}


// MARK: - Private Classes

internal enum KBHTextFieldStepperButtonType {
    case Plus, Minus
}

internal class KBHTextFieldStepperButton: UIControl {
    
    private var type: KBHTextFieldStepperButtonType
    
    
    // MARK: Initializers
    
    internal required init(origin: CGPoint = CGPoint(x: 0, y: 0), type: KBHTextFieldStepperButtonType) {
        self.type = type
        super.init(frame: CGRect(x: origin.x, y: origin.y, width: 47, height: 29))
        self.backgroundColor = UIColor.clear
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: Drawing
    
    internal override func draw(_ rect: CGRect) {
        self.tintColor.setFill()
        
        if self.type == .Minus {
            self.drawMinus()
        } else {
            self.drawPlus()
        }
    }
    
    private func drawMinus() {
        let minus = UIBezierPath(rect: CGRect(x: 15.6667, y: 14.5, width: 15.6667, height: 1.5))
        minus.fill()
    }
    
    private func drawPlus() {
        let horiz = UIBezierPath(rect: CGRect(x: 15.6667, y: 14.5, width: 15.6667, height: 1.5))
        horiz.fill()
        let vert = UIBezierPath(rect: CGRect(x: 23.5, y: 6.6665, width: 1.5, height: 15.6667))
        vert.fill()
    }
    
    
    // MARK: Actions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.sendActions(for: .touchDown)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.sendActions(for: .touchUpInside)
    }
    
}
