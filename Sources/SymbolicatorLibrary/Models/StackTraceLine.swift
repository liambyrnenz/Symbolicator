//
//  StackTraceLine.swift
//  SymbolicatorLibrary
//
//  Created by Liam on 23/12/22.
//

/// Model form of a line in a crash report stack trace.
public struct StackTraceLine {
    let index: String
    let module: String
    let address: String
    let line: String
}
