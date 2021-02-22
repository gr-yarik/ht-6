//
//  ViewController.swift
//  GHImages
//
//  Created by Yaroslav Hrytsun on 16.02.2021.
//

import UIKit
import SwiftKeychainWrapper
import CoreData
import LocalAuthentication

protocol ViewControllerDelegate: class {
    func didDismissAuthView(_ viewController: GHAuthVC)
}

class ViewController: GHDataLoadingVC {
    
    var context: NSManagedObjectContext?
    
    @IBOutlet private weak var tableView: UITableView!
    
    @IBOutlet private weak var logOutButton: UIBarButtonItem!
    @IBOutlet private weak var logInButton: UIBarButtonItem!
    
    private var images: [Image] = [] {
        didSet {
            for image in images {
                guard let imageData = image.imageData, let uiImage = UIImage(data: imageData) else { return }
                uiImages.append(uiImage)
            }
        }
    }
    
    private var uiImages: [UIImage] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private var logInButtonIsEnabled: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.logInButton.isEnabled = self.logInButtonIsEnabled
            }
        }
    }
    
    private var logOutButtonIsEnabled: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.logOutButton.isEnabled = self.logOutButtonIsEnabled
            }
        }
    }
    
    
    @IBAction private func logOutButtonPressed(_ sender: Any) {
        if let context = context {
            CleanerManager.clean(context: context)
        }
        logOutButtonIsEnabled = false
        logInButtonIsEnabled = true
        uiImages = []
    }
    
    
    @IBAction private func logInButtonPressed(_ sender: Any) {
        logInButtonIsEnabled = false
        initiateAuthProcess()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        performAuthCheck()
    }
    
    
    private func performAuthCheck() {
        guard let token = KeychainWrapper.getAccessToken() else {
            initiateAuthProcess()
            return
        }
//        uncomment if you need to see the token
//        print(token)
        showLoadingView()
        NetworkManager.shared.checkIfTokenIsValid(token: token) { [weak self] tokenIsValid in
            guard let self = self else { return }
            guard tokenIsValid else {
                self.dismissLoadingView()
                self.initiateAuthProcess()
                return
            }
            self.performBiometricsAuth { success in
                guard success else {
                    self.dismissLoadingView()
                    return 
                }
                self.getImagesFromStorageOrNetwork(withToken: token)
            }
        }
    }
    
    
    private func performBiometricsAuth(completion: @escaping (Bool) -> ()) {
        let context = LAContext()
        var error: NSError? = nil
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Proceed if you want to continue"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
                guard let self = self else { return }
                guard success, error == nil else {
                    let alert = UIAlertController(title: "Error", message: "Failed to authenticate", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    DispatchQueue.main.async {
                        self.logOutButtonIsEnabled = true
                        self.present(alert, animated: true)
                    }
                    completion(false)
                    return
                }
                completion(true)
            }
        }
    }
    
    
    private func getImagesFromStorageOrNetwork(withToken token: String) {
        if let token = KeychainWrapper.getAccessToken() {
            NetworkManager.shared.getImagesFromRepo(withAccessToken: token) { [weak self] completed in
                guard let self = self else { return }
                if completed {
                    let fetchR: NSFetchRequest<Image> = Image.fetchRequest()
                    do {
                        guard let context = self.context else { return }
                        self.images = try context.fetch(fetchR)
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            self.logInButtonIsEnabled = false
                            self.logOutButtonIsEnabled = true
                            self.dismissLoadingView()
                        }
                    } catch let error {
                        print(error)
                    }
                }
            }
        }
    }
    
    
    private func initiateAuthProcess() {
        DispatchQueue.main.async {
            self.present(GHAuthVC(delegate: self), animated: true)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "detailed", let sender = sender as? UITableViewCell, let destinationVC = segue.destination as? DetailedViewController else { return }
        destinationVC.image = sender.imageView?.image
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return uiImages.count
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let imageName = images[section].name else { return "" }
        return imageName
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.imageView?.image = uiImages[indexPath.section]
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

extension ViewController: ViewControllerDelegate {
    func didDismissAuthView(_ viewController: GHAuthVC) {
        showLoadingView()
        if let token = KeychainWrapper.getAccessToken() {
            getImagesFromStorageOrNetwork(withToken: token)
        }
    }
}
