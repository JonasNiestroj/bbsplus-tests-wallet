//
//  ContentView.swift
//  BBS+Tests
//
//  Created by Jonas Niestroj on 18.11.23.
//

import SwiftUI
import bbs

struct ContentView: View {
    @State var scanResult = "No QR code detected"
    @State var showQRScanner = false
    @State var updater: Bool = false
    

    func handleCredential(qrCode: String) {
        showQRScanner.toggle()
        guard let url = URL(string: "http://192.168.1.108:8000/params") else {fatalError("MIssing url")}
        var request = URLRequest(url: url)
        let dataTask = URLSession.shared.dataTask(with: request){(data, response, error) in
            guard let data = data else {return}
            let dataString = String(data: data, encoding: .utf8)

            let commitment = create_binding_commitment(dataString!)
            
            let commitment_url = commitment.toString().addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!.replacingOccurrences(of: "+", with: "%2B")
            
            guard let url = URL(string: qrCode + "&binding=" + commitment_url) else {fatalError("Missing url")}
            print(url)
            var request = URLRequest(url: url)
            let dataTask = URLSession.shared.dataTask(with: request){(data, response,error) in
                if let error = error {
                    print("Request error:", error)
                    return
                }
                
                guard let response = response as? HTTPURLResponse else {return}
                
                if response.statusCode == 200 {
                    guard let data = data else {return}
                    let json =  try? JSONSerialization.jsonObject(with: data)
                    DBManager.instance.insert(json: String(data: data, encoding: .utf8)!)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // Change `2.0` to the desired number of seconds.
                        updater = false
                    }
                    updater.toggle()
                }
            }
            
            dataTask.resume()
        }
        dataTask.resume()

    }
    
    func handlePresentation(qrCode: String) {
        let credential = DBManager.instance.getCredentials()[0]
        if var jsonObject = try? JSONSerialization.jsonObject(with: credential.data(using: .utf8)!, options: []) as? [String: Any] {
            var proof = jsonObject["proof"] as? [String: Any]
            var signature = proof!["proofValue"] as? String
            let proofValue = create_proof(signature!)
            
            guard let url = URL(string: qrCode) else {fatalError("Missing url")}
            var request = URLRequest(url: url)
            proof?.updateValue(proofValue.toString(), forKey: "proofValue")
            jsonObject.updateValue(proof, forKey: "proof")
            
            var revocation = jsonObject["revocation"] as? [String: Any]
            var credential_index = revocation!["credentialIndex"] as? Int;
            
            guard let revocationUrl = URL(string: "http://192.168.1.108:8001/verify?credential_index=" + String(credential_index!)) else {fatalError("Missing url")}
            var revocationRequest = URLRequest(url: revocationUrl)
            revocationRequest.httpMethod = "POST"
            
            let revocationTask = URLSession.shared.dataTask(with: revocationRequest){(data, response, error) in
                let json = try? JSONSerialization.jsonObject(with: data!) as? [String: Any]
                revocation?.updateValue(json!["nonRevocationProof"] as? String, forKey: "nonRevocationProof")
                revocation?.updateValue(json!["nonRevocationChallenge"] as? String, forKey: "nonRevocationChallenge")
                jsonObject.updateValue(revocation, forKey: "revocation")
                request.httpBody = try? JSONSerialization.data(withJSONObject: jsonObject)
                request.httpMethod = "POST"
                let dataTask = URLSession.shared.dataTask(with: request){(data, response,error) in
                    if let error = error {
                        print("Request error:", error)
                        return
                    }
                    
                    guard let response = response as? HTTPURLResponse else {return}
                    
                    if response.statusCode == 200 {
                        guard let data = data else {return}
                        let json =  try? JSONSerialization.jsonObject(with: data)
                        showQRScanner.toggle()
                    }
                }
                
                dataTask.resume()
            }
            
            revocationTask.resume()
        }
        
    }
    
    func handleQRCode(qrCode: String) {
        if qrCode.contains("credential") {
            handleCredential(qrCode: qrCode)
        } else if qrCode.contains("presentation") {
            handlePresentation(qrCode: qrCode)
        }
    }
    
    var body: some View {
        
        let scanResultBinding = Binding<String>(get: {
            self.scanResult
        }, set: {
            if self.scanResult != $0 && self.showQRScanner {
                self.handleQRCode(qrCode: $0)
            }
            
            self.scanResult = $0
        })
        
        Credentials()
        
        if self.updater {
            
        }
        
        Button(action: {self.showQRScanner.toggle()}) {
            Text("Scan")
        }.sheet(isPresented: $showQRScanner) {
            QRScanner(result: scanResultBinding)
            Button(action: {self.showQRScanner = false}) {
                Text("X")
            }.padding(.top)
        }
    }
}


#Preview {
    ContentView()
}
