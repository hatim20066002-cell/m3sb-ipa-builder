import Combine
import Foundation
import Security

@MainActor
final class LicenseManager: ObservableObject {
    @Published private(set) var expirationDate: Date?
    @Published private(set) var isActive = false
    @Published private(set) var isBusy = false
    @Published private(set) var message: String?
    @Published private(set) var contactOwner: String?
    @Published var rememberKey = true

    private let service = "com.caosx.pro-license.activation"
    private let keyAccount = "license-key"
    private var lastAttemptAt: Date?

    init() {
        isActive = hasRememberedKey
    }

    var hasRememberedKey: Bool {
        !(string(for: keyAccount) ?? "").isEmpty
    }

    func beginLaunchSession() {
        guard let key = rememberedKey(), !key.isEmpty else {
            isActive = false
            message = "Key required — enter your Caos X - Pro access key"
            return
        }
        verify(key: key, saveOnSuccess: false, showBusy: false)
    }

    func activate(key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isBusy else { return }
        if let lastAttemptAt, Date().timeIntervalSince(lastAttemptAt) < 1 {
            message = "Please wait a moment before trying again"
            return
        }
        lastAttemptAt = Date()
        verify(key: trimmed, saveOnSuccess: rememberKey, showBusy: true)
    }

    func rememberedKey() -> String? { string(for: keyAccount) }

    func refresh() {
        guard let key = rememberedKey(), !key.isEmpty else {
            isActive = false
            message = "Key required — enter your Caos X - Pro access key"
            return
        }
        verify(key: key, saveOnSuccess: false, showBusy: true)
    }

    func deactivate() {
        delete(keyAccount)
        isActive = false
        expirationDate = nil
        contactOwner = nil
        message = "Activation removed from this device"
    }

    private func verify(key: String, saveOnSuccess: Bool, showBusy: Bool) {
        isBusy = showBusy
        if showBusy { message = "Checking Caos X - Pro access key…" }

        APONLicenseSDK.verify(licenseKey: key) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isBusy = false
                switch result {
                case .success(let state) where state.isActive:
                    if saveOnSuccess { self.save(key, for: self.keyAccount) }
                    self.isActive = true
                    self.expirationDate = state.expiresDate
                    self.contactOwner = nil
                    self.message = state.expiresAt.map { "Caos X - Pro activated • valid until \($0)" } ?? "Caos X - Pro activated successfully"
                case .success(let state):
                    self.isActive = false
                    self.expirationDate = nil
                    self.contactOwner = nil
                    self.message = state.message ?? "This Caos X - Pro license is not active"
                case .failure(let error):
                    self.isActive = false
                    self.expirationDate = nil
                    self.contactOwner = nil
                    self.message = error.localizedDescription
                }
            }
        }
    }

    private func string(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func save(_ value: String, for account: String) {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(base as CFDictionary)
        var item = base
        item[kSecValueData as String] = Data(value.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }

    private func delete(_ account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
