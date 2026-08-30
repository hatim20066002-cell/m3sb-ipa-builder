import UIKit
import CryptoKit
import Security

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = GateViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

private struct M3SBConfig {
    static let baseURL = (Bundle.main.object(forInfoDictionaryKey: "M3SB_API_BASE_URL") as? String) ?? "https://api.m3sbapi.shop"
    static let packageName = (Bundle.main.object(forInfoDictionaryKey: "M3SB_PACKAGE_NAME") as? String) ?? "M3SB"
    static let token = (Bundle.main.object(forInfoDictionaryKey: "M3SB_PACKAGE_TOKEN") as? String) ?? ""
    static let secret = (Bundle.main.object(forInfoDictionaryKey: "M3SB_HMAC_SECRET") as? String) ?? ""
    static let apiVersion = "1.1.0"
    static let owner = "m3sbffxx"
    static let heartbeatSeconds: TimeInterval = 300
}

private struct LicenseReply {
    let valid: Bool
    let status: String
    let package: String
    let license: String
    let expires: String?
    let deviceHash: String?
    let devicesLeft: Int?
    let message: String?
    let telegram: String?
    let sigV2: String?
    let raw: [String: Any]
}

private enum KeychainStore {
    static let service = "com.m3sb.api.instance.v1"
    static func get(_ account: String) -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account, kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    static func set(_ value: String, _ account: String) {
        let base: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
        SecItemDelete(base as CFDictionary)
        var item = base
        item[kSecValueData as String] = Data(value.utf8)
        SecItemAdd(item as CFDictionary, nil)
    }
    static func remove(_ account: String) {
        SecItemDelete([kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account] as CFDictionary)
    }
}

private enum M3BSCrypto {
    static func sha256(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
    static func canonicalJSON(_ value: Any) -> String {
        if value is NSNull { return "null" }
        if let b = value as? Bool { return b ? "true" : "false" }
        if let s = value as? String { return String(data: try! JSONSerialization.data(withJSONObject: s), encoding: .utf8)! }
        if let n = value as? NSNumber { return n.stringValue }
        if let a = value as? [Any] { return "[" + a.map(canonicalJSON).joined(separator: ",") + "]" }
        if let d = value as? [String: Any] { return "{" + d.keys.sorted().map { canonicalJSON($0) + ":" + canonicalJSON(d[$0]!) }.joined(separator: ",") + "}" }
        return "null"
    }
    static func hmac(_ string: String, secret: String) -> String {
        HMAC<SHA256>.authenticationCode(for: Data(string.utf8), using: SymmetricKey(data: Data(secret.utf8))).map { String(format: "%02x", $0) }.joined()
    }
    static func headers(body: [String: Any], key: String, device: String) -> [String: String] {
        let data = try! JSONSerialization.data(withJSONObject: body, options: [.sortedKeys, .withoutEscapingSlashes])
        let hash = sha256(data)
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let nonce = UUID().uuidString.replacingOccurrences(of: "-", with: "") + "Aa"
        let canonical = ["M3SB-API-SIGNATURE-V3", "POST", "/api/sdk/verify", timestamp, nonce, hash, M3SBConfig.token, key, device].joined(separator: "\n")
        return ["X-M3SB-Signature-Version": "3", "X-M3SB-Timestamp": timestamp, "X-M3SB-Nonce": nonce, "X-M3SB-Body-SHA256": hash, "X-M3SB-Signature": hmac(canonical, secret: M3SBConfig.secret)]
    }
    static func checkHeaders(body: [String: Any], key: String, device: String) -> [String: String] {
        let data = try! JSONSerialization.data(withJSONObject: body, options: [.sortedKeys, .withoutEscapingSlashes])
        let hash = sha256(data)
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let nonce = UUID().uuidString.replacingOccurrences(of: "-", with: "") + "Bb"
        let canonical = ["M3SB-API-SIGNATURE-V3", "POST", "/api/sdk/check", timestamp, nonce, hash, M3SBConfig.token, key, device].joined(separator: "\n")
        return ["X-M3SB-Signature-Version": "3", "X-M3SB-Timestamp": timestamp, "X-M3SB-Nonce": nonce, "X-M3SB-Body-SHA256": hash, "X-M3SB-Signature": hmac(canonical, secret: M3SBConfig.secret)]
    }
    static func responseIsTrusted(_ json: [String: Any]) -> Bool {
        guard let signature = json["sig_v2"] as? String, !signature.isEmpty else { return false }
        let fields = ["valid", "status", "license", "device_hash", "expires_at", "devices_left", "allow_inject", "ts"]
        let payload = fields.map { field -> String in
            guard let value = json[field], !(value is NSNull) else { return "\(field)=" }
            if let bool = value as? Bool { return "\(field)=\(bool ? "true" : "false")" }
            return "\(field)=\(value)"
        }.joined(separator: "&")
        return hmac(payload, secret: M3SBConfig.secret) == signature
    }
}

private final class GateViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let successIcon = UIImageView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let keyField = UITextField()
    private let actionButton = UIButton(type: .system)
    private let secondaryButton = UIButton(type: .system)
    private var heartbeat: Timer?
    private var licenseKey = ""
    private var deviceID: String { if let x = KeychainStore.get("device-id") { return x }; let x = UUID().uuidString; KeychainStore.set(x, "device-id"); return x }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.055, alpha: 1)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        build()
        start()
    }
    deinit { heartbeat?.invalidate(); NotificationCenter.default.removeObserver(self) }

    private func build() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        stack.axis = .vertical; stack.alignment = .center; stack.spacing = 14; stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 30),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -30),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 38),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -30),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -60)
        ])
        spinner.color = .lightGray
        successIcon.image = UIImage(systemName: "app.fill")
        successIcon.tintColor = .systemBlue
        successIcon.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.18)
        successIcon.layer.cornerRadius = 28
        successIcon.clipsToBounds = true
        successIcon.contentMode = .center
        successIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 36, weight: .semibold)
        successIcon.widthAnchor.constraint(equalToConstant: 86).isActive = true
        successIcon.heightAnchor.constraint(equalToConstant: 86).isActive = true
        titleLabel.textColor = .white; titleLabel.font = .systemFont(ofSize: 23, weight: .semibold); titleLabel.textAlignment = .center
        detailLabel.textColor = .lightGray; detailLabel.font = .systemFont(ofSize: 15); detailLabel.textAlignment = .center; detailLabel.numberOfLines = 0
        keyField.placeholder = "License key"; keyField.textColor = .white; keyField.tintColor = .systemBlue; keyField.backgroundColor = UIColor(white: 0.12, alpha: 1); keyField.layer.cornerRadius = 16; keyField.layer.borderWidth = 1; keyField.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor; keyField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1)); keyField.leftViewMode = .always; keyField.autocapitalizationType = .none; keyField.autocorrectionType = .no; keyField.returnKeyType = .done; keyField.addTarget(self, action: #selector(keySubmitted), for: .editingDidEndOnExit); keyField.heightAnchor.constraint(equalToConstant: 54).isActive = true; keyField.widthAnchor.constraint(equalToConstant: 320).isActive = true
        actionButton.setTitleColor(.white, for: .normal); actionButton.backgroundColor = .systemBlue; actionButton.layer.cornerRadius = 17; actionButton.layer.shadowColor = UIColor.systemBlue.cgColor; actionButton.layer.shadowOpacity = 0.35; actionButton.layer.shadowRadius = 14; actionButton.layer.shadowOffset = CGSize(width: 0, height: 7); actionButton.heightAnchor.constraint(equalToConstant: 54).isActive = true; actionButton.widthAnchor.constraint(equalToConstant: 230).isActive = true; actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        secondaryButton.setTitleColor(.systemBlue, for: .normal); secondaryButton.addTarget(self, action: #selector(contactOwner), for: .touchUpInside)
        stack.addArrangedSubview(spinner); stack.addArrangedSubview(successIcon); stack.addArrangedSubview(titleLabel); stack.addArrangedSubview(detailLabel); stack.addArrangedSubview(keyField); stack.addArrangedSubview(actionButton); stack.addArrangedSubview(secondaryButton)
    }

    @objc private func keySubmitted() { actionTapped() }

    @objc private func keyboardChanged(_ notification: Notification) {
        guard let info = notification.userInfo, let endFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let converted = view.convert(endFrame, from: nil)
        let overlap = max(0, view.bounds.maxY - converted.minY)
        let duration = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        let curveRaw = (info[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 7
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)
        UIView.animate(withDuration: duration, delay: 0, options: [options, .beginFromCurrentState]) {
            self.scrollView.contentInset.bottom = overlap + 24
            self.scrollView.verticalScrollIndicatorInsets.bottom = overlap + 24
            if self.keyField.isFirstResponder {
                let rect = self.actionButton.convert(self.actionButton.bounds, to: self.scrollView).insetBy(dx: 0, dy: -18)
                self.scrollView.scrollRectToVisible(rect, animated: false)
            }
        }
    }

    private func animateState(_ changes: @escaping () -> Void) {
        UIView.transition(with: view, duration: 0.22, options: [.transitionCrossDissolve, .beginFromCurrentState, .allowAnimatedContent], animations: changes)
    }

    private func start() {
        successIcon.isHidden = true; titleLabel.text = "M3SB API"; detailLabel.text = "Version: \(M3SBConfig.apiVersion)"; keyField.isHidden = true; actionButton.isHidden = true; secondaryButton.isHidden = true; spinner.startAnimating()
        if let saved = KeychainStore.get("license-key"), !saved.isEmpty { licenseKey = saved; showLoading("APIServer"); verify(saved, save: false) } else { showKeyRequired() }
    }
    private func showLoading(_ text: String) { animateState { self.successIcon.isHidden = true; self.spinner.startAnimating(); self.titleLabel.text = text; self.titleLabel.textColor = .white; self.titleLabel.font = .systemFont(ofSize: 23, weight: .semibold); self.detailLabel.text = "Version: \(M3SBConfig.apiVersion)"; self.keyField.isHidden = true; self.actionButton.isHidden = true; self.secondaryButton.isHidden = true } }
    private func showKeyRequired() { animateState { self.successIcon.isHidden = true; self.spinner.stopAnimating(); self.titleLabel.text = "Key required"; self.titleLabel.textColor = .white; self.titleLabel.font = .systemFont(ofSize: 23, weight: .semibold); self.detailLabel.text = "Enter your M3SB license key"; self.keyField.isHidden = false; self.actionButton.isHidden = false; self.actionButton.setTitle("Verify", for: .normal); self.secondaryButton.isHidden = false; self.secondaryButton.setTitle("Contact Owner…", for: .normal) } }
    private func showError(_ status: String, message: String?) { animateState { self.successIcon.isHidden = true; self.spinner.stopAnimating(); self.keyField.isHidden = false; self.actionButton.isHidden = false; self.actionButton.setTitle("Try again", for: .normal); self.secondaryButton.isHidden = false; self.secondaryButton.setTitle("Contact Owner…", for: .normal); self.titleLabel.text = status == "package_off" ? "Package off" : status == "key_not_found" ? "Key required" : "Verification failed"; self.titleLabel.textColor = .systemRed; self.titleLabel.font = .systemFont(ofSize: 23, weight: .semibold); self.detailLabel.text = message ?? "The server rejected this request." } }

    @objc private func actionTapped() { let key = keyField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""; guard !key.isEmpty else { detailLabel.text = "Enter your M3SB license key"; return }; licenseKey = key; showLoading("Package initializing"); verify(key, save: true) }
    @objc private func contactOwner() { guard let url = URL(string: "https://t.me/\(M3SBConfig.owner)") else { return }; UIApplication.shared.open(url) }

    private func verify(_ key: String, save: Bool) {
        guard !M3SBConfig.token.isEmpty, !M3SBConfig.secret.isEmpty, let url = URL(string: M3SBConfig.baseURL + "/api/sdk/verify") else { showError("Configuration error", message: "M3SB package configuration is missing."); return }
        let body: [String: Any] = ["token": M3SBConfig.token, "key": key, "device_id": deviceID, "udid": M3BSCrypto.sha256(Data(deviceID.utf8)), "device_name": UIDevice.current.name, "system_info": "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)", "os_info": UIDevice.current.systemVersion]
        var request = URLRequest(url: url); request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type"); request.setValue("APON/3.0 (iOS IPA)", forHTTPHeaderField: "X-APON-Client"); M3BSCrypto.headers(body: body, key: key, device: deviceID).forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }; request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys, .withoutEscapingSlashes]); request.timeoutInterval = 20
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in DispatchQueue.main.async { guard let self else { return }; guard error == nil, let data, let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { self.showError("Connection failed", message: error?.localizedDescription); return }; let reply = self.parse(json); guard reply.valid else { self.showError(reply.status, message: reply.message); return }; if !M3BSCrypto.responseIsTrusted(json) { self.showError("Invalid server response", message: "The response signature could not be verified."); return }; if save { KeychainStore.set(key, "license-key") }; self.showSuccess(reply) } }.resume()
    }

    private func parse(_ json: [String: Any]) -> LicenseReply { LicenseReply(valid: json["valid"] as? Bool ?? false, status: json["status"] as? String ?? "unknown", package: json["package"] as? String ?? M3SBConfig.packageName, license: json["license"] as? String ?? "", expires: json["expires_at"] as? String, deviceHash: json["device_hash"] as? String, devicesLeft: json["devices_left"] as? Int, message: json["message"] as? String, telegram: json["telegram_username"] as? String, sigV2: json["sig_v2"] as? String, raw: json) }
    private func showSuccess(_ reply: LicenseReply) {
        animateState {
            self.spinner.stopAnimating()
            self.successIcon.isHidden = false
            self.successIcon.tintColor = .systemGreen
            self.keyField.isHidden = true
            self.actionButton.isHidden = true
            self.secondaryButton.isHidden = false
            self.secondaryButton.setTitle("Tap to close", for: .normal)
            self.titleLabel.text = "✓"
            self.titleLabel.textColor = .systemGreen
            self.titleLabel.font = .systemFont(ofSize: 58, weight: .regular)
            self.detailLabel.text = "\(reply.package)\nExpiry date: \(reply.expires ?? "Unlimited")\nDevice: \(UIDevice.current.model) | System version: \(UIDevice.current.systemVersion)\nAPIServer: \(M3SBConfig.apiVersion)"
            self.startHeartbeat()
        }
    }
    private func startHeartbeat() { heartbeat?.invalidate(); heartbeat = Timer.scheduledTimer(withTimeInterval: M3SBConfig.heartbeatSeconds, repeats: true) { [weak self] _ in self?.check() } }
    private func check() { guard !licenseKey.isEmpty, let url = URL(string: M3SBConfig.baseURL + "/api/sdk/check") else { return }; let body: [String: Any] = ["token": M3SBConfig.token, "key": licenseKey, "device_id": deviceID]; var request = URLRequest(url: url); request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type"); M3BSCrypto.checkHeaders(body: body, key: licenseKey, device: deviceID).forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }; request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys, .withoutEscapingSlashes]); URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in guard let data, let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any], json["valid"] as? Bool == true else { DispatchQueue.main.async { self?.showError("Verification required", message: "The license is no longer valid."); KeychainStore.remove("license-key") }; return }; if !M3BSCrypto.responseIsTrusted(json) { DispatchQueue.main.async { self?.showError("Invalid server response", message: "The response signature could not be verified.") } } }.resume() }
}
