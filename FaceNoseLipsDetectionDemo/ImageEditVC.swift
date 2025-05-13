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
import MetalKit

class ImageEditVC: UIViewController {

    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var metalImageView: MetalImageView!

    var image = UIImage(named: "face")!
    var selectedFeaturePoints: [CGPoint] = []
    var faceObservation: VNFaceObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        metalImageView.setupMetal()
        metalImageView.updateImage(image)
        detectFaceFeatures(in: image)
        slider.minimumValue = 0.9
        slider.maximumValue = 1.1
    }

    @IBAction func sliderChanged(_ sender: UISlider) {
        let scale = CGFloat(sender.value)
        guard let scaled = applyFeatureScaling(original: image, featurePoints: selectedFeaturePoints, scale: scale) else { return }
        metalImageView.updateImage(scaled)
    }

    func detectFaceFeatures(in image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let request = VNDetectFaceLandmarksRequest { [weak self] request, _ in
            guard let self = self,
                  let result = request.results?.first as? VNFaceObservation,
                  let nose = result.landmarks?.nose?.normalizedPoints else { return }

            self.faceObservation = result
            let boundingBox = result.boundingBox
            let imgSize = image.size
            self.selectedFeaturePoints = nose.map {
                let x = boundingBox.origin.x + $0.x * boundingBox.width
                let y = 1 - (boundingBox.origin.y + $0.y * boundingBox.height)
                return CGPoint(x: x * imgSize.width, y: y * imgSize.height)
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }

    func applyFeatureScaling(original: UIImage, featurePoints: [CGPoint], scale: CGFloat) -> UIImage? {
        guard featurePoints.count > 2 else { return nil }

        let path = UIBezierPath()
        path.move(to: featurePoints.first!)
        for pt in featurePoints.dropFirst() {
            path.addLine(to: pt)
        }
        path.close()

        let bounds = path.bounds.insetBy(dx: -10, dy: -10)
        UIGraphicsBeginImageContextWithOptions(original.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext(),
              let croppedCG = original.cgImage?.cropping(to: bounds) else {
            UIGraphicsEndImageContext()
            return nil
        }

        let cropped = UIImage(cgImage: croppedCG)
        let newSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        let newOrigin = CGPoint(x: bounds.midX - newSize.width/2, y: bounds.midY - newSize.height/2)

        original.draw(at: .zero)
        context.saveGState()
        context.addPath(path.cgPath)
        context.clip()
        cropped.draw(in: CGRect(origin: newOrigin, size: newSize))
        context.restoreGState()

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}

class MetalImageView: MTKView {

    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var texture: MTLTexture?

    func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal not supported on this device")
        }

        self.device = device
        self.commandQueue = device.makeCommandQueue()
        self.colorPixelFormat = .bgra8Unorm
        self.framebufferOnly = false
        self.isPaused = true
        self.enableSetNeedsDisplay = true

        loadShaders()
    }

    private func loadShaders() {
        guard let device = self.device,
              let library = device.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "vertexShader"),
              let fragmentFunction = library.makeFunction(name: "fragmentShader") else {
            print("Failed to load Metal shaders")
            return
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Error creating pipeline state: \(error)")
        }
    }

    func updateImage(_ image: UIImage) {
        guard let device = self.device, device != nil else {
              print("❌ Metal device is not available")
              return
          }
          guard let library = device.makeDefaultLibrary(),
                let vertexFunction = library.makeFunction(name: "vertexShader"),
                let fragmentFunction = library.makeFunction(name: "fragmentShader") else {
              print("❌ Failed to load shaders")
              return
          }

          let pipelineDescriptor = MTLRenderPipelineDescriptor()
          pipelineDescriptor.vertexFunction = vertexFunction
          pipelineDescriptor.fragmentFunction = fragmentFunction
          pipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat

          do {
              pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
          } catch {
              print("❌ Failed to create pipeline state: \(error)")
          }
    }

    override func draw(_ rect: CGRect) {
        guard let drawable = currentDrawable,
              let descriptor = currentRenderPassDescriptor,
              let texture = self.texture,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
