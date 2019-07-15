import Foundation
import Alamofire
import SwiftyJSON

extension Request {
    public func debugLog() -> Self {
        #if DEBUG
        debugPrint(self)
        #endif
        return self
    }
}

class GithubLoader {
    let baseURL = URL(string: "https://api.github.com/")!
    var username: String
    var accessToken: String
    
    let manager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        return SessionManager(configuration: configuration)
    }()

    public init(username: String, accessToken: String) {
        self.username = username
        self.accessToken = accessToken
    }

    public func refreshNotifications(callback: @escaping (([JSON]?, Error?) -> Void)) {
        let url = baseURL.appendingPathComponent("notifications")

        var headers: HTTPHeaders = [
            "Accept": "application/vnd.github.v3+json, application/json"
        ]
        if let authorizationHeader = Request.authorizationHeader(user: username, password: accessToken) {
            headers[authorizationHeader.key] = authorizationHeader.value
        }
        manager.request(url, headers: headers)
            .validate()
            .responseString { response in
                if response.error == nil {
                    let notifications = JSON.init(parseJSON: response.result.value!).array!
                    DispatchQueue.main.async {
                        callback(notifications, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        callback(nil, response.error)
                    }
                }
            }
    }
}
