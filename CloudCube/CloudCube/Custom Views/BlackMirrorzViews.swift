//
//  BlackMirrorzViews.swift
//  CloudCube
//
//  Created by Josh Robbins on 15/06/2018.
//  Copyright © 2018 BlackMirrorz. All rights reserved.
//

import UIKit
import ARKit

//---------------------------------
//MARK: - BlackMirrorz Round Button
//---------------------------------

@IBDesignable public class BlackMirrorzRoundButton: UIButton {
    
    @IBInspectable var borderColor: UIColor = .white{
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 2.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = 0.5 * bounds.size.width
            
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        clipsToBounds = true
    }
}

//------------------------------------
//MARK: - BlackMirrorz Round ImageView
//------------------------------------

@IBDesignable public class BlackMirrorzRoundImageView: UIImageView { 
    
    @IBInspectable var borderColor: UIColor = .white{
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 2.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = 0.5 * bounds.size.width
            
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        clipsToBounds = true
    }
}
