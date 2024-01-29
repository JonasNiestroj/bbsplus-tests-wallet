//
//  Credentials.swift
//  BBS+Tests
//
//  Created by Jonas Niestroj on 25.11.23.
//

import Foundation
import SwiftUI

struct Credentials: View {
    
    var names = Array<String>()
    
    init() {
        let credentials = DBManager.instance.getCredentials()
        print("credentials", credentials)
        for credential in credentials {
            if let jsonObject = try? JSONSerialization.jsonObject(with: credential.data(using: .utf8)!, options: []) as? [String: Any] {
                let credentialSubject = jsonObject["credentialSubject"] as? [String: Any]
                let firstName = credentialSubject!["firstName"] as? String
                names.append(firstName!)
            }
        }
    }
    
    func delete(at offsets: IndexSet) {
        DBManager.instance.deleteCredential(index: offsets.first!)
    }
    
    var body: some View {
        List {
            ForEach(names, id: \.self) { name in
                Text(name)
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("Credentials")
        
    }
}

#Preview {
    Credentials()
}
