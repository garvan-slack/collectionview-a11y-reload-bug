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

var vv = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))

final class FlickrPhotosViewController: UICollectionViewController {
  // MARK: - Properties
  private let reuseIdentifier = "FlickrCell"
  private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
  private var searches: [FlickrSearchResults] = []
  private let flickr = Flickr()
  private let itemsPerRow: CGFloat = 3
  
  var tf = UITextField(frame: CGRect(x: 0, y: 70, width: 100, height: 22))
  
  override func viewWillAppear(_ animated: Bool) {
    collectionView!.allowsSelection = true
    
    view.addSubview(tf)
    tf.backgroundColor = .yellow
    tf.layer.borderWidth = 1
    tf.delegate = self
  }
  
  override func viewDidAppear(_ animated: Bool) {
    flickr.searchCat() { searchResults in
      if case .success(let results) = searchResults {
        self.searches.insert(results, at: 0)
        self.reloadData(visible: false) {
          self.setup(enable: true)
        }
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


// MARK: - Text Field Delegate
extension FlickrPhotosViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    tf = textField
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
          self.reloadData(visible: false) {
            self.setup(enable: true)
          }
        }
      }
    }
    
    textField.text = nil
    textField.resignFirstResponder()
    return true
  }
}
var c = 0
// MARK: - UICollectionViewDataSource
extension FlickrPhotosViewController {
  // 1
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
    c += 1
    cell.accessibilityLabel = "Hello \(c)"
    
    return cell
  }
  
  func reloadData(visible: Bool, completion: @escaping () -> ()) {
    tf.accessibilityViewIsModal = true
    UIAccessibility.post(notification: .layoutChanged, argument: tf)
    // DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
    UIView.animate(withDuration: 0, animations: {
      //visible ? cv.reloadItems(at: cv.indexPathsForVisibleItems) :
      self.collectionView!.reloadData()
    }) {_ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
        self.tf.accessibilityViewIsModal = false
        //UIAccessibility.post(notification: .screenChanged, argument: nil)
        completion()
      }
    }
    //  }
  }
  
  func setup(enable: Bool) {
    //    for section in 0 ..< cv.numberOfSections {
    //      let rowCount = cv.numberOfItems(inSection: section)
    //      for row in 0 ..< rowCount {
    //        let cell = cv.cellForItem(at: IndexPath(row: row, section: section))
    //        cell?.isAccessibilityElement = enable
    //      }
    //    }
  }
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    print("here didSelectItemAt")
    self.setup(enable: false)
    reloadData(visible: true) {
      self.setup(enable: true)
    }
  }
}

// MARK: - Collection View Flow Layout Delegate
extension FlickrPhotosViewController: UICollectionViewDelegateFlowLayout {
  // 1
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
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
