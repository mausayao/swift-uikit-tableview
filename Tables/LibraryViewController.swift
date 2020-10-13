//
//  ViewController.swift
//  Tables
//
//  Created by Maurício de Freitas Sayão on 05/10/20.
//

import UIKit

class LibraryHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "\(LibraryHeaderView.self)"
    @IBOutlet weak var titleLabel: UILabel!
}

enum SortStyle {
    case title
    case author
    case readMe
}
enum Section: String, CaseIterable {
    case addNew
    case readMe = "Read Me!"
    case finished = "Finished"
}

class LibraryViewController: UITableViewController {
    
    var dataSource: LibraryDataSource!
    @IBOutlet var sortButtons: [UIBarButtonItem]!
    
    @IBSegueAction func showDetailView(_ coder: NSCoder) -> DetailViewController? {
        
        guard let indexPath = tableView.indexPathForSelectedRow, let book = dataSource.itemIdentifier(for: indexPath) else {fatalError("Nothing selected")}
        
        return DetailViewController(coder: coder, book: book)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem
        
        tableView.register(UINib(nibName: "\(LibraryHeaderView.self)", bundle: nil), forHeaderFooterViewReuseIdentifier: LibraryHeaderView.reuseIdentifier)
        configureDataSource()
        dataSource.update(sortStyle: .readMe)
    }
    
   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        dataSource.update(sortStyle: dataSource.currentSortStyle)
    }
    
    @IBAction func sortTitle(_ sender: UIBarButtonItem) {
        dataSource.update(sortStyle: .title)
        updateTintColors(tappedButton: sender)
    }
    
    @IBAction func sortAuthor(_ sender: UIBarButtonItem) {
        dataSource.update(sortStyle: .author)
        updateTintColors(tappedButton: sender)
    }
    
    @IBAction func sortReadMe(_ sender: UIBarButtonItem) {
        dataSource.update(sortStyle: .readMe)
        updateTintColors(tappedButton: sender)
    }
    
    func updateTintColors(tappedButton: UIBarButtonItem) {
        sortButtons.forEach { button in
            button.tintColor = button == tappedButton ? button.customView?.tintColor : .secondaryLabel
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 { return nil }
        
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: LibraryHeaderView.reuseIdentifier) as? LibraryHeaderView else { return nil }
        
        headerView.titleLabel.text = Section.allCases[section].rawValue
        
        return headerView
        
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section != 0 ? 60 : 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 1 ? "Read Me!" : nil
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    // MARK: - Data source
    
    func configureDataSource() {
        dataSource = LibraryDataSource(tableView: tableView) { (tableView, indexPath, book) -> UITableViewCell? in
            
            if indexPath == IndexPath(row: 0, section: 0) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "NewBookCell", for: indexPath)
                
                return cell
            }
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(BookCell.self)", for: indexPath) as? BookCell else { fatalError("Could not create a BookCell") }
            
            cell.titleLabel.text = book.title
            cell.authorLabel.text = book.author
            cell.bookThunbnail.image = book.image ?? LibrarySymbol.letterSquare(letter: book.title.first).image
            
            cell.bookThunbnail.layer.cornerRadius = 12
            
            if let review  = book.review {
                cell.reviewLabel.text = review
                cell.reviewLabel.isHidden = false
            }
            
            cell.readMeBookMark.isHidden = !book.readMe
            
            return cell
        }
    }
    
    

}

class LibraryDataSource: UITableViewDiffableDataSource<Section, Book> {
    
    var currentSortStyle: SortStyle = .title
    
    func update(sortStyle: SortStyle, animatingDifferences: Bool = true) {
        
        currentSortStyle = sortStyle
        
        var newSnapshot = NSDiffableDataSourceSnapshot<Section, Book>()
        newSnapshot.appendSections(Section.allCases)
        newSnapshot.appendItems(Library.books, toSection: .readMe)
        
        let booksByReadMe: [Bool: [Book]] = Dictionary(grouping: Library.books, by: \.readMe)
        
        for (readMe, books) in booksByReadMe {
            var sortedBooks: [Book]
            
            switch sortStyle {
            case .title:
                sortedBooks = books.sorted {$0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            case .author:
                sortedBooks = books.sorted {$0.author.localizedCaseInsensitiveCompare($1.author) == .orderedAscending }
            case .readMe:
                sortedBooks = books
            }
            
            newSnapshot.appendItems(sortedBooks, toSection: readMe ? .readMe: .finished)
        }
        
        newSnapshot.appendItems([Book.mockBook], toSection: .addNew)
        apply(newSnapshot, animatingDifferences: animatingDifferences)
        
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        indexPath.section == snapshot().indexOfSection(.addNew) ? false : true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let book = self.itemIdentifier(for: indexPath) else { return }
            
            Library.delete(book: book)
            update(sortStyle: currentSortStyle)
        }
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section != snapshot().indexOfSection(.readMe) || currentSortStyle == .readMe {
            return false
        } else {
            return true
        }
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard sourceIndexPath != destinationIndexPath,
              sourceIndexPath.section == destinationIndexPath.section,
              let bookToMove = itemIdentifier(for: sourceIndexPath),
              let bookDestination = itemIdentifier(for: destinationIndexPath)
        else {
            apply(snapshot(), animatingDifferences: false)
            return
        }
        
        Library.reorderBooks(bookToMove: bookToMove, bookAtDestination: bookDestination)
        update(sortStyle: currentSortStyle ,animatingDifferences: false)
    }
}

