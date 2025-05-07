//
//  UserManager.swift
//  FitFlow
//
//  Created by Carlos Esteve Fernández on 15/4/25.
//

import Foundation
import SwiftUI

class UserManager: ObservableObject {
    @AppStorage("userName") var userName: String = ""
    @AppStorage("userEmail") var userEmail: String = ""

    func save(name: String, email: String) {
        userName = name
        userEmail = email
    }
}
