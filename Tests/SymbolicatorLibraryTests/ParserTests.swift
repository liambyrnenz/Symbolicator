//
//  ParserTests.swift
//  SymbolicatorLibraryTests
//
//  Created by Liam on 23/12/22.
//

import XCTest
@testable import SymbolicatorLibrary

class ParserTests: XCTestCase {
    
    func testBinaryImageGeneration() {
        let binaryImages = Parser.generateBinaryImagesReference(from: """
        Binary Images:
        0x0000000100284000 -        0x0000000100763fff +MyApplication arm64  <219132bbc2d03cc9aabdd0df0ed9ab2d> /private/var/containers/Bundle/Application/6DDD326C-75DB-40FD-B3F3-7A45E4EA53E7/MyApplication.app/MyApplication
        0x000000010093c000 -        0x00000001009e3fff +FrameworkA arm64  <548e9f2cfc1a3c82acc9c4461469beec> /private/var/containers/Bundle/Application/6DDD326C-75DB-40FD-B3F3-7A45E4EA53E7/MyApplication.app/Frameworks/FrameworkA.framework/FrameworkA
        0x0000000100a3c000 -        0x0000000100ae7fff +FrameworkB arm64  <8bc859e475f9317cbe260edb5b5b84ce> /private/var/containers/Bundle/Application/6DDD326C-75DB-40FD-B3F3-7A45E4EA53E7/MyApplication.app/Frameworks/FrameworkB.framework/FrameworkB

        """)
        
        XCTAssertEqual(binaryImages.count, 3)
        
        XCTAssertEqual(binaryImages[0].loadAddress, "0x0000000100284000")
        XCTAssertEqual(binaryImages[0].moduleName, "MyApplication")
        XCTAssertEqual(binaryImages[0].architecture, "arm64")
        XCTAssertEqual(binaryImages[0].uuid, "219132BB-C2D0-3CC9-AABD-D0DF0ED9AB2D")
        
        XCTAssertEqual(binaryImages[1].loadAddress, "0x000000010093c000")
        XCTAssertEqual(binaryImages[1].moduleName, "FrameworkA")
        XCTAssertEqual(binaryImages[1].architecture, "arm64")
        XCTAssertEqual(binaryImages[1].uuid, "548E9F2C-FC1A-3C82-ACC9-C4461469BEEC")
        
        XCTAssertEqual(binaryImages[2].loadAddress, "0x0000000100a3c000")
        XCTAssertEqual(binaryImages[2].moduleName, "FrameworkB")
        XCTAssertEqual(binaryImages[2].architecture, "arm64")
        XCTAssertEqual(binaryImages[2].uuid, "8BC859E4-75F9-317C-BE26-0EDB5B5B84CE")
    }
    
    func testSymbolicatingCrashReport() throws {
        let translator = MockTranslator()
        let report = try Parser.generateSymbolicatedCrashReport(from: """
        Incident Identifier: 74d73a9e-32ce-483e-801c-4fa98cf3fd56
        CrashReporter Key:   E465B1AA-5E26-40A3-BE03-F061FD65214E
        Hardware Model:      iPad7,6
        Process:         MyApplication [2460]
        Path:            /private/var/containers/Bundle/Application/6DDD326C-75DB-40FD-B3F3-7A45E4EA53E7/MyApplication.app/MyApplication
        Identifier:      nz.liambyrne.myapplication
        Version:         1.0.0 (10)
        Code Type:       arm64
        Parent Process:  ??? [1]

        Date/Time:       2020-12-09T08:26:57.999Z
        Launch Time:     2020-12-09T03:15:06Z
        OS Version:      iPhone OS 13.4.1 (17E262)
        Report Version:  104

        Exception Type:  SIGTRAP
        Exception Codes: TRAP_BRKPT at 0x1c3b7e5e0
        Crashed Thread:  0

        Thread 0 Crashed:
        0   libswiftCore.dylib                   0x00000001c3b7e5e0 Swift._assertionFailure(_: Swift.StaticString, _: Swift.String, file: Swift.StaticString, line: Swift.UInt, flags: Swift.UInt32) -> Swift.Never + 796
        1   MyApplicationDataAccess              0x0000000100ee479c _hidden#1679_ (__hidden#8070_:186)
        2   MyApplicationDataAccess              0x0000000100fc7e70 _hidden#20946_ (__hidden#1870_:0)
        3   MyApplication                        0x00000001005a2628 _hidden#46492_ (__hidden#57813_:605)
        4   MyApplication                        0x000000010041873c _hidden#1521_ (__hidden#1232_:0)
        5   libdispatch.dylib                    0x00000001b63989a8 _dispatch_call_block_and_release + 20
        6   libdispatch.dylib                    0x00000001b6399524 _dispatch_client_callout + 12
        7   libdispatch.dylib                    0x00000001b634b5b4 _dispatch_main_queue_callback_4CF$VARIANT$mp + 900
        8   CoreFoundation                       0x00000001b6651748 __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__ + 8
        9   CoreFoundation                       0x00000001b664c61c __CFRunLoopRun + 1720
        10  CoreFoundation                       0x00000001b664bc34 CFRunLoopRunSpecific + 420
        11  GraphicsServices                     0x00000001c079538c GSEventRunModal + 156
        12  UIKitCore                            0x00000001ba77e22c UIApplicationMain + 1928
        13  MyApplication                        0x000000010028a9b8 main (__hidden#1230_:11)
        14  libdyld.dylib                        0x00000001b64d3800 start + 0
        """, with: translator)
        
        // MockTranslator doesn't actually perform any translation, it returns a placeholder for any changed line
        // so we look for that
        
        XCTAssertEqual(report, """
        Incident Identifier: 74d73a9e-32ce-483e-801c-4fa98cf3fd56
        CrashReporter Key:   E465B1AA-5E26-40A3-BE03-F061FD65214E
        Hardware Model:      iPad7,6
        Process:         MyApplication [2460]
        Path:            /private/var/containers/Bundle/Application/6DDD326C-75DB-40FD-B3F3-7A45E4EA53E7/MyApplication.app/MyApplication
        Identifier:      nz.liambyrne.myapplication
        Version:         1.0.0 (10)
        Code Type:       arm64
        Parent Process:  ??? [1]

        Date/Time:       2020-12-09T08:26:57.999Z
        Launch Time:     2020-12-09T03:15:06Z
        OS Version:      iPhone OS 13.4.1 (17E262)
        Report Version:  104

        Exception Type:  SIGTRAP
        Exception Codes: TRAP_BRKPT at 0x1c3b7e5e0
        Crashed Thread:  0

        Thread 0 Crashed:
        0   libswiftCore.dylib                   0x00000001c3b7e5e0 Swift._assertionFailure(_: Swift.StaticString, _: Swift.String, file: Swift.StaticString, line: Swift.UInt, flags: Swift.UInt32) -> Swift.Never + 796
        \(MockTranslator.placeholder)
        \(MockTranslator.placeholder)
        \(MockTranslator.placeholder)
        \(MockTranslator.placeholder)
        5   libdispatch.dylib                    0x00000001b63989a8 _dispatch_call_block_and_release + 20
        6   libdispatch.dylib                    0x00000001b6399524 _dispatch_client_callout + 12
        7   libdispatch.dylib                    0x00000001b634b5b4 _dispatch_main_queue_callback_4CF$VARIANT$mp + 900
        8   CoreFoundation                       0x00000001b6651748 __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__ + 8
        9   CoreFoundation                       0x00000001b664c61c __CFRunLoopRun + 1720
        10  CoreFoundation                       0x00000001b664bc34 CFRunLoopRunSpecific + 420
        11  GraphicsServices                     0x00000001c079538c GSEventRunModal + 156
        12  UIKitCore                            0x00000001ba77e22c UIApplicationMain + 1928
        \(MockTranslator.placeholder)
        14  libdyld.dylib                        0x00000001b64d3800 start + 0
        """)
    }
    
}
