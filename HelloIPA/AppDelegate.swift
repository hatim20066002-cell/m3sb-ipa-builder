import UIKit
import CryptoKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = VerificationViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

private struct VerifyResponse: Decodable {
    let valid: Bool?
    let status: String?
    let message: String?
    let package: String?
    let expiresAt: String?
    enum CodingKeys: String, CodingKey { case valid, status, message, package; case expiresAt = "expires_at" }
}

private final class VerificationViewController: UIViewController {
    private let packageTokenField = UITextField()
    private let licenseKeyField = UITextField()
    private let verifyButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.035, green: 0.055, blue: 0.10, alpha: 1)
        buildView()
    }

    private func buildView() {
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        let icon = makeLabel("◈", size: 54, weight: .bold, color: .systemBlue)
        icon.textAlignment = .center
        let title = makeLabel("M3SB API", size: 30, weight: .bold, color: .white)
        title.textAlignment = .center
        let subtitle = makeLabel("Verify your license to continue", size: 16, weight: .regular, color: .lightGray)
        subtitle.textAlignment = .center

        packageTokenField.placeholder = "Package token"
        licenseKeyField.placeholder = "License key"
        packageTokenField.accessibilityIdentifier = "package-token"
        licenseKeyField.accessibilityIdentifier = "license-key"
        configureField(packageTokenField)
        configureField(licenseKeyField)

        verifyButton.setTitle("Verify and continue", for: .normal)
        verifyButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        verifyButton.setTitleColor(.white, for: .normal)
        verifyButton.backgroundColor = .systemBlue
        verifyButton.layer.cornerRadius = 12
        verifyButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        verifyButton.addTarget(self, action: #selector(verifyTapped), for: .touchUpInside)

        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .systemRed

        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(subtitle)
        stack.addArrangedSubview(spacer(18))
        stack.addArrangedSubview(packageTokenField)
        stack.addArrangedSubview(licenseKeyField)
        stack.addArrangedSubview(verifyButton)
        stack.addArrangedSubview(statusLabel)
        stack.addArrangedSubview(makeLabel("The token and key must belong to the same M3SB package.", size: 12, weight: .regular, color: .gray))
    }

    private func configureField(_ field: UITextField) {
        field.borderStyle = .none
        field.backgroundColor = UIColor(white: 0.10, alpha: 1)
        field.textColor = .white
        field.tintColor = .systemBlue
        field.layer.cornerRadius = 12
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        field.leftViewMode = .always
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.heightAnchor.constraint(equalToConstant: 52).isActive = true
    }

    private func makeLabel(_ text: String, size: CGFloat, weight: UIFont.Weight, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.numberOfLines = 0
        return label
    }

    private func spacer(_ height: CGFloat) -> UIView {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }

    @objc private func verifyTapped() {
        view.endEditing(true)
        let token = packageTokenField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let key = licenseKeyField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !token.isEmpty, !key.isEmpty else { showError("Enter the package token and license key."); return }
        verifyButton.isEnabled = false
        verifyButton.alpha = 0.6
        verify(token: token, key: key)
    }

    private func verify(token: String, key: String) {
        let baseURL = (Bundle.main.object(forInfoDictionaryKey: "M3SB_API_BASE_URL") as? String) ?? "https://api.m3sbapi.shop"
        let secret = (Bundle.main.object(forInfoDictionaryKey: "M3SB_HMAC_SECRET") as? String) ?? ""
        guard !secret.isEmpty, let url = URL(string: baseURL + "/api/sdk/verify") else {
            finishWithError("This build is missing its package security configuration.")
            return
        }
        let deviceID = persistentDeviceID()
        let body: [String: Any] = ["token": token, "key": key, "device_id": deviceID, "device_name": UIDevice.current.model, "hwid": deviceID, "os_info": UIDevice.current.systemVersion]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys]) else { finishWithError("Could not prepare verification request."); return }
        let bodyHash = SHA256.hash(data: bodyData).map { String(format: "%02x", $0) }.joined()
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let nonce = randomNonce()
        let canonical = ["M3SB-API-SIGNATURE-V3", "POST", "/api/sdk/verify", timestamp, nonce, bodyHash, token, key, deviceID].joined(separator: "\n")
        let signature = HMAC<SHA256>.authenticationCode(for: Data(canonical.utf8), using: SymmetricKey(data: Data(secret.utf8))).map { String(format: "%02x", $0) }.joined()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("3", forHTTPHeaderField: "X-M3SB-Signature-Version")
        request.setValue(timestamp, forHTTPHeaderField: "X-M3SB-Timestamp")
        request.setValue(nonce, forHTTPHeaderField: "X-M3SB-Nonce")
        request.setValue(bodyHash, forHTTPHeaderField: "X-M3SB-Body-SHA256")
        request.setValue(signature, forHTTPHeaderField: "X-M3SB-Signature")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error { self.finishWithError("Network error: \(error.localizedDescription)"); return }
                guard let data, let response = try? JSONDecoder().decode(VerifyResponse.self, from: data) else { self.finishWithError("The API returned an invalid response."); return }
                guard response.valid == true else { self.finishWithError(response.message ?? response.status ?? "Verification failed."); return }
                self.showMainScreen(package: response.package ?? "Verified package", expires: response.expiresAt)
            }
        }.resume()
    }

    private func finishWithError(_ message: String) {
        verifyButton.isEnabled = true
        verifyButton.alpha = 1
        showError(message)
    }

    private func showError(_ message: String) {
        statusLabel.text = message
        statusLabel.textColor = .systemRed
    }

    private func showMainScreen(package: String, expires: String?) {
        let controller = UIViewController()
        controller.view.backgroundColor = UIColor(red: 0.035, green: 0.055, blue: 0.10, alpha: 1)
        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 18
        content.alignment = .center
        content.translatesAutoresizingMaskIntoConstraints = false
        let title = makeLabel("Protected content", size: 30, weight: .bold, color: .white)
        title.textAlignment = .center
        let detail = makeLabel("Package: \(package)\n\(expires.map { "Expires: \($0)" } ?? "License verified")", size: 16, weight: .regular, color: .lightGray)
        detail.textAlignment = .center
        let badge = makeLabel("API VERIFIED", size: 14, weight: .bold, color: .systemGreen)
        content.addArrangedSubview(title)
        content.addArrangedSubview(detail)
        content.addArrangedSubview(badge)
        controller.view.addSubview(content)
        NSLayoutConstraint.activate([content.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor), content.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor)])
        window?.rootViewController = controller
    }

    private func persistentDeviceID() -> String {
        let key = "m3sb.device.id"
        if let value = UserDefaults.standard.string(forKey: key) { return value }
        let value = UUID().uuidString
        UserDefaults.standard.set(value, forKey: key)
        return value
    }

    private func randomNonce() -> String {
        let bytes = (0..<18).map { _ in UInt8.random(in: 0...255) }
        return Data(bytes).base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
}
