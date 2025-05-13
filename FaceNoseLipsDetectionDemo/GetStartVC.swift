//
//  ViewController.swift
//  FaceNoseLipsDetectionDemo
//
//  Created by manthan on 12/05/25.
//

import UIKit
import PhotosUI

class GetStartVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
      
    }
    
    func configureImagePicker(){
          var configuration = PHPickerConfiguration()
          //0 - unlimited 1 - default
          configuration.selectionLimit = 1
          configuration.filter = .images
          let pickerViewController = PHPickerViewController(configuration: configuration)
          pickerViewController.delegate = self
          present(pickerViewController, animated: true)
      }


    @IBAction func btnContinueTapped(_ sender: UIButton) {
        configureImagePicker()
        
    }
}

extension GetStartVC : PHPickerViewControllerDelegate{
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            if let itemprovider = results.first?.itemProvider{
              
                if itemprovider.canLoadObject(ofClass: UIImage.self){
                    itemprovider.loadObject(ofClass: UIImage.self) { image , error  in
                        if let error{
                            print(error)
                        }
           
                        if let selectedImage = image as? UIImage{
                            DispatchQueue.main.async {
                                
                                let nextVC = self.storyboard!.instantiateViewController(withIdentifier: "ImageEditVC") as! ImageEditVC
                                nextVC.image = selectedImage
                                self.navigationController?.pushViewController(nextVC, animated: true)
                            }
                        }
                    }
                }
                
            }
        }
    
    
}
