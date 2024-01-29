//
//  DBManager.swift
//  BBS+Tests
//
//  Created by Jonas Niestroj on 25.11.23.
//

import Foundation
import SQLite3

class DBManager {
    
    static let instance = DBManager()
    
    init() {
        db = openDatabase()
        clear()
        createTable()
    }
    
    let dbPath: String = "credential.sqlite"
    var db: OpaquePointer?
    
    func openDatabase() -> OpaquePointer? {
        let filePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(dbPath)
        var db: OpaquePointer? = nil
        
        if sqlite3_open(filePath.path, &db) != SQLITE_OK {
            debugPrint("Cant open database")
            return nil
        } else {
            print("Success created connection to database")
            return db
        }
    }
    
    func createTable() {
        let createTableString = "CREATE TABLE IF NOT EXISTS credentials(json TEXT);"
        var createTableStatement: OpaquePointer? = nil
        
        sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil)
        sqlite3_step(createTableStatement)
        sqlite3_finalize(createTableStatement)
    }
    
    func insert(json: String) {
        let insertStatementString = "INSERT INTO credentials(json) VALUES (?);"
        var insertStatement: OpaquePointer? = nil
        
        sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil)
        sqlite3_bind_text(insertStatement, 1, (json as NSString).utf8String, -1, nil)
        sqlite3_step(insertStatement)
        sqlite3_finalize(insertStatement)
    }
    
    func clear() {
        print("clear")
        let deleteStatementString = "DELETE FROM credentials;"
        var deleteStatement: OpaquePointer? = nil
        
        sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil)
        sqlite3_step(deleteStatement)
        sqlite3_finalize(deleteStatement)
    }
    
    func getCredentials() -> [String] {
        let queryStatementString = "SELECT * FROM credentials;"
        var queryStatement: OpaquePointer? = nil
        var credentials: [String] = []
        
        sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil)
        
        while sqlite3_step(queryStatement) == SQLITE_ROW {
            let json = String(describing: String(cString: sqlite3_column_text(queryStatement, 0)))
            credentials.append(json)
        }
        
        sqlite3_finalize(queryStatement)
        return credentials
    }
    
    func deleteCredential(index: Int) {
        let deleteStatementString = "DELETE FROM credentials WHERE rowid in (SELECT rowid FROM credentials LIMIT 1 OFFSET \(index));"
        var deleteStatement: OpaquePointer? = nil
        
        sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil)
        sqlite3_step(deleteStatement)
        sqlite3_finalize(deleteStatement)
    }
}
