//
//  JCPlayerLayoutHelper.swift
//  JCRookiePlayer
//
//  Created by jaycehan on 2024/6/9.
//

import UIKit

extension UIDevice {
    
    static func navigationBarHeight() -> CGFloat {
        return 44
    }
    
    static func statusBarHeight() -> CGFloat {
        if #available(iOS 13.0, *) {
            let scene = UIApplication.shared.connectedScenes.first
            guard let windowScene = scene as? UIWindowScene else { return 0 }
            guard let window = windowScene.windows.first else { return 0 }
            return window.safeAreaInsets.top
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
    }
}
