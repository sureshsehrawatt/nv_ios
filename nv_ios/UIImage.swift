//
//  UIImage.swift
//  NetVision
//
//  Created by compass-362 on 07/07/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

import UIKit
import Foundation

extension UIImage{
    
    func resizeWith(percentage: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: size.width * percentage, height: size.height * percentage)))
        imageView.contentMode = .scaleAspectFill
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context);
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
    
    func compress( quality : Float = 0.5 ) -> NSData {
        let Quality = CGFloat.init(quality)
        //MARK: - Niket 23/07/21
//        return UIImageJPEGRepresentation(self, Quality) as! NSData
        return self.jpegData(compressionQuality: Quality)! as NSData
//        return self.UIImageJPEGRepresentation(compressionQuality: Quality)! as NSData;
    }
}
struct RGBA32 : Equatable  {
    var color: UInt32
    
    func red() -> UInt8 {
        return UInt8((color >> 24) & 255)
    }
    
    func green() -> UInt8 {
        return UInt8((color >> 16) & 255)
    }
    
    func blue() -> UInt8 {
        return UInt8((color >> 8) & 255)
    }
    
    func alpha() -> UInt8 {
        return UInt8((color >> 0) & 255)
    }
    
    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        color = (UInt32(red) << 24) | (UInt32(green) << 16) | (UInt32(blue) << 8) | (UInt32(alpha) << 0)
    }
    
    static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
}


func ==( lhs: RGBA32, rhs: RGBA32) -> Bool {
    return lhs.color == rhs.color
}

public func censorImage(sourceImage:UIImage, withImage : UIImage)->UIImage{
    
    let size = sourceImage.size
    UIGraphicsBeginImageContext(size)
    let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
    sourceImage.draw(in: rect, blendMode: CGBlendMode.normal, alpha: 1.0)
    withImage.draw(in: rect, blendMode: CGBlendMode.normal, alpha: 1.0)
    let testImg =  UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return testImg!
    
}


public func BlackListImage(image: UIImage , x : Int , y : Int , h : Int , w : Int ) -> UIImage {
    let imageSize = image.size
    let scale: CGFloat = UIScreen.main.scale
    UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
    let context = UIGraphicsGetCurrentContext()
    
    let rectangle = CGRect(x: x , y: y , width: w , height: h)
    
    context!.setFillColor(UIColor.black.cgColor)
    context!.addRect(rectangle)
    context!.drawPath(using: .fill);

    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    let Image = censorImage(sourceImage: image, withImage : newImage!);
    return Image
}

public func takeScreenshot(view: UIView) -> UIImage {
    
    UIGraphicsBeginImageContextWithOptions(UIScreen.main.bounds.size, false, 0);
    view.drawHierarchy(in: UIScreen.main.bounds, afterScreenUpdates: false)
    let image : UIImage = UIGraphicsGetImageFromCurrentImageContext()!;
    
    UIGraphicsEndImageContext();
    return image
    
}

public func SendToServer(image : UIImage, s : String = "") {
    let fileManager = FileManager.default;
    //MARK: - Niket 23/07/21
//    let image = image.UIImagePNGRepresentation();
//    let image = UIImagePNGRepresentation(image)
    let image = image.pngData()
    let loc = "/Users/compass362/Documents/myimage" + s + ".png"
    fileManager.createFile(atPath: loc, contents: image, attributes: nil)
}


public func savetoDesktop(image : UIImage, s : String = "") {
    let fileManager = FileManager.default;
    //MARK: - Niket 23/07/21
//    let image = image.UIImagePNGRepresentation();
//    let image = UIImagePNGRepresentation(image)
    let image = image.pngData()
    let loc = "/Users/compass362/Documents/myimage" + s + ".png"
    fileManager.createFile(atPath: loc, contents: image, attributes: nil)
}


