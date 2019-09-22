//
//  SongsContainerViewController.swift
//  Music
//
//  Created by Florian on 27/08/15.
//  Copyright © 2015 objc.io. All rights reserved.
//

import UIKit
import CoreData
import MusicModel


private enum SongPresentationStyle: Int {
    case list = 0
    case grid = 1
}


class SongsContainerViewController: UIViewController {

    @IBOutlet weak var songPresentationButton: UIBarButtonItem!
    @IBOutlet weak var presentationStyleButton: UIBarButtonItem!
    var managedObjectContext: NSManagedObjectContext!
    var songSource: SongSource!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = songSource.localizedDescription
        presentationStyle = UserDefaults.standard.songPresentationStyle
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        for vc in segue.destination.children {
            guard let songsPresenter = vc as? SongsPresenter else { fatalError("expected songs presenter") }
            songsPresenter.managedObjectContext = managedObjectContext
            songsPresenter.songSource = songSource
        }
    }

    @IBAction func toggleSongPresentation(_ sender: AnyObject) {
        presentationStyle = presentationStyle.opposite
    }


    // MARK: Private

    fileprivate var tabController: UITabBarController {
        guard let tc = children.first as? UITabBarController else { fatalError("expected tab bar controller") }
        return tc
    }

    fileprivate var presentationStyle = SongPresentationStyle.standard {
        didSet {
            presentationStyleButton.title = ""
            tabController.selectedIndex = presentationStyle.rawValue
            UserDefaults.standard.songPresentationStyle = presentationStyle
        }
    }

}


extension SongsContainerViewController {
    static func instantiateFromStoryboard(for songSource: SongSource, managedObjectContext: NSManagedObjectContext) -> SongsContainerViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "SongsContainerViewController") as? SongsContainerViewController else { fatalError() }
        vc.songSource = songSource
        vc.managedObjectContext = managedObjectContext
        return vc
    }
}


extension SongPresentationStyle {
    fileprivate static var standard: SongPresentationStyle {
        return .list
    }

    fileprivate var opposite: SongPresentationStyle {
        switch self {
        case .list: return .grid
        case .grid: return .list
        }
    }
}


private let SongPresentationStyleKey = "songsPresentationStyle"

extension UserDefaults {
    fileprivate var songPresentationStyle: SongPresentationStyle {
        get {
            let val = integer(forKey: SongPresentationStyleKey)
            return SongPresentationStyle(rawValue: val) ?? SongPresentationStyle.standard
        }
        set {
            set(newValue.rawValue, forKey: SongPresentationStyleKey)
        }
    }
}

