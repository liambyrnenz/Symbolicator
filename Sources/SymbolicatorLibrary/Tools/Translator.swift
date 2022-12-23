//
//  Translator.swift
//  SymbolicatorLibrary
//
//  Created by Liam on 23/12/22.
//

import CommandLineUtilities

public enum TranslatorError: Error {
    case filesNotFound(rawLog: String?)
    case genericError(rawLog: String?)
    
    var localizedDescription: String {
        switch self {
        case .filesNotFound:
            return "required symbol files could not be found, check that you are using the correct archive"
        case .genericError:
            return "could not complete operation"
        }
    }
}

/// Entity that performs translating (i.e. de-obfuscating and symbolicating) operations.
///
/// De-obfuscation is the process of mapping symbols back to the build's associated debug symbol
/// (dSYM) files using the bitcode symbol map (BCSymbolMap) files provided in the archive. This
/// operation modifies the dSYM files locally.
///
/// Symbolication is the process of replacing hexadecimal addresses in crash reports with the
/// associated symbols located in the debug symbol (dSYM) files.
///
/// The correct archive for the build that generated the report must be provided, otherwise the
/// debug symbol files will not match up.
public protocol TranslatorProtocol {
    
    /// Take a stack trace line with obfuscated and/or unsymbolicated symbols and produce a new line by running external processes
    /// to generate a new version of the line with corrected symbols.
    ///
    /// - Parameters:
    ///   - line: original stack trace line to modify and return
    ///   - trace: `StackTraceLine` object to mark components of the line for the external processes
    /// - Returns: corrected version of the argument supplied for `line`, or `line` if translation cannot proceed
    /// - Throws: TranslatorError if the underlying processes fail
    func deobfuscateAndSymbolicateLine(_ line: String, withTrace trace: StackTraceLine) throws -> String
    
}

public class Translator: TranslatorProtocol {
    
    private let archive: XCArchive
    private let binaryImages: [BinaryImage]
    
    /// A dictionary of UUIDs and filepaths for dSYMs that have been already re-mapped using their bitcode symbol map.
    ///
    /// Generally, dSYMs are named with the UUID of the binary they correspond to. However, especially with user frameworks,
    /// the dSYMS can be sometimes named with the framework's name instead. This dictionary thus also helps to determine the
    /// actual filename of dSYMS with a given UUID.
    private var bitcodeMappedSymbols: [String: String] = [:]
    
    public init(archive: XCArchive, binaryImages: [BinaryImage]) {
        self.archive = archive
        self.binaryImages = binaryImages
    }
    
    public func deobfuscateAndSymbolicateLine(_ line: String, withTrace trace: StackTraceLine) throws -> String {
        var output = ""
        
        guard let binaryImage = binaryImages.first(where: { $0.moduleName == trace.module }) else {
            return line
        }
        
        // only translate lines where the associated binary image is not a system one
        guard binaryImage.isNonSystemBinaryImage else {
            return line
        }
        
        // set up possible paths for the dSYM to be located at and declare a constant to hold the correct one when it is found
        let uuidDSYMPath = archive.dSYMs + binaryImage.uuid + ".dSYM"
        let namedDSYMPath = archive.dSYMs + binaryImage.fullyQualifiedName() + ".dSYM"
        let dsymPath: String
        
        // try and only do the bitcode mapping once per dSYM
        if let knownDsymPath = bitcodeMappedSymbols[binaryImage.uuid] {
            dsymPath = knownDsymPath
        } else {
            func executeDsymutil(path: String) -> String {
                return TerminalHelper.execute("xcrun dsymutil -symbol-map \"\(archive.bcSymbolMaps)\" \"\(path)\"")
            }
            
            func dsymutilResultNotFound(_ result: String) -> Bool {
                return result.contains("error") && result.contains("No such file or directory")
            }
            
            func dsymutilResultIsError(_ result: String) -> Bool {
                return result.contains("error")
            }
            
            // try and execute dsymutil using the UUID-based path first
            // if that fails, try again using the named path
            // and if that fails, then there must be no dSYM
            let uuidDSYMUtilResult = executeDsymutil(path: uuidDSYMPath)
            if dsymutilResultNotFound(uuidDSYMUtilResult) {
                let namedDSYMUtilResult = executeDsymutil(path: namedDSYMPath)
                if dsymutilResultNotFound(namedDSYMUtilResult) {
                    throw TranslatorError.filesNotFound(rawLog: namedDSYMUtilResult)
                } else if dsymutilResultIsError(namedDSYMUtilResult) {
                    throw TranslatorError.genericError(rawLog: namedDSYMUtilResult)
                } else {
                    dsymPath = namedDSYMPath
                }
            } else if dsymutilResultIsError(uuidDSYMUtilResult) {
                throw TranslatorError.genericError(rawLog: uuidDSYMUtilResult)
            } else {
                dsymPath = uuidDSYMPath
            }
            bitcodeMappedSymbols[binaryImage.uuid] = dsymPath
        }
        
        let atosCommand = "atos -arch \(binaryImage.architecture) -o \"\(dsymPath)/Contents/Resources/DWARF/\(trace.module)\" -l \(binaryImage.loadAddress) \(trace.address)"
        // split the atos output by lines and use only the last actual line
        // as of November 2020, atos started spitting out warnings that were cluttering the output
        // luckily, these could be separated from the actual output via newlines, so just take the last line
        let atosOutputs = TerminalHelper.execute(atosCommand).components(separatedBy: .newlines).filter { $0.count > 0 }
        let atosResult = atosOutputs[atosOutputs.endIndex - 1]
        if atosResult.contains("cannot load symbols") {
            throw TranslatorError.genericError(rawLog: atosResult)
        }
        
        output = line.replacingOccurrences(of: trace.line, with: atosResult)
        
        return output
    }
    
}
