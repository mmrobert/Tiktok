//
//  TabBarController.swift
//  Beau.ty
//  Created by Boqian Cheng on 2022-11-26.
//

import Foundation
import UIKit
import SwiftUI
import Combine

public enum AppTab {
    case home
    case love
    case post
    case inbox
    case profile
}

class TabBarController: UITabBarController {
    
    private var disposables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBar.barTintColor = UIColor.tabbarBackground
        self.tabBar.isTranslucent = false
        self.tabBar.unselectedItemTintColor = .gray
        self.tabBar.tintColor = UIColor.tabbarTint

        self.viewControllers = [homeTab(), favoritesTab(), postTab(), inboxTab(), profileTab()]
    }
    
    private func homeTab() -> UINavigationController {
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: String.homeStr.localized(),
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
       
        return homeNav
    }
    
    private func favoritesTab() -> UINavigationController {
        let favoritesVC = FavoritesViewController()
        let favoritesNav = UINavigationController(rootViewController: favoritesVC)
        favoritesNav.tabBarItem = UITabBarItem(
            title: String.favoritesStr.localized(),
            image: UIImage(systemName: "heart.circle"),
            selectedImage: UIImage(systemName: "heart.circle.fill")
        )
       
        return favoritesNav
    }
    
    private func postTab() -> UINavigationController {
        let createVC = CreateMediaViewController()
        let createNav = UINavigationController(rootViewController: createVC)
        createNav.tabBarItem = UITabBarItem(
            title: String.postStr.localized(),
            image: UIImage(systemName: "plus.rectangle"),
            selectedImage: UIImage(systemName: "plus.rectangle.fill")
        )
       
        return createNav
    }
    
    private func inboxTab() -> UINavigationController {
        let inboxVC = InboxViewController()
        let inboxNav = UINavigationController(rootViewController: inboxVC)
        inboxNav.tabBarItem = UITabBarItem(
            title: String.inboxStr.localized(),
            image: UIImage(systemName: "text.bubble"),
            selectedImage: UIImage(systemName: "text.bubble.fill")
        )
       
        return inboxNav
    }
    
    private func profileTab() -> UINavigationController {
        let profileVC = ProfileViewController()
        let profileNav = UINavigationController(rootViewController: profileVC)
        profileNav.tabBarItem = UITabBarItem(
            title: String.profileStr.localized(),
            image: UIImage(systemName: "person.circle"),
            selectedImage: UIImage(systemName: "person.circle.fill")
        )
       
        return profileNav
    }

    public func chooseTab(appTab: AppTab) {
        switch appTab {
        case .home:
            selectedIndex = 0
        case .love:
            selectedIndex = 1
        case .post:
            selectedIndex = 2
        case .inbox:
            selectedIndex = 3
        case .profile:
            selectedIndex = 4
        }
    }
}
