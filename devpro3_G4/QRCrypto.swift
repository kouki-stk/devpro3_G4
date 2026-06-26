//
//  QRCrypto.swift
//  devpro3_G4
//
//  Created by 齊藤 洸希 on 2026/06/26.
//

import Foundation
import CryptoKit

struct QRCrypto {
    private static let schemePrefix = "devpro3-auth://"
    private static let keyString = "devpro3_G4_Super_Secret_Key_2026"
    private static var symmetricKey: SymmetricKey {
        let keyData = SHA256.hash(data: keyString.data(using: .utf8)!)
        return SymmetricKey(data: keyData)
    }
    
    static func encryptIP(_ ip: String) -> String {
        let normalizedIP = ip.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidIPAddress(normalizedIP),
              let data = normalizedIP.data(using: .utf8),
              let sealedBox = try? AES.GCM.seal(data, using: symmetricKey),
              let combinedData = sealedBox.combined else {
            return ""
        }
        return schemePrefix + combinedData.base64EncodedString()
    }
    
    static func decryptIP(_ encryptedString: String) -> String? {
        let trimmedString = encryptedString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedString.hasPrefix(schemePrefix) else { return nil }
        let base64String = String(trimmedString.dropFirst(schemePrefix.count))
        
        guard let combinedData = Data(base64Encoded: base64String),
              let sealedBox = try? AES.GCM.SealedBox(combined: combinedData),
              let decryptedData = try? AES.GCM.open(sealedBox, using: symmetricKey),
              let ip = String(data: decryptedData, encoding: .utf8),
              isValidIPAddress(ip) else {
            return nil
        }
        return ip
    }
    
    private static func isValidIPAddress(_ ip: String) -> Bool {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let value = Int(part), (0...255).contains(value) else { return false }
            return String(value) == part || part == "0"
        }
    }
}
