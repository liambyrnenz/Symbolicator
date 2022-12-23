//
//  OptionsHelperTests.swift
//  SymbolicatorLibraryTests
//
//  Created by Liam on 23/12/22.
//

import XCTest
@testable import SymbolicatorLibrary

class OptionsHelperTests: XCTestCase {
    
    var optionsHelper: OptionsHelper!
    
    override func setUp() {
        optionsHelper = OptionsHelper()
    }
    
}

// MARK: Multiple reports option

extension OptionsHelperTests {
    
    func testMultipleReportsOptionShort() throws {
        _ = try optionsHelper.evaluate(["Archive.xcarchive", "-m", "Directory"])
        XCTAssertEqual(optionsHelper.multipleReportsOption, "Directory")
    }
    
    func testMultipleReportsOptionLong() throws {
        _ = try optionsHelper.evaluate(["Archive.xcarchive", "--multi", "Directory"])
        XCTAssertEqual(optionsHelper.multipleReportsOption, "Directory")
    }
    
    func testMultipleReportsOptionRequiresArgument() {
        XCTAssertThrowsError(try optionsHelper.evaluate(["-m"]))
    }
    
}

// MARK: Override output option

extension OptionsHelperTests {
    
    func testOverrideOutputOptionShort() throws {
        _ = try optionsHelper.evaluate(["Archive.xcarchive", "CrashReport.txt", "-o", "Output.txt"])
        XCTAssertEqual(optionsHelper.overrideOutputOption, "Output.txt")
    }
    
    func testOverrideOutputOptionLong() throws {
        _ = try optionsHelper.evaluate(["Archive.xcarchive", "CrashReport.txt", "--output", "Output.txt"])
        XCTAssertEqual(optionsHelper.overrideOutputOption, "Output.txt")
    }
    
    func testOverrideOutputOptionRequiresArgument() {
        XCTAssertThrowsError(try optionsHelper.evaluate(["-o"]))
    }
    
    func testOverrideOutputOptionIncorrectExtension() {
        XCTAssertThrowsError(try optionsHelper.evaluate(["Archive.xcarchive", "CrashReport.txt", "-o", "Output.docx"]))
    }
    
}

// MARK: No archive option

extension OptionsHelperTests {
    
    func testNoArchiveOptionShort() throws {
        _ = try optionsHelper.evaluate(["CrashReport.txt", "-n", "./BCSymbolMaps/", "./dSYMs/"])
        XCTAssertEqual(optionsHelper.noArchiveOption?.0, "./BCSymbolMaps/")
        XCTAssertEqual(optionsHelper.noArchiveOption?.1, "./dSYMs/")
    }
    
    func testNoArchiveOptionLong() throws {
        _ = try optionsHelper.evaluate(["CrashReport.txt", "--no-archive", "./BCSymbolMaps/", "./dSYMs/"])
        XCTAssertEqual(optionsHelper.noArchiveOption?.0, "./BCSymbolMaps/")
        XCTAssertEqual(optionsHelper.noArchiveOption?.1, "./dSYMs/")
    }
    
    func testNoArchiveOptionRequiresArguments() {
        XCTAssertThrowsError(try optionsHelper.evaluate(["-n"]))
    }
    
    func testNoArchiveOptionInvalidDirectories() {
        optionsHelper = OptionsHelper()
        XCTAssertThrowsError(try optionsHelper.evaluate(["CrashReport.txt", "-n", "./NotBCSymbolMaps/", "./dSYMs/"]))
        
        optionsHelper = OptionsHelper()
        XCTAssertThrowsError(try optionsHelper.evaluate(["CrashReport.txt", "-n", "./BCSymbolMaps/", "./NotdSYMs/"]))
    }
    
}

// MARK: Base arguments

extension OptionsHelperTests {
    
    func testMultipleReportsOptionWithTooManyArguments() {
        XCTAssertThrowsError(try optionsHelper.evaluate(["Archive.xcarchive", "-m", "Directory1", "Directory2"]))
    }
    
    func testMultipleReportsOptionIncorrectArchive() {
        XCTAssertThrowsError(try optionsHelper.evaluate(["Archive", "-m", "Directory"]))
    }
    
    func testNoArchiveOptionWithTooManyArguments() {
        XCTAssertThrowsError(try optionsHelper.evaluate(["CrashReport.txt", "-n", "./BCSymbolMaps/", "./dSYMs/", "Argument"]))
    }
    
    func testNoArchiveOptionIncorrectReportExtension() {
        XCTAssertThrowsError(try optionsHelper.evaluate(["CrashReport.docx", "-n", "./BCSymbolMaps/", "./dSYMs/"]))
    }
    
    func testNotEnoughBaseArguments() {
        XCTAssertThrowsError(try optionsHelper.evaluate([]))
    }
    
    func testIncorrectArchiveType() {
        XCTAssertThrowsError(try optionsHelper.evaluate(["Archive", "CrashReport.txt"]))
    }
    
    func testIncorrectReportType() {
        XCTAssertThrowsError(try optionsHelper.evaluate(["Archive.xcarchive", "CrashReport.docx"]))
    }
    
}
