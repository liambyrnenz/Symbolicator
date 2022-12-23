//
//  XCArchive.swift
//  SymbolicatorLibrary
//
//  Created by Liam on 23/12/22.
//

/// Model form of an Xcode Archive, containing information about the locations of required folders for the symbolication process.
public struct XCArchive {
    let bcSymbolMaps: String
    let dSYMs: String
    
    public init(archiveFilePath: String) {
        self.bcSymbolMaps = archiveFilePath + "/BCSymbolMaps"
        self.dSYMs = archiveFilePath + "/dSYMs/"
    }
    
    public init(bcSymbolMaps: String, dSYMs: String) {
        self.bcSymbolMaps = bcSymbolMaps
        self.dSYMs = dSYMs
    }
}
