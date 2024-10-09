//  KeePassium Password Manager
//  Copyright © 2018–2024 KeePassium Labs <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.


public final class DomainNameHelper {

    public func parse(url: URL) -> String? {
        guard let host = url.host else {
            return nil
        }
        return host
    }

    public func parse(host: String) -> String? {
        return host
    }

    public func getMainDomain(url: URL?) -> String? {
        return  url?.host
    }

    public func getMainDomain(host: String?) -> String? {
        return host
    }
}

