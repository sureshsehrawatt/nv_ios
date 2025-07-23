//
//  NvFlushCrashData.swift
//  nv_ios
//  Created by cavisson on 18/08/23.
//  Copyright © 2023 Cavisson. All rights reserved.
//  Suresh Sehrawat
//

import Foundation

public class NvFlushCrashData{
    public func sendPostData(){
        // Reading data from UserDefaults
        let postdata = UserDefaults.standard.string(forKey: "postdata")!
        let url = UserDefaults.standard.string(forKey: "url")!
        
        if let url1 = URL(string: url) {
            let postData = postdata.data(using: .utf8)!
            
            NetworkManager.performPOSTRequest(url: url1, bodyData: postData) { result in
                switch result {
                case .success(let (response, responseData)):
                    let statusCode = response.statusCode
                    print("Status Code: \(statusCode)")
                    print(url1)
                    UserDefaults.standard.set("false", forKey: "pendingData")
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
    }
    
    public func flushData(){
        if let check = UserDefaults.standard.string(forKey: "pendingData") {
            if(check == "true"){
                sendPostData()
                UserDefaults.standard.set("false", forKey: "pendingData")
            }
        }
    }
}




class NetworkManager {
    static func performPOSTRequest(url: URL, bodyData: Data, completion: @escaping (Result<(HTTPURLResponse, Data), Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, let data = data {
                completion(.success((httpResponse, data)))
            }
        }
        task.resume()
    }
}
