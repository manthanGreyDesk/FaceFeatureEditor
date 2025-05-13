//
//  ImageEditVC.swift
//  FaceNoseLipsDetectionDemo
//
//  Created by manthan on 12/05/25.
//
//
//  ImageEditVC.swift
//  FaceNoseLipsDetectionDemo
//
//  Created by manthan on 12/05/25.
//

import UIKit
import Vision

class ImageEditVC: UIViewController {

    @IBOutlet weak var Segment: UISegmentedControl!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var slider: UISlider!

    var image = UIImage()
    var faceObservation: VNFaceObservation?

    var nosePoints: [CGPoint] = []
    var lipsPoints: [CGPoint] = []
    var leftEyePoints: [CGPoint] = []
    var rightEyePoints: [CGPoint] = []
    var leftEyeBrowsPoints: [CGPoint] = []
    var rightEyeBrowsPoints: [CGPoint] = []
    var facePoints: [CGPoint] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
        detectFaceFeatures(in: image)
        slider.minimumValue = 0.94
        slider.maximumValue = 1.06
    }

    func detectFaceFeatures(in image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let self = self,
                  let results = request.results as? [VNFaceObservation],
                  let face = results.first else { return }

            self.faceObservation = face
            let boundingBox = face.boundingBox
            let size = image.size

            func convert(_ points: [CGPoint]?, to array: inout [CGPoint]) {
                guard let points = points else { return }
                array = points.map { self.convert(point: $0, boundingBox: boundingBox, imageSize: size) }
            }

            convert(face.landmarks?.nose?.normalizedPoints, to: &nosePoints)
            convert(face.landmarks?.outerLips?.normalizedPoints, to: &lipsPoints)
            convert(face.landmarks?.leftEye?.normalizedPoints, to: &leftEyePoints)
            convert(face.landmarks?.rightEye?.normalizedPoints, to: &rightEyePoints)
            convert(face.landmarks?.leftEyebrow?.normalizedPoints, to: &leftEyeBrowsPoints)
            convert(face.landmarks?.rightEyebrow?.normalizedPoints, to: &rightEyeBrowsPoints)
            convert(face.landmarks?.faceContour?.normalizedPoints, to: &facePoints)
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }

    func convert(point: CGPoint, boundingBox: CGRect, imageSize: CGSize) -> CGPoint {
        let x = boundingBox.origin.x + point.x * boundingBox.width
        let y = 1 - (boundingBox.origin.y + point.y * boundingBox.height)
        return CGPoint(x: x * imageSize.width, y: y * imageSize.height)
    }

    @IBAction func SliderChange(_ sender: UISlider) {
        let scale = CGFloat(sender.value)
        let selected = Segment.selectedSegmentIndex

        let points: [CGPoint]
        switch selected {
        case 0: points = nosePoints
        case 1: points = lipsPoints
        case 2: points = leftEyePoints + rightEyePoints
        case 3: points = leftEyeBrowsPoints + rightEyeBrowsPoints
        case 4: points = facePoints
        default: return
        }

        guard points.count > 2 else { return }
        imageView.image = applyFeatureScaling(original: image, featurePoints: points, scale: scale)
    }

    @IBAction func ChangeSegment(_ sender: UISegmentedControl) {
        slider.setValue(1.0, animated: true)
        
        switch sender.selectedSegmentIndex{
        case 0 : slider.minimumValue = 0.94
            slider.maximumValue = 1.06
            
        case 1 : slider.minimumValue = 0.82
            slider.maximumValue = 1.28
            
        case 2 : slider.minimumValue = 0.94
            slider.maximumValue = 1.06
            
        case 3 : slider.minimumValue = 0.94
            slider.maximumValue = 1.06
            
        case 4 : slider.minimumValue = 0.98
            slider.maximumValue = 1.02
            
        default:
            slider.minimumValue = 0.99
            slider.maximumValue = 1.01
        }

    }

    func applyFeatureScaling(original: UIImage, featurePoints: [CGPoint], scale: CGFloat) -> UIImage? {
        // Create a smooth closed path around the feature
        let maskPath = UIBezierPath()
        maskPath.move(to: featurePoints.first!)
        for point in featurePoints.dropFirst() {
            maskPath.addLine(to: point)
        }
        maskPath.close()

        // Feature bounding rect with padding
        let bounds = maskPath.bounds.insetBy(dx: -15, dy: -15)

        UIGraphicsBeginImageContextWithOptions(original.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext(),
              let croppedCG = original.cgImage?.cropping(to: bounds) else {
            UIGraphicsEndImageContext()
            return nil
        }

        let croppedImage = UIImage(cgImage: croppedCG)
        let scaledSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        let scaledOrigin = CGPoint(
            x: bounds.midX - scaledSize.width / 2,
            y: bounds.midY - scaledSize.height / 2
        )

        // Draw the original image
        original.draw(at: .zero)

        // Mask drawing area only to feature shape
        context.saveGState()
        context.addPath(maskPath.cgPath)
        context.clip()

        // Draw scaled feature
        croppedImage.draw(in: CGRect(origin: scaledOrigin, size: scaledSize))
        context.restoreGState()

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
