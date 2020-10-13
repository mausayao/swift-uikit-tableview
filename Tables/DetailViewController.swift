//
//  DetailViewController.swift
//  Tables
//
//  Created by Maurício de Freitas Sayão on 07/10/20.
//

import UIKit

class DetailViewController: UITableViewController {
    
    var book: Book
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var author: UILabel!
    @IBOutlet weak var bookImage: UIImageView!
    
    @IBOutlet weak var readMeButton: UIButton!
    
    @IBOutlet weak var reviewText: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bookImage.image = book.image ?? LibrarySymbol.letterSquare(letter: book.title.first).image
        bookImage.layer.cornerRadius = 16
        
        titleLabel.text = book.title
        author.text = book.author
        
        if let review = book.review {
            reviewText.text = review
        }
        
        let image = book.readMe ? LibrarySymbol.bookmarkFill.image : LibrarySymbol.bookmark.image
        readMeButton.setImage(image, for: .normal)
        
        reviewText.addDoneButton()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("This should never be called")
    }
    
    init?(coder: NSCoder, book: Book) {
        self.book = book
        super.init(coder: coder)
    }
    
    @IBAction func updateImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func saveChanges() {
        Library.update(book: book)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func toggleReadMe() {
        book.readMe.toggle()
        let image = book.readMe ? LibrarySymbol.bookmarkFill.image : LibrarySymbol.bookmark.image
        readMeButton.setImage(image, for: .normal)
    }
}

extension DetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.editedImage] as? UIImage else { return }
        
        bookImage.image = selectedImage
        
        book.image = selectedImage
        
        dismiss(animated: true)
    }
}

extension DetailViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        book.review = textView.text
        textView.resignFirstResponder()
    }
}

extension UITextView {
    func addDoneButton() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.resignFirstResponder))
        
        toolbar.items = [flexSpace, doneButton]
        
        self.inputAccessoryView = toolbar
        
    }
}
