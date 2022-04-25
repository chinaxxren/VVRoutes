//
// Created by 赵江明 on 2022/3/3.
// Copyright (c) 2022 北京挖趣智慧有限公司. All rights reserved.
//


import UIKit
import VVRoute

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: ViewController())
        window?.makeKeyAndVisible()
        
        let routes = VVRoute.globalRoutes()
        VVRoute.verboseLoggingEnabled = true
        
        routes?.addRoute(pattern: "/login", handler: { (params) -> Bool in
            let user = params["user"]
            let vc = SecondController(user: user as! User)
            VVRouteUtil.push(vc)
            return true
        })
        
        routes?.addRoute(pattern: "/user/view/:userID", handler: { (params) -> Bool in
            let userID = params["userID"] // defined in the route by specifying ":userID"

            // present UI for viewing user with ID 'userID'

            return true // return true to say we have handled the route
        })

        // VVRoute.verboseLoggingEnabled = true

        VVRoute.routesForScheme("ViPay")?.addRoute(pattern: "/test/:opt(/a)(/b)(/c)", priority: 10, handler: { (params) -> Bool in
            print("打开测试页面\(params)")
            return true
        })

        VVRoute.globalRoutes()?.addRoute(pattern: "/test1", handler: { (params) -> Bool in
            print("打开测试1页面\(params)")
            return true
        })

        VVRoute.routesForScheme("ViPay")?.unmatchedURLHandler = { _, _, _ in
            print("无法识别的 ViPay 路由")
        }

        VVRoute.globalRoutes()?.unmatchedURLHandler = { _, _, _ in
            print("无法识别的路由")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            _ = VVRoute.routeURL(URL(string: "ViPay://test/:opt?a=6")!, parameters: ["name": "wangwanjie", "number": 5_201_314])

            _ = VVRoute.routeURL(URL(string: "/test1?age=27#topic")!, parameters: ["name": "wangwanjie", "number": 5_201_314])

            _ = VVRoute.routeURL(URL(string: "ViPay://8978998798q")!)
            _ = VVRoute.routeURL(URL(string: "jhkhjkkk")!)
        }

        VVRoute.globalRoutes()?.setHandlerBlock({ (_) -> Bool in
            // ...

            true
        }, forKeyedSubscript: "/user/view/:userID")

        return true
    }

    func application(_: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return VVRoute.routeURL(url)
    }
}
