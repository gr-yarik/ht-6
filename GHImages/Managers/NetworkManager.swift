//
//  NetworkManager.swift
//  GHImages
//
//  Created by Yaroslav Hrytsun on 19.02.2021.
//

import UIKit
import CoreData

class NetworkManager {
    
    static let shared = NetworkManager()
    
    var context: NSManagedObjectContext?
    
    private init () {}
    
    func checkIfTokenIsValid(token: String, completion: @escaping (Bool) -> ()) {
        let urlString = "https://api.github.com/"
        guard let url = URL(string: urlString) else { return }
        let request = NSMutableURLRequest(url: url)
        request.addValue("bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request as URLRequest) { [weak self] (data, response, error) in
            guard let self = self, let context = self.context, let statusCode = (response as? HTTPURLResponse)?.statusCode else { return }
            guard statusCode == 200 else {
                CleanerManager.clean(context: context)
                completion(false)
                return
            }
            completion(true)
        }.resume()
    }
    
    
    func getImagesFromRepo(withAccessToken accessToken: String, completion: @escaping (Bool) -> ()) {
        let urlString = "https://api.github.com/repos/gr-yarik/images/contents/"
        guard let url = URL(string: urlString) else { return }
        let request = NSMutableURLRequest(url: url)
        request.addValue("bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request as URLRequest) { [weak self] (data, response, error) in
            guard let self = self else { return }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else { return }
            guard statusCode == 200, let data = data else {
                return
            }
            do {
                let decoder = JSONDecoder()
                let imagesData = try decoder.decode([ImageModel].self, from: data)
                self.downloadImages(imageModels: imagesData, accessToken: accessToken, completion: completion)
            } catch {
                print(error.localizedDescription)
            }
        }.resume()
    }
    
    
    private func downloadImages(imageModels: [ImageModel], accessToken: String, completion: @escaping (Bool) -> ()) {
        var images: [Image] = [] {
            didSet {
                if imageModels.count - storedImages.count == images.count {
                    completion(true)
                }
            }
        }
        var storedImages: [Image] = []
        let fetchR: NSFetchRequest<Image> = Image.fetchRequest()
        do {
            guard let context = self.context else { return }
            storedImages = try context.fetch(fetchR)
        } catch {
            print(error.localizedDescription)
        }
        
        for (storedImageIndex, storedImage) in storedImages.enumerated() {
            if !imageModels.contains(where: { imageModel -> Bool in
                storedImage.name == imageModel.name
            }) {
                guard let context = self.context else { return }
                context.delete(storedImage)
//                uncomment if you need to see images that will be deleted
//                print("image to delete ", storedImage.name)
                storedImages.remove(at: storedImageIndex)
                do {
                    try context.save()
                } catch let error {
                    print(error)
                }
            }
        }
        
        for imageModel in imageModels {
            if storedImages.contains(where: { image -> Bool in
                image.name == imageModel.name
            }) {
                continue
            }
            
            guard let url = URL(string: imageModel.downloadURL) else { return }
            let request = NSMutableURLRequest(url: url)
            request.addValue("bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            URLSession.shared.dataTask(with: request as URLRequest) { [weak self] data, response, error in
                guard let data = data, let self = self else { return }
                DispatchQueue.main.async {
                    guard let context = self.context, let entity = NSEntityDescription.entity(forEntityName: "Image", in: context) else { return }
                    let image: Image = Image(entity: entity, insertInto: context)
                    image.name = imageModel.name
                    image.imageData = data
                    images.append(image)
                    do {
                        try context.save()
                    } catch let error {
                        print(error)
                    }
                }
            }.resume()
        }
        if imageModels.count - storedImages.count == images.count {
            completion(true)
        }
    }
}
