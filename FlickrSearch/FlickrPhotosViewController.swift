/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

final class FlickrPhotosViewController: UICollectionViewController {
  // MARK: - Properties
  private let reuseIdentifier = "FlickrCell"
  private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
  private var searches: [FlickrSearchResults] = []
  private let flickr = Flickr()
  private let itemsPerRow: CGFloat = 3

  override func viewWillAppear(_ animated: Bool) {
    collectionView!.allowsSelection = true
  }
  
  override func viewDidAppear(_ animated: Bool) {
    flickr.searchCat() { searchResults in
      if case .success(let results) = searchResults {
        self.searches.insert(results, at: 0)

        //self.collectionView!.reloadData()
        self.reload()
      }
    }
  }
}

// MARK: - Private
private extension FlickrPhotosViewController {
  func photo(for indexPath: IndexPath) -> FlickrPhoto {
    return searches[indexPath.section].searchResults[indexPath.row]
  }
}

// MARK: - UICollectionViewDataSource
extension FlickrPhotosViewController {
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return searches.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return searches[section].searchResults.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell( withReuseIdentifier: reuseIdentifier, for: indexPath) as! FlickrPhotoCell
    let flickrPhoto = photo(for: indexPath)
    cell.backgroundColor = .white
    cell.imageView.image = flickrPhoto.thumbnail
    
    cell.isAccessibilityElement = true
    cell.accessibilityLabel = "Hello \(indexPath.section)\(indexPath.row)"
    cell.accessibilityIdentifier = "\(indexPath.section)\(indexPath.row)"
    
    return cell
  }

  func reload() {
    UIView.animate(withDuration: 0, animations: {
      self.collectionView!.reloadData()
    }) { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
        self.cellA11y(enable: true)
      }
    }
  }

  override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
    print("this will reload data and show the bug")

    /// Disabling A11Y will remove the first announcement after reload where it is on the wrong cell.
    /// Note this requires more than one spin of the event loop
    cellA11y(enable: false)
    /// view.layoutIfNeeded() , no effect
    let delay = 0.1 // a delay of zero won't work
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      self.reload()
    }
    return false
  }

  func cellA11y(enable: Bool) {
    for section in 0 ..< collectionView!.numberOfSections {
      let rowCount = collectionView!.numberOfItems(inSection: section)
      for row in 0 ..< rowCount {
        let cell = collectionView!.cellForItem(at: IndexPath(row: row, section: section))
        cell?.isAccessibilityElement = enable

        /// This has no effect, I tried not setting the label in cellForItemAt and then later, setting the label
        /// by using the id. This has no added benefit, since setting accessibilityLabel at any time
        /// triggers the focused cell's announcement
//        if !enable {
//          cell?.accessibilityLabel = nil
//        } else {
//          cell?.accessibilityLabel = cell!.accessibilityIdentifier
//        }
      }
    }
  }
}

// MARK: - Collection View Flow Layout Delegate
extension FlickrPhotosViewController: UICollectionViewDelegateFlowLayout {
  func collectionView( _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
    let availableWidth = view.frame.width - paddingSpace
    let widthPerItem = availableWidth / itemsPerRow
    return CGSize(width: widthPerItem, height: widthPerItem)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return sectionInsets
  }
  
  func collectionView( _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.left
  }
}

// MARK: - Text Field Delegate
extension FlickrPhotosViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    print("Make sure to update the flickr test API key for searching to work.")

    guard let text = textField.text, !text.isEmpty else { return true }

    let activityIndicator = UIActivityIndicatorView(style: .gray)
    textField.addSubview(activityIndicator)
    activityIndicator.frame = textField.bounds
    activityIndicator.startAnimating()

    flickr.searchFlickr(for: text) { searchResults in
      DispatchQueue.main.async {
        activityIndicator.removeFromSuperview()

        switch searchResults {
        case .failure(let error) :
          print("Error Searching: \(error)")
        case .success(let results):
          print("Found \(results.searchResults.count) matching \(results.searchTerm) ")
          self.searches.insert(results, at: 0)
          self.collectionView!.reloadData()
        }
      }
    }

    textField.text = nil
    textField.resignFirstResponder()
    return true
  }
}
