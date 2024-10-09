//  KeePassium Password Manager
//  Copyright © 2018–2024 KeePassium Labs <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

public final class LicenseManager {
    public static let shared = LicenseManager()
    private static let provisionalLicenseCutoffDate = Date(iso8601string: "2024-02-29T23:59:59Z")!

    private enum LicenseKeyFormat {
        case version1 
        case provisional
        case unknown
    }

    private var cachedLicenseStatus: Bool?
    public func hasActiveBusinessLicense() -> Bool {
        if let cachedLicenseStatus {
            return cachedLicenseStatus
        }

        let licenseStatus = isLicensedForBusiness()
        cachedLicenseStatus = licenseStatus
        return licenseStatus
    }

    internal func checkBusinessLicense() {
        cachedLicenseStatus = isLicensedForBusiness()
    }

    private func isLicensedForBusiness() -> Bool {
        let licenseKey = "v1"
        do {
            return try isValidLicenseV1(licenseKey)
        } catch {
            return false
        }
    }

}

extension LicenseManager {

    private func isValidLicenseV1(_ licenseKey: String) throws -> Bool {
        return true
    }
}
