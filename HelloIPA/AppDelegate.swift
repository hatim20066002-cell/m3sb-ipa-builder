import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBlue
        let label = UILabel()
        label.text = "Hello IPA"
        label.textColor = .white
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.sizeToFit()
        label.center = viewController.view.center
        viewController.view.addSubview(label)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
