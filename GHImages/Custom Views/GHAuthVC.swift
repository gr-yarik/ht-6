//
//  GHAuthVC.swift
//  GHImages
//
//  Created by Yaroslav Hrytsun on 18.02.2021.
//

import UIKit
import WebKit
import SwiftKeychainWrapper

class GHAuthVC: UIViewController {
    
    private var authWebView: WKWebView?
    
    weak var delegate: ViewControllerDelegate?
    
    init(delegate: ViewController) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        modalPresentationStyle = .fullScreen
        configureAuthWebView()
        loadLoginPage()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func configureAuthWebView() {
        authWebView = WKWebView(frame: view.bounds)
        guard let authWebView = authWebView else { return }
        authWebView.navigationDelegate = self
        view.addSubview(authWebView)
    }
    
    
    private func loadLoginPage() {
        let uuid = UUID().uuidString
        let urlString = "https://github.com/login/oauth/authorize?client_id=" + GithubConstants.clientId + "&scope=" + GithubConstants.scope + "&redirect_uri=" + GithubConstants.redirectUrl + "&state=" + uuid
        guard let url = URL(string: urlString) else { return }
        let urlRequest = URLRequest(url: url)
        guard let authWebView = authWebView else { return }
        authWebView.load(urlRequest)
    }
    
    
    private func RequestForCallbackURL(request: URLRequest) {
        guard let requestURLString = request.url?.absoluteString,
              requestURLString.hasPrefix(GithubConstants.redirectUrl),
              requestURLString.contains("code="),
              let range = requestURLString.range(of: "=")
        else { return }
        
        let githubCode = requestURLString[range.upperBound...]
        if let range = githubCode.range(of: "&state=") {
            let githubCodeFinal = githubCode[..<range.lowerBound]
            githubRequestForAccessToken(authCode: String(githubCodeFinal))
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    
    private func githubRequestForAccessToken(authCode: String) {
        let grantType = "authorization_code"
        let postParams = "grant_type=" + grantType + "&code=" + authCode + "&client_id=" + GithubConstants.clientId + "&client_secret=" + GithubConstants.clientSecret
        let postData = postParams.data(using: String.Encoding.utf8)
        guard let url = URL(string: GithubConstants.tokenUrl) else { return }
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postData
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else { return }
            guard statusCode == 200, let data = data else { return }
            let results = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [AnyHashable: Any]
            guard let accessToken = results?["access_token"] as? String else { return }
            KeychainWrapper.saveAccessTocken(accessToken: accessToken)
            print("AccessToken has been saved")
            DispatchQueue.main.async {
                self.delegate?.didDismissAuthView(self)
                self.dismiss(animated: true, completion: nil)
            }
        }.resume()
    }
}

extension GHAuthVC: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        self.RequestForCallbackURL(request: navigationAction.request)
        decisionHandler(.allow)
    }
}
