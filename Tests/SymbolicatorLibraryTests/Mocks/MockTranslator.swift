//
//  MockTranslator.swift
//  SymbolicatorLibraryTests
//
//  Created by Liam on 23/12/22.
//

@testable import SymbolicatorLibrary

class MockTranslator: TranslatorProtocol {
    
    static let placeholder = "(symbolicated)"
    
    func deobfuscateAndSymbolicateLine(_ line: String, withTrace trace: StackTraceLine) throws -> String {
        return Self.placeholder
    }
    
}
