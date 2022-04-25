//
// Created by 赵江明 on 2022/3/3.
// Copyright (c) 2022 北京挖趣智慧有限公司. All rights reserved.
//


import UIKit

open class VVRoutesUtil {
    // MARK: - public methods

    public class func push(_ vc: UIViewController) {
        let nc = currentNavigationController()
        nc.pushViewController(vc, animated: true);
    }

    public class func present(_ vc: UIViewController) {
        let vc = currentTopViewController()
        vc.present(vc, animated: true)
    }

    /// 获取当前页面
    public class func currentTopViewController() -> UIViewController {
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
        return currentTopViewController(rootViewController: rootViewController!)
    }

    public class func currentNavigationController() -> UINavigationController {
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
        return currentNavigationController(rootViewController: rootViewController!)
    }

    // MARK: - private methods

    private class func currentTopViewController(rootViewController: UIViewController) -> UIViewController {
        if rootViewController.isKind(of: UITabBarController.self) {
            let tabBarController = rootViewController as! UITabBarController
            return currentTopViewController(rootViewController: tabBarController.selectedViewController!)
        } else if rootViewController.isKind(of: UINavigationController.self) {
            let navigationController = rootViewController as! UINavigationController
            return currentTopViewController(rootViewController: navigationController.visibleViewController!)
        }
        if rootViewController.presentedViewController != nil {
            return currentTopViewController(rootViewController: rootViewController.presentedViewController!)
        }
        return rootViewController
    }

    private class func currentNavigationController(rootViewController: UIViewController) -> UINavigationController {
        if rootViewController.isKind(of: UITabBarController.self) {
            let tabBarController = rootViewController as! UITabBarController
            return currentNavigationController(rootViewController: tabBarController.selectedViewController!)
        }

        return rootViewController as! UINavigationController
    }

    /// 打印日志
    class func printLog<T>(_ message: T, file _: String = #file, method _: String = #function, line _: Int = #line) {
        guard VVRoutes.verboseLoggingEnabled else {
            return
        }

        print("[VVRoute]: \(message)")
    }
}
