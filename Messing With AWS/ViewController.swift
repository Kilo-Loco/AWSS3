//
//  ViewController.swift
//  Messing With AWS
//
//  Created by Kyle Lee on 7/2/17.
//  Copyright © 2017 Kyle Lee. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import AWSCognito
import AWSS3

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    let bucketName = "messing-with-aws"
    var contentUrl: URL!
    var s3Url: URL!
    
    let fileArray = ["earth", "neptune", "saturn"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USWest2,
                                                                identityPoolId:"us-west-2:97a13634-bb79-4043-b08e-4e59635bce6c")
        
        let configuration = AWSServiceConfiguration(region:.USWest2, credentialsProvider:credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        s3Url = AWSS3.default().configuration.endpoint.url
    }
    
    func uploadFile(with resource: String, type: String) {
        let key = "\(resource).\(type)"
        let localImagePath = Bundle.main.path(forResource: resource, ofType: type)!
        let localImageUrl = URL(fileURLWithPath: localImagePath)
        
        let request = AWSS3TransferManagerUploadRequest()!
        request.bucket = bucketName
        request.key = key
        request.body = localImageUrl
        request.acl = .publicReadWrite
        
        let transferManager = AWSS3TransferManager.default()
        transferManager.upload(request).continueWith(executor: AWSExecutor.mainThread()) { (task) -> Any? in
            if let error = task.error {
                print(error)
            }
            if task.result != nil {
                print("Uploaded \(key)")
                let contentUrl = self.s3Url.appendingPathComponent(self.bucketName).appendingPathComponent(key)
                self.contentUrl = contentUrl
            }
            
            return nil
        }
        
    }
    
    @IBAction func onUploadTapped() {
        uploadFile(with: "random", type: "mov")
    }
    
    @IBAction func onBulkTapped() {
        for fileName in fileArray {
            uploadFile(with: fileName, type: "jpeg")
        }
    }
    
    @IBAction func onShowTapped() {
        if contentUrl.path.contains("mov") {
            let player = AVPlayer(url: contentUrl)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            present(playerViewController, animated: true, completion: nil)
        } else {
            do {
                let data = try Data(contentsOf: contentUrl)
                imageView.image = UIImage(data: data)
            } catch {}
        }
    }

}

