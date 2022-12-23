//
//  Parser.swift
//  SymbolicatorLibrary
//
//  Created by Liam on 23/12/22.
//

public class Parser {
    
    // Note that the Parser is particularly susceptible to fatal "index out of range" errors.
    // This is because it greatly assumes the format of an iOS crash report. These cannot be
    // caught using traditional do/catch and so the Parser has no specific errors for when
    // parsing fails.
    
    /// Generate a list of binary image models from the given crash file content.
    ///
    /// - Parameter content: text contents from crash file
    /// - Returns: list of `BinaryImage` models with populated data
    public static func generateBinaryImagesReference(from content: String) -> [BinaryImage] {
        var output: [BinaryImage] = []
        
        let images = content.components(separatedBy: "Binary Images:\n")[1].components(separatedBy: .newlines)
        for line in images {
            let tokens = line.components(separatedBy: .whitespaces).filter({ $0.count > 0 })
            
            if tokens.count == 0 || tokens[0] == "EOF" { // for iOS 13 reports
                continue
            }
            
            // note that some tokens are deliberately skipped
            let loadAddress = tokens[0]
            let moduleName = tokens[3]
            let architecture = tokens[4]
            let uuid = tokens[5]
            let path = tokens[tokens.endIndex - 1]
            output.append(BinaryImage(loadAddress: loadAddress, moduleName: moduleName, architecture: architecture, uuid: uuid, path: path))
        }
        
        return output
    }
    
    /// Parse the given crash file contents and produce new contents with de-obfuscated and symbolicated details.
    ///
    /// - Parameters:
    ///   - content: crash report file contents
    ///   - translator: instance of `Translator` to generate de-obfuscated and symbolicated lines
    /// - Returns: new crash report contents in String form
    /// - Throws: `TranslatorError` from the given translator if the operation failed, to be handled at the appropriate logging level
    public static func generateSymbolicatedCrashReport(from content: String, with translator: TranslatorProtocol) throws -> String {
        var output: [String] = []
        
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let tokens = line.components(separatedBy: .whitespaces).filter({ $0.count > 0 })
            if tokens.isEmpty {
                output.append("") // preserve empty line
                continue
            }
            
            // Assume the first token for a valid stack trace line is the index
            // If we cannot find the index, keep the line since we don't need to change anything
            if Int(tokens[0]) == nil {
                output.append(line)
                continue
            }
            
            // Should be safe to capture variables from tokens now
            let index = tokens[0]
            let module = tokens[1]
            let address = tokens[2]
            let callLine = tokens.suffix(from: 3).joined(separator: " ")
            
            // attempt to translate any line that is obfuscated or unsymbolicated, the translator will decide whether to proceed
            // based off its dependencies
            if callLine.contains("hidden#") || callLine.starts(with: "0x") {
                let stackTraceLine = StackTraceLine(index: index, module: module, address: address, line: callLine)
                let translation = try translator.deobfuscateAndSymbolicateLine(line, withTrace: stackTraceLine)
                output.append(translation)
            } else {
                output.append(line)
            }
        }
        
        return output.joined(separator: "\n")
    }
    
}
