//
//  main.swift
//  Symbolicator
//
//  Created by Liam on 23/12/22.
//

import CommandLineUtilities
import SymbolicatorLibrary

// MARK: Constant declarations

let standardOutputFilename = "symbolicated.crash"

// MARK: Utility functions

private func generateReport(for file: String, into outputFile: String, inCurrentDirectory: Bool) throws {
    // Start reading in crash report file
    let content = try FileHelper.read(fileAt: file)
    log.write(message: "crash report file read in successfully", category: .info)
    
    // Read the crash report file initially to extract the binary images list into a reference model list
    log.write(message: "parsing binary image references...", category: .info)
    let binaryImages = Parser.generateBinaryImagesReference(from: content)
    log.write(message: "binary images parsed successfully", category: .info)
    
    // Begin the generation of the new crash report
    log.write(message: "generating new crash report with de-obfuscated symbols...", category: .info)
    let translator = Translator(archive: archive, binaryImages: binaryImages)
    
    let writeableContent = try Parser.generateSymbolicatedCrashReport(from: content, with: translator)
    log.write(message: "new crash report generated", category: .info)
    
    log.write(message: "writing new crash report to disk...", category: .info)
    try FileHelper.write(fileContents: writeableContent, into: outputFile, inCurrentDirectory: inCurrentDirectory)
    log.write(message: "de-obfuscated and symbolicated crash report file saved to \"\(outputFile)\"", category: .complete)
}

private func handleFatalError(message: String, rawLog: String? = nil, hints: [String]? = nil) {
    log.write(message: message, category: .error)
    if let rawLog = rawLog {
        log.write(message: rawLog, category: .output)
    }
    for hint in hints ?? [] {
        log.write(message: hint, category: .hint)
    }
    quit()
}

// MARK: Main script

// This app takes at least two arguments, the .xcarchive for the build and the path to the crash report file to translate
var arguments = Array(CommandLine.arguments.dropFirst()) // get rid of "./Symbolicator"

do {
    // Check input arguments for options and remove any that are present
    arguments = try OptionsHelper.shared.evaluate(arguments)
} catch let error as OptionsError {
    switch error {
    case .invalidArguments(let hints):
        handleFatalError(message: error.localizedDescription, hints: hints)
    }
}

// Extract filepath information from command line arguments
let archive: XCArchive
if let noArchiveDirectories = OptionsHelper.shared.noArchiveOption {
    archive = XCArchive(bcSymbolMaps: noArchiveDirectories.0, dSYMs: noArchiveDirectories.1)
} else {
    archive = XCArchive(archiveFilePath: arguments[0])
}

do {
    if let directory = OptionsHelper.shared.multipleReportsOption {
        let command = "find \(directory) -type f \\( -name \"*.txt\" -o -name \"*.crash\" \\)"
        let output = TerminalHelper.execute(command)
        let files = output.components(separatedBy: .newlines) // note that these filepaths are absolute
        
        for file in files.filter({ $0.isEmpty == false }) {
            log.write(message: "proceeding with crash report \(file) in \(directory)", category: .info)
            try generateReport(for: file, into: "\(file)-\(standardOutputFilename)", inCurrentDirectory: false)
        }
        quit()
    }
    
    let crashReportFilePath = arguments[arguments.endIndex - 1]
    log.write(message: "arguments extracted, will proceed to read crash report", category: .info)
    try generateReport(for: crashReportFilePath,
                       into: OptionsHelper.shared.overrideOutputOption ?? standardOutputFilename,
                       inCurrentDirectory: true)
} catch let error as FileError {
    switch error {
    case .readingFailed(let rawLog),
         .writingFailed(let rawLog):
        handleFatalError(message: error.localizedDescription, rawLog: rawLog)
    }
} catch let error as TranslatorError {
    switch error {
    case .filesNotFound(let rawLog),
         .genericError(let rawLog):
        handleFatalError(message: error.localizedDescription, rawLog: rawLog)
    }
} catch {
    log.write(error)
}
