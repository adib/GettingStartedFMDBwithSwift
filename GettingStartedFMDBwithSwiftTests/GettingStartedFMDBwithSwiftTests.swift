//
//  GettingStartedFMDBwithSwiftTests.swift
//  GettingStartedFMDBwithSwiftTests
//
//  Created by Sasmito Adibowo on 30/11/22.
//

import XCTest
import FMDB


final class GettingStartedFMDBwithSwiftTests: XCTestCase {
    
    var theDatabase: FMDatabase!

    override func setUpWithError() throws {
        let databaseDir = URL.applicationSupportDirectory.appending(path: "GettingStartedWithFMDBandSwift")
        try FileManager.default.createDirectory(at: databaseDir, withIntermediateDirectories: true)
        let databaseFile = databaseDir.appending(path: "\( UInt(round(Date().timeIntervalSince1970*1000)) ).sqlite")
        theDatabase = FMDatabase(url: databaseFile)
        theDatabase.open()
        theDatabase.executeStatements("""
        CREATE TABLE IF NOT EXISTS songs (
            song_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
            title TEXT NULL,
            artist TEXT NULL,
            album TEXT NULL,
            play_count INTEGER NULL
        );
        """)
        print("Database created at: \(databaseDir) ")
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        theDatabase.close()        
    }
    
    
    /**
     Populate   two rows and query them.
     */
    func testSimpleQuery() throws {
        // populate database
        try theDatabase.executeUpdate("""
        INSERT INTO songs (
            title,
            album,
            artist
        ) VALUES (
            'Girlfriend',
            'The Best Damn Thing',
            'Avril Lavigne'
        )
        """, values: nil)
        try theDatabase.executeUpdate("""
        INSERT INTO songs (
            title,
            album,
            artist
        ) VALUES (
            'Ska8ter Boi',
            'Let Go',
            'Avril Lavigne'
        )
        """, values: nil)
                
        // query it
        let resultSet = try theDatabase.executeQuery("""
        SELECT album FROM songs WHERE artist = 'Avril Lavigne'
        """, values: nil)
        
        print("... and the albums are:")
        var resultNumber = 0;
        while(resultSet.next()) {
            resultNumber = resultNumber + 1
            let albumName = resultSet.string(forColumn: "album") ?? "*[NULL]*"
            print("\(resultNumber). \(albumName)")
        }
    }
    
    
    /**
       Prints a result set in a markdown format.
     */
    func printRows(_ resultSet: FMResultSet) {
        guard resultSet.columnCount > 0 else {
            print("ResultSet is empty")
            return
        }
        
        // print table column header
        print("\n|", terminator: "")
        for columnIndex in 0..<resultSet.columnCount {
            let columnName = resultSet.columnName(for: columnIndex) ?? "*[UNTITLED]*"
            print(" \(columnName) |", terminator: "")
        }
        print("\n|",terminator: "")
        for _ in 0..<resultSet.columnCount {
            print("---|", terminator: "")
        }
        print("")
        
        var resultNumber = 0;
        while(resultSet.next()) {
            resultNumber = resultNumber + 1
            print("|", terminator: "")
            for columnIndex in 0..<resultSet.columnCount {
                let columnValueAsString = resultSet.string(forColumnIndex: columnIndex)  ?? "*[NULL]*"
                print(" \(columnValueAsString) |", terminator: "")
            }
            print("")
        }
        print("\nTotal: \(resultNumber) row(s)", terminator: "\n\n")
    }
    
    /**
     Demonstrates SQL queries with hard-coded values.
     */
    func testHardCodedQuery() throws {
        // Insert one row
        try theDatabase.executeUpdate("""
        INSERT INTO songs (
            title,
            album,
            artist
        ) VALUES (
            'Begin Again',
            'Red',
            'Taylor Swift'
        )
        """, values: nil)
        
        // Get the last inserted row and query it.
        let lastInsertRowID = theDatabase.lastInsertRowId
        let insertResults = try theDatabase.executeQuery("""
        SELECT * FROM songs WHERE _rowid_=\(lastInsertRowID)
        """, values:nil)
        print("Result of insert follows...")
        printRows(insertResults)
        
        try theDatabase.executeUpdate("""
        UPDATE songs SET
            title = 'Begin Again (Taylor''s Version)',
            album = 'Red (Taylor''s Version)'
        WHERE
            artist = 'Taylor Swift'
            AND album = 'Red'
            AND title = 'Begin Again'
        """, values: nil)
        
        let updateResults = try theDatabase.executeQuery("""
            SELECT * FROM songs
        """, values: nil)
        print("Result of update follows...")
        printRows(updateResults)
    }

    
    /**
        Demonstrates SQL with statements having parameters.
     */
    func testParameterizedQuery() throws {
        let initialRowValues = [
            "title" : "Stay Stay Stay",
            "album" : "Red",
            "artist" : "Taylor Swift",
            "play_count" : 42
        ] as [String : Any]
        theDatabase.executeUpdate("""
        INSERT INTO songs (
            title,
            album,
            artist,
            play_count
        ) VALUES (
            :title,
            :album,
            :artist,
            :play_count
        )
        """, withParameterDictionary: initialRowValues)
        
        let insertResults = try theDatabase.executeQuery("""
            SELECT * FROM songs
        """, values: nil)
        print("Result of insert follows...")
        printRows(insertResults)

        let updateRowValues = [
            "title" : "Stay Stay Stay",
            "album" : "Red",
            "artist" : "Taylor Swift",
            "delta_play_count" : 1
        ] as [String : Any]
        theDatabase.executeUpdate("""
        UPDATE songs SET
            play_count = play_count + :delta_play_count
        WHERE
            title = :title
            AND album = :album
            AND artist = :artist
        """, withParameterDictionary: updateRowValues)
        
        let querySongValues = [
            "title" : "Stay Stay Stay",
            "album" : "Red",
            "artist" : "Taylor Swift"
        ]        
        let playCountResult = theDatabase.executeQuery("""
        SELECT
            play_count
        FROM songs
        WHERE
            title = :title
            AND album = :album
            AND artist = :artist
        """, withParameterDictionary: querySongValues)
        
        if let playCountResult = playCountResult,
           playCountResult.next() {
            let updatedPlayCount = playCountResult.int(forColumn: "play_count")
            print("Updated play count: \(updatedPlayCount)")
        }
    }
    
    
    func populateRecords() {
        let dataValues = [
            [
                "title" : "Keep Being You",
                "album" : "EXPLORE! (Special Edition)",
                "artist" : "Isyana Sarasvati",
                "play_count" : 11
            ],
            [
                "title" : "The Moon Represents My Heart",
                "album" : "Home Sweet Home (Deluxe Version)",
                "artist" : "Katherine Jenkins",
                "play_count" : 23
            ]
        ] as [[String : Any]]

        for rowValue in dataValues {
            theDatabase.executeUpdate("""
            INSERT INTO songs (
                title,
                album,
                artist,
                play_count
            ) VALUES (
                :title,
                :album,
                :artist,
                :play_count
            )
            """, withParameterDictionary: rowValue)

        }
    }
    
    
    func printSongsTable() throws {
        let results = try theDatabase.executeQuery("""
        SELECT * FROM songs
        """, values: nil)
        printRows(results)
    }
    
    
    /**
        Demonstrates committing a transaction.
     */
    func testTransactionCommit() throws {
        populateRecords()
        
        print("Initial table contents")
        try printSongsTable()
        
        if !theDatabase.beginTransaction() {
            throw theDatabase.lastError()
        }
        try theDatabase.executeUpdate("""
        UPDATE songs SET
            play_count = play_count + 6
        WHERE
            artist = 'Isyana Sarasvati'
        """, values: nil)
        if !theDatabase.commit() {
            throw theDatabase.lastError()
        }
        
        print("Final table contents...")
        try printSongsTable()
    }
    
    
    /**
     Demonstrates rolling back a transaction.
     */
    func testTransactionRollback() throws {
        populateRecords()
        print("Initial table contents...")
        try printSongsTable()
        if !theDatabase.beginTransaction() {
            throw theDatabase.lastError()
        }
        try theDatabase.executeUpdate("""
        UPDATE songs SET
            play_count = play_count + 6
        WHERE
            artist = 'Isyana Sarasvati'
        """, values: nil)
        
        print("The table inside a transaction...")
        try printSongsTable()
        
        if !theDatabase.rollback() {
            throw theDatabase.lastError()
        }
        
        print("The table after rollback...")
        try printSongsTable()
    }
}
