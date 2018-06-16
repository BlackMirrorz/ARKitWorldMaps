//
//  BoxNode.swift
//  CloudCube
//
//  Created by Josh Robbins on 15/06/2018.
//  Copyright © 2018 BlackMirrorz. All rights reserved.
//

import UIKit
import ARKit


/// The Geometry Index Of An SCNBox Geometry
enum BoxFaces: Int{
    
    case Front, Right, Back, Left, Top, Botton
}

class Box: SCNNode {
    
    private var faceArray = [SCNMaterial]()
    
    /// Creates An SCNBox With A Single Colour Or Image For It's Material
    ///
    /// - Parameters:
    ///   - width: Optional CGFloat (Defaults To 20cm)
    ///   - height: Optional CGFloat (Defaults To 20cm)
    ///   - length: Optional CGFloat (Defaults To 20cm)
    ///   - chamferRadius: Optional CGFloat (Defaults To 0cm)
    ///   - colour: Optional UIColor
    ///   - image: Optional UIColor
    init(width: CGFloat = 0.2, height: CGFloat = 0.2, length: CGFloat = 0.2, chamferRadius: CGFloat = 0, colour: UIColor?, image: UIImage?) {
        
        super.init()

        //1. Create The Box Geometry With Our Width, Height, Length & Chamfer Radius Parameters
        self.geometry = SCNBox(width: width, height: height, length: length, chamferRadius: chamferRadius)
       
        //2. Create A New Material
        let material = SCNMaterial()
       
        //3. If A Colour Has Not Be Set The Then Material Will Be A UIImage
        if colour == nil{
            material.diffuse.contents = image
        }else{
            //The Material Will Be A UIColor
            material.diffuse.contents = colour
        }
        
        //4. Set The Material Of The Box
        self.geometry?.firstMaterial = material
       
    }
    
    /// Creates An SCNBox With Either A Colour Or UIImage For Each Of It's Faces
    /// (Either An Array [Colour] Or [UIImage] Must Be Input)
    /// - Parameters:
    ///   - width: Optional CGFloat (Defaults To 20cm)
    ///   - height: Optional CGFloat (Defaults To 20cm)
    ///   - length: Optional CGFloat (Defaults To 20cm)
    ///   - chamferRadius: Optional CGFloat (Defaults To 0cm)
    ///   - colours: Optional [UIColor] - [Front, Right, Back, Left, Top, Bottom]
    ///   - images: Optional [UIImage] - [Front, Right, Back, Left, Top, Bottom]
    init(width: CGFloat = 0.2, height: CGFloat = 0.2, length: CGFloat = 0.2, chamferRadius: CGFloat = 0, colours: [UIColor]?, images: [UIImage]?) {
        
        super.init()
        
        //1. Create The Box Geometry With Our Width, Height, Length & Chamfer Radius Parameters
        self.geometry = SCNBox(width: width, height: height, length: length, chamferRadius: chamferRadius)
        
        //2. Create A Temporary Array To Store Either Our UIColors Or UIImages
        var sideArray = [Any]()
        
        //3. If Our Color Array Is Nil Then Our Side Array Will Be Equal To Our Images Array
        if colours == nil{
            guard let imageArray = images else { return }
            sideArray = imageArray
        }else{
            //Our Side Array Will Be Equal To Our Colours Array
            guard let coloursArray = colours else { return }
            sideArray = coloursArray
        }
        
        //4. Loop Through The Number Of Faces & Create A New Material For Each
        for index in 0 ..< 6{
            let face = SCNMaterial()
            face.diffuse.contents = sideArray[index]
            //Add The Material To Our Face Array
            faceArray.append(face)
        }
        
        //5. Set The Boxes Materials From Our Face Array
        self.geometry?.materials = faceArray

    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

}
