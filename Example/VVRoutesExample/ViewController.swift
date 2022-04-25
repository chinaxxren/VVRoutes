//
// Created by 赵江明 on 2022/3/3.
// Copyright (c) 2022 北京挖趣智慧有限公司. All rights reserved.
//


import UIKit
import HDRoutes

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let btn = UIButton()
        btn .setTitle("Click", for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        btn.center = view.center
        btn.addTarget(self, action: #selector(doClick), for: .touchUpInside)
        view.addSubview(btn)
        view.backgroundColor = .red
    }
    
    @objc func doClick() {
        let user = User(name: "Name", age: 18)
//        HDRoutes.routeURL(URL(string: "/login")!,parameters: ["user":user])
        HDRoutes.openURL("/login",parameters: ["user":user])
    }
}
