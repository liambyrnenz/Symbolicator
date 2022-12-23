//
//  OptionsHelper.swift
//  SymbolicatorLibrary
//
//  Created by Liam on 23/12/22.
//

import CommandLineUtilities

public class OptionsHelper: OptionsHelperProtocol {
    
    public static let shared = OptionsHelper()
    
    @Option("-m", "--multi")
    public private(set) var multipleReportsOption: String?
    
    @Option("-o", "--output")
    public private(set) var overrideOutputOption: String?
    
    @Option("-n", "--no-archive")
    public private(set) var noArchiveOption: (String, String)?
    
    private let allowedCrashReportExtensions: Set = [".txt", ".crash"]
    private let allowedArchiveFolderNames: Set = ["/BCSymbolMaps", "/BCSymbolMaps/", "/dSYMs", "/dSYMs/"]
    
}
    
// MARK: - Evaluation methods

extension OptionsHelper {
    
    /// Evaluate the arguments passed to the application for any options that need to be kept track of.
    ///
    /// - Parameter arguments: list of arguments passed to the application, excluding the execution command
    /// - Returns: original list of arguments filtered of any options and their parameters
    /// - Throws: OptionsError if options are malformed
    public func evaluate(_ arguments: [String]) throws -> [String] {
        var arguments = arguments // make mutable for inout evaluation methods
        
        // try and evaluate each type of option set in turn, removing themselves if they are present afterwards
        try evaluateMultipleReportsArguments(&arguments)
        try evaluateOverrideOutputOption(&arguments)
        try evaluateNoArchiveOption(&arguments)
        try evaluateBaseArguments(&arguments)
        
        return arguments
    }
    
}

extension OptionsHelper {
    
    /// Evaluate the given arguments for the presence of the multiple reports option.
    ///
    /// - Parameters:
    ///   - arguments: arguments list from `evaluate(_:)`
    /// - Throws: OptionsError if options are malformed
    private func evaluateMultipleReportsArguments(_ arguments: inout [String]) throws {
        guard
            let providedOption = try providedOption(in: arguments, from: $multipleReportsOption),
            let optionIndex = arguments.firstIndex(of: providedOption)
            else {
                return
        }
        let reportDirectoryIndex = optionIndex + 1
        
        // check that a filename has been provided
        if arguments.indices.contains(reportDirectoryIndex) == false {
            throw OptionsError.invalidArguments(hints: ["please ensure that a directory is specified"])
        }
        
        multipleReportsOption = arguments[reportDirectoryIndex]
        log.write(message: "multiple reports mode enabled, will create reports for all crash reports in directory \(arguments[reportDirectoryIndex])", category: .option)
        
        remove([providedOption, arguments[reportDirectoryIndex]], fromArguments: &arguments)
    }
    
    /// Evaluate the given arguments for the presence of the output filename override option.
    ///
    /// - Parameters:
    ///   - arguments: arguments list from `evaluate(_:)`
    /// - Throws: OptionsError if options are malformed
    private func evaluateOverrideOutputOption(_ arguments: inout [String]) throws {
        guard
            let providedOption = try providedOption(in: arguments, from: $overrideOutputOption),
            let optionIndex = arguments.firstIndex(of: providedOption)
            else {
                return
        }
        let fileNameIndex = optionIndex + 1
        
        // check that a filename has been provided
        if arguments.indices.contains(fileNameIndex) == false {
            throw OptionsError.invalidArguments(hints: ["please ensure that a filename is specified"])
        }
        
        guard allowedCrashReportExtensions.contains(where: { arguments[fileNameIndex].hasSuffix($0) }) else {
            throw OptionsError.invalidArguments(hints: ["have you ensured your output filename has one of the following extensions? \(allowedCrashReportExtensions)"])
        }
        
        overrideOutputOption = arguments[fileNameIndex]
        log.write(message: "override output filename provided, will output to \"\(arguments[fileNameIndex])\"", category: .option)
        
        remove([providedOption, arguments[fileNameIndex]], fromArguments: &arguments)
    }
    
    /// Evaluate the given arguments for the presence of the no archive option.
    ///
    /// - Parameters:
    ///   - arguments: arguments list from `evaluate(_:)`
    /// - Throws: OptionsError if options are missing or malformed
    private func evaluateNoArchiveOption(_ arguments: inout [String]) throws {
        guard
            let providedOption = try providedOption(in: arguments, from: $noArchiveOption),
            let optionIndex = arguments.firstIndex(of: providedOption)
            else {
                return
        }
        let symbolMapsDirectoryIndex = optionIndex + 1
        let dSYMsDirectoryIndex = optionIndex + 2
        
        if arguments.indices.contains(symbolMapsDirectoryIndex) == false || arguments.indices.contains(dSYMsDirectoryIndex) == false {
            throw OptionsError.invalidArguments(hints: ["please ensure that BCSymbolMaps and dSYMs directory paths are specified"])
        }
        
        guard
            allowedArchiveFolderNames.contains(where: { arguments[symbolMapsDirectoryIndex].hasSuffix($0) }),
            allowedArchiveFolderNames.contains(where: { arguments[dSYMsDirectoryIndex].hasSuffix($0) }) else {
                throw OptionsError.invalidArguments(hints: ["are you using correct folders (BCSymbolMaps and dSYMs)?"])
        }
        
        noArchiveOption = (arguments[symbolMapsDirectoryIndex], arguments[dSYMsDirectoryIndex])
        log.write(message: "no archive mode enabled, using BCSymbolMaps directory \(arguments[symbolMapsDirectoryIndex]) and dSYMs directory \(arguments[dSYMsDirectoryIndex])", category: .option)
        
        remove([providedOption, arguments[symbolMapsDirectoryIndex], arguments[dSYMsDirectoryIndex]], fromArguments: &arguments)
    }
    
    /// Evaluate the given arguments for the presence of the required base arguments.
    ///
    /// - Parameter arguments: arguments list from `evaluate(_:)`
    /// - Throws: OptionsError if arguments are missing or malformed
    private func evaluateBaseArguments(_ arguments: inout [String]) throws {
        removeAllOptions(from: &arguments)
        
        if multipleReportsOption != nil {
            guard
                arguments.count == 1,
                arguments[0].hasSuffix(".xcarchive") else {
                    throw OptionsError.invalidArguments(hints: [
                        "check that you have provided a valid archive file and directory",
                        "check that you are referring to the archive directly (no trailing \"/\")"
                        ]
                    )
            }
            return
        }
        
        if noArchiveOption != nil {
            guard
                arguments.count == 1,
                allowedCrashReportExtensions.contains(where: { arguments[0].hasSuffix($0) }) else {
                    throw OptionsError.invalidArguments(hints: [
                        "check that you have provided a valid crash report file with one of these extensions: \(allowedCrashReportExtensions)"
                    ])
            }
            return
        }
        
        guard
            arguments.count == 2,
            arguments[0].hasSuffix(".xcarchive"),
            allowedCrashReportExtensions.contains(where: { arguments[1].hasSuffix($0) })
            else {
                throw OptionsError.invalidArguments(hints: [
                    "Symbolicator requires at least two arguments (archive and crash report file), please try again",
                    "are you using XCode archives and crash report files with one of these extensions? \(allowedCrashReportExtensions)",
                    "check that you are referring to the archive directly (no trailing \"/\")"
                ])
        }
    }
    
}
