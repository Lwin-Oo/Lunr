//
//  UserManager.swift
//  Lunr
//
//  Created by Lwin Oo on 5/23/25.
//

import Foundation
import Combine

class UserManager: ObservableObject {
    static let shared = UserManager()
    @Published var currentUser: User?
    @Published var isUserLoaded = false

    private init() {
        loadUser()
    }

    func saveUser(_ user: User) {
        let url = fileURL(for: user.name)
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(user) {
            try? data.write(to: url)
            currentUser = user
            isUserLoaded = true
        }
    }

    func loadUser() {
        DispatchQueue.global().async {
            let usersFolder = self.userBaseDirectory().appendingPathComponent("users")
            guard let folders = try? FileManager.default.contentsOfDirectory(at: usersFolder, includingPropertiesForKeys: nil),
                  let first = folders.first else {
                DispatchQueue.main.async { self.isUserLoaded = true }
                return
            }

            let profile = first.appendingPathComponent("profile.json")
            guard let data = try? Data(contentsOf: profile),
                  let user = try? JSONDecoder().decode(User.self, from: data) else {
                DispatchQueue.main.async { self.isUserLoaded = true }
                return
            }

            DispatchQueue.main.async {
                self.currentUser = user
                self.isUserLoaded = true
            }
        }
    }

    private func userBaseDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("Lunr")
    }

    private func fileURL(for username: String) -> URL {
        userBaseDirectory()
            .appendingPathComponent("users")
            .appendingPathComponent(username)
            .appendingPathComponent("profile.json")
    }
}
