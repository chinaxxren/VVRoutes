//
// Created by 赵江明 on 2022/3/3.
// Copyright (c) 2022 北京挖趣智慧有限公司. All rights reserved.
//


import UIKit
import VVRoutes

class SecondController: UIViewController {
    let user: User
    
    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let btn = UIButton()
        btn .setTitle(user.name, for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        btn.center = view.center
        btn.addTarget(self, action: #selector(doClick), for: .touchUpInside)
        view.addSubview(btn)
        view.backgroundColor = .green
    }
    
    @objc func doClick() {
        let user = User(name: "Name", age: 18)
        VVRoutes.routeURL(URL(string: "/login")!,parameters: ["user":user])
    }
}
