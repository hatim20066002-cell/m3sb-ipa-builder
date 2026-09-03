import UIKit
import Security

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = ActivationViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

private enum ActivationConfig {
    // This is intentionally local-only: there is no API server or network request.
    static let accessKey = "M3SBxYAGAMI"
    static let appTitle = "External IOS"
}

private enum KeychainStore {
    static let service = "com.m3sb.external-ios"
    static let account = "activated"

    static func isActivated() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else { return false }
        return value == ActivationConfig.accessKey
    }

    static func activate() {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(base as CFDictionary)
        var item = base
        item[kSecValueData as String] = Data(ActivationConfig.accessKey.utf8)
        SecItemAdd(item as CFDictionary, nil)
    }
}

private final class NetworkBackgroundView: UIView {
    private let lines = CAShapeLayer()
    private let dots = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        lines.strokeColor = UIColor.white.withAlphaComponent(0.14).cgColor
        lines.fillColor = UIColor.clear.cgColor
        lines.lineWidth = 0.65
        dots.fillColor = UIColor.white.withAlphaComponent(0.54).cgColor
        layer.addSublayer(lines)
        layer.addSublayer(dots)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let points = stride(from: CGFloat(-40), to: bounds.width + 80, by: CGFloat(86)).map {
            CGPoint(x: $0 + CGFloat((Int($0) * 17) % 42), y: bounds.height * 0.18 + CGFloat((Int($0) * 31) % max(1, Int(bounds.height * 0.62))))
        }
        let path = UIBezierPath()
        let dotPath = UIBezierPath()
        for (index, point) in points.enumerated() {
            dotPath.append(UIBezierPath(ovalIn: CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4)))
            if index > 0 {
                path.move(to: point)
                path.addLine(to: points[index - 1])
            }
            if index + 2 < points.count {
                path.move(to: point)
                path.addLine(to: points[index + 2])
            }
        }
        lines.path = path.cgPath
        dots.path = dotPath.cgPath
    }
}

private final class ActivationViewController: UIViewController, UITextFieldDelegate {
    private let background = NetworkBackgroundView()
    private let card = UIView()
    private let keyField = UITextField()
    private let continueButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let refreshButton = UIButton(type: .system)
    private let activity = UIActivityIndicatorView(style: .medium)
    private var isActivated = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        buildInterface()
        if KeychainStore.isActivated() { showActivated() } else { showActivationForm() }
    }

    private func buildInterface() {
        background.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(background)
        NSLayoutConstraint.activate([
            background.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            background.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            background.topAnchor.constraint(equalTo: view.topAnchor),
            background.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let header = UILabel()
        header.text = ActivationConfig.appTitle
        header.textColor = .white
        header.font = .systemFont(ofSize: 31, weight: .bold)
        header.textAlignment = .center
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        configureIconButton(refreshButton, symbol: "arrow.triangle.2.circlepath")
        configureIconButton(closeButton, symbol: "xmark")
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(refreshButton)
        view.addSubview(closeButton)

        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor(white: 0.095, alpha: 0.96)
        card.layer.cornerRadius = 28
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.23).cgColor
        card.layer.borderWidth = 1
        view.addSubview(card)

        let eyebrow = UILabel()
        eyebrow.text = "Best External"
        eyebrow.textColor = UIColor.white.withAlphaComponent(0.52)
        eyebrow.font = .systemFont(ofSize: 19, weight: .semibold)
        eyebrow.textAlignment = .center

        let title = UILabel()
        title.text = "Welcome back"
        title.textColor = .white
        title.font = .systemFont(ofSize: 42, weight: .bold)
        title.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = "Enter your access key to continue."
        subtitle.textColor = UIColor.white.withAlphaComponent(0.64)
        subtitle.font = .systemFont(ofSize: 23, weight: .semibold)
        subtitle.textAlignment = .center

        keyField.placeholder = "Enter your key"
        keyField.attributedPlaceholder = NSAttributedString(string: "Enter your key", attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.42)])
        keyField.textColor = .white
        keyField.font = .systemFont(ofSize: 24, weight: .semibold)
        keyField.tintColor = .white
        keyField.backgroundColor = UIColor(white: 0.055, alpha: 1)
        keyField.layer.cornerRadius = 23
        keyField.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        keyField.layer.borderWidth = 1
        keyField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 25, height: 1))
        keyField.leftViewMode = .always
        keyField.autocapitalizationType = .none
        keyField.autocorrectionType = .no
        keyField.returnKeyType = .done
        keyField.delegate = self

        continueButton.setTitle("Continue", for: .normal)
        continueButton.setTitleColor(.black, for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 25, weight: .bold)
        continueButton.backgroundColor = UIColor(white: 0.91, alpha: 1)
        continueButton.layer.cornerRadius = 23
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        statusLabel.textColor = UIColor.systemRed.withAlphaComponent(0.95)
        statusLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        activity.color = .white
        activity.hidesWhenStopped = true

        let stack = UIStackView(arrangedSubviews: [eyebrow, title, subtitle, keyField, continueButton, statusLabel, activity])
        stack.axis = .vertical
        stack.spacing = 18
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            header.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            refreshButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            refreshButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -76),
            closeButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 35),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -35),
            card.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 112),
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 555),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 34),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -34),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 43),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -35),
            keyField.heightAnchor.constraint(equalToConstant: 92),
            continueButton.heightAnchor.constraint(equalToConstant: 92),
            activity.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private func configureIconButton(_ button: UIButton, symbol: String) {
        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.tintColor = UIColor.white.withAlphaComponent(0.58)
        button.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
    }

    private func showActivationForm() {
        isActivated = false
        keyField.isHidden = false
        continueButton.isHidden = false
        statusLabel.text = nil
        refreshButton.isHidden = false
    }

    private func showActivated() {
        isActivated = true
        keyField.isHidden = true
        continueButton.isHidden = true
        statusLabel.textColor = UIColor.systemGreen
        statusLabel.text = "Activated successfully"
        refreshButton.isHidden = true
    }

    @objc private func continueTapped() {
        let entered = keyField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !entered.isEmpty else {
            statusLabel.text = "Enter your access key to continue."
            return
        }
        activity.startAnimating()
        continueButton.isEnabled = false
        statusLabel.text = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self else { return }
            self.activity.stopAnimating()
            self.continueButton.isEnabled = true
            if entered == ActivationConfig.accessKey {
                KeychainStore.activate()
                self.showActivated()
            } else {
                self.statusLabel.text = "Invalid access key."
            }
        }
    }

    @objc private func refreshTapped() {
        keyField.text = nil
        statusLabel.text = nil
        keyField.becomeFirstResponder()
    }

    @objc private func closeTapped() {
        view.endEditing(true)
        if isActivated { showActivationForm() }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        continueTapped()
        return true
    }
}
