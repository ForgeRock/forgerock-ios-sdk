//
//  FRAStringUtil.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

extension String {
    func insertSpace(at: Int) -> String {
        let index = self.index(self.startIndex, offsetBy: at)
        return self[..<index] + " " + self[index...]
    }
}
