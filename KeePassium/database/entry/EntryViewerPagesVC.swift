//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
// 
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import KeePassiumLib

protocol EntryViewerPagesDataSource: AnyObject {
    func getPageCount(for viewController: EntryViewerPagesVC) -> Int
    func getPage(index: Int, for viewController: EntryViewerPagesVC) -> UIViewController?
    func getPageIndex(of page: UIViewController, for viewController: EntryViewerPagesVC) -> Int?
}

final class EntryViewerPagesVC: UIViewController, Refreshable {

    @IBOutlet private weak var pageSelector: UISegmentedControl!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var titleImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    
    public weak var dataSource: EntryViewerPagesDataSource?

    private var isHistoryEntry = false
    private var entryIcon: UIImage?
    private var resolvedEntryTitle = ""
    private var isEntryExpired = false
    private var entryLastModificationTime = Date.distantPast
    
    private var pagesViewController: UIPageViewController! 
    private var currentPageIndex = 0 {
        didSet {
            if !isHistoryEntry {
                Settings.current.entryViewerPage = currentPageIndex
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pagesViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil)
        pagesViewController.delegate = self
        pagesViewController.dataSource = self

        addChild(pagesViewController)
        pagesViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pagesViewController.view.frame = containerView.bounds
        containerView.addSubview(pagesViewController.view)
        pagesViewController.didMove(toParent: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        assert(dataSource != nil, "dataSource must be defined")
        refresh()
        if isHistoryEntry {
            switchTo(page: 0)
        } else {
            switchTo(page: Settings.current.entryViewerPage)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationItem.rightBarButtonItem =
            pagesViewController.viewControllers?.first?.navigationItem.rightBarButtonItem
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refresh()
    }
    
    public func setContents(from entry: Entry, isHistoryEntry: Bool) {
        entryIcon = UIImage.kpIcon(forEntry: entry)
        resolvedEntryTitle = entry.resolvedTitle
        isEntryExpired = entry.isExpired
        entryLastModificationTime = entry.lastModificationTime
        self.isHistoryEntry = isHistoryEntry
        refresh()
    }
    
    public func switchTo(page index: Int) {
        guard let dataSource = dataSource,
              let targetPageVC = dataSource.getPage(index: index, for: self)
        else {
            assertionFailure()
            return
        }
        
        let direction: UIPageViewController.NavigationDirection
        if index >= currentPageIndex {
            direction = .forward
        } else {
            direction = .reverse
        }

        let previousPageVC = pagesViewController.viewControllers?.first
        previousPageVC?.willMove(toParent: nil)
        targetPageVC.willMove(toParent: pagesViewController)
        pagesViewController.setViewControllers(
            [targetPageVC],
            direction: direction,
            animated: true,
            completion: { [weak self] (finished) in
                guard let self = self else { return }
                previousPageVC?.didMove(toParent: nil)
                targetPageVC.didMove(toParent: self.pagesViewController)
                self.pageSelector.selectedSegmentIndex = index
                self.currentPageIndex = index
                self.navigationItem.rightBarButtonItem =
                    targetPageVC.navigationItem.rightBarButtonItem
            }
        )
        
    }
    
    @IBAction func didChangePage(_ sender: Any) {
        switchTo(page: pageSelector.selectedSegmentIndex)
    }

    
    func refresh() {
        guard isViewLoaded else { return }
        titleLabel.setText(resolvedEntryTitle, strikethrough: isEntryExpired)
        titleImageView?.image = entryIcon
        if isHistoryEntry {
            if traitCollection.horizontalSizeClass == .compact {
                subtitleLabel?.text = DateFormatter.localizedString(
                    from: entryLastModificationTime,
                    dateStyle: .medium,
                    timeStyle: .short)
            } else {
                subtitleLabel?.text = DateFormatter.localizedString(
                    from: entryLastModificationTime,
                    dateStyle: .full,
                    timeStyle: .medium)
            }
            subtitleLabel?.isHidden = false
        } else {
            subtitleLabel?.isHidden = true
        }
        
        let currentPage = pagesViewController.viewControllers?.first
        (currentPage as? Refreshable)?.refresh()
    }
}

extension EntryViewerPagesVC: UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard finished && completed else { return }

        guard let dataSource = dataSource,
              let selectedVC = pageViewController.viewControllers?.first,
              let selectedIndex = dataSource.getPageIndex(of: selectedVC, for: self)
        else {
            return
        }
        
        previousViewControllers.first?.didMove(toParent: nil)
        selectedVC.didMove(toParent: pagesViewController)
        currentPageIndex = selectedIndex
        pageSelector.selectedSegmentIndex = selectedIndex
        navigationItem.rightBarButtonItem = selectedVC.navigationItem.rightBarButtonItem
    }
}

extension EntryViewerPagesVC: UIPageViewControllerDataSource {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = dataSource?.getPageIndex(of: viewController, for: self) else {
            return nil
        }
        return dataSource?.getPage(index: index - 1, for: self)
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = dataSource?.getPageIndex(of: viewController, for: self) else {
            return nil
        }
        
        return dataSource?.getPage(index: index + 1, for: self)
    }
}