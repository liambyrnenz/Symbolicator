//
//  BinaryImage.swift
//  SymbolicatorLibrary
//
//  Created by Liam on 23/12/22.
//

/// Model form of a binary image, found at the bottom of crash report files.
///
/// See https://developer.apple.com/documentation/xcode/examining-the-fields-in-a-crash-report#Binary-Images for more info.
public struct BinaryImage {
    let loadAddress: String
    let moduleName: String
    let architecture: String
    let uuid: String
    let path: String
    
    /// Specifies whether this binary image is for a system library or not.
    let isNonSystemBinaryImage: Bool
    
    /// - Parameters:
    ///   - loadAddress: load address for the binary image
    ///   - moduleName: module name of the binary image, provided exactly as declared in the report
    ///   - architecture: architecture of the binary image
    ///   - uuid: UUID of the binary image that refers to the paired dSYM file (this will be converted to a standard
    ///           format automatically, if possible.)
    ///   - path: filepath of the dSYM on the device
    init(loadAddress: String, moduleName: String, architecture: String, uuid: String, path: String) {
        // simply initialize load address and architecture first
        self.loadAddress = loadAddress
        self.architecture = architecture
        
        // save following information by dissecting module name
        self.isNonSystemBinaryImage = moduleName.starts(with: "+")
        self.moduleName = moduleName.filter({ $0.isLetter })
        
        self.uuid = BinaryImage.createUUIDString(from: uuid)
        self.path = path
    }
    
    private static func createUUIDString(from string: String) -> String {
        var uuidString = string
        
        uuidString = uuidString.filter({ $0.isLetter || $0.isNumber })
        // check that the remaining string of letters and numbers fits the UUID length
        guard uuidString.count == 32 else {
            return string
        }
        
        uuidString.insert("-", at: uuidString.index(uuidString.startIndex, offsetBy: 8))
        uuidString.insert("-", at: uuidString.index(uuidString.startIndex, offsetBy: 13))
        uuidString.insert("-", at: uuidString.index(uuidString.startIndex, offsetBy: 18))
        uuidString.insert("-", at: uuidString.index(uuidString.startIndex, offsetBy: 23))
        
        return uuidString.uppercased()
    }
    
    /// Returns the fully qualified name of the image, e.g. `MyApp.app` or `MyLibrary.framework`.
    func fullyQualifiedName() -> String {
        // the path lists the on-device path to the binary image and the path component second from the end
        // contains the fully qualified name that is sometimes used to name dSYMs
        // e.g. /private/var/containers/Bundle/Application/63CDD4A6-0675-41E5-AB1B-1CA7BB051A9E/MyApplication.app/MyApplication
        let pathComponents = path.components(separatedBy: "/")
        return pathComponents[pathComponents.endIndex - 2]
    }
    
}
