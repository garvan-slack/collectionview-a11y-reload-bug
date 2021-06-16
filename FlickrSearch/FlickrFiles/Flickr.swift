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

// https://www.flickr.com/services/api/explore/flickr.photos.search at the bottom it shows temp API key
// These temp keys rotate ~daily
let apiKey = "0833f75e45683dadf421e0bb39ff9c1d"

class Flickr {
  enum Error: Swift.Error {
    case unknownAPIResponse
    case generic
  }

  func searchFlickr(for searchTerm: String, completion: @escaping (Result<FlickrSearchResults, Swift.Error>) -> Void) {
    guard let searchURL = flickrSearchURL(for: searchTerm) else {
      completion(.failure(Error.unknownAPIResponse))
      return
    }

    URLSession.shared.dataTask(with: URLRequest(url: searchURL)) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard (response as? HTTPURLResponse) != nil, let data = data else {
        completion(.failure(Error.unknownAPIResponse))
        return
      }

      self.process(searchTerm: searchTerm, data: data, completion: completion)
    }
    .resume()
  }

  func searchCat(completion: @escaping (Result<FlickrSearchResults, Swift.Error>) -> Void) {
    process(searchTerm: "cat", data: starterData.data(using: .utf8)!, completion: completion)
  }

  private func process(searchTerm: String, data: Data, completion: @escaping (Result<FlickrSearchResults, Swift.Error>) -> Void) {
    do {
      guard
        let resultsDictionary = try JSONSerialization.jsonObject(with: data) as? [String: AnyObject],
        let stat = resultsDictionary["stat"] as? String
      else {
        completion(.failure(Error.unknownAPIResponse))
        return
      }

      switch stat {
      case "ok":
        print("Results processed OK")
      case "fail":
        completion(.failure(Error.generic))
        return
      default:
        completion(.failure(Error.unknownAPIResponse))
        return
      }

      guard
        let photosContainer = resultsDictionary["photos"] as? [String: AnyObject],
        let photosReceived = photosContainer["photo"] as? [[String: AnyObject]]
      else {
        completion(.failure(Error.unknownAPIResponse))
        return
      }

      let flickrPhotos = self.getPhotos(photoData: photosReceived)
      let searchResults = FlickrSearchResults(searchTerm: searchTerm, searchResults: flickrPhotos)
      completion(.success(searchResults))
    } catch {
      completion(.failure(error))
      return
    }
  }

  private func getPhotos(photoData: [[String: AnyObject]]) -> [FlickrPhoto] {
    let photos: [FlickrPhoto] = photoData.compactMap { photoObject in
      guard
        let photoID = photoObject["id"] as? String,
        let farm = photoObject["farm"] as? Int ,
        let server = photoObject["server"] as? String ,
        let secret = photoObject["secret"] as? String
      else {
        return nil
      }

      let flickrPhoto = FlickrPhoto(photoID: photoID, farm: farm, server: server, secret: secret)

      guard
        let url = flickrPhoto.flickrImageURL(),
        let imageData = try? Data(contentsOf: url as URL)
      else {
        return nil
      }

      if let image = UIImage(data: imageData) {
        flickrPhoto.thumbnail = image
        return flickrPhoto
      } else {
        return nil
      }
    }
    return photos
  }

  private func flickrSearchURL(for searchTerm: String) -> URL? {
    guard let escapedTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) else {
      return nil
    }

    let URLString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&text=\(escapedTerm)&per_page=20&format=json&nojsoncallback=1"
    return URL(string: URLString)
  }
}

let starterData =
"""
  {"photos":{"page":1,"pages":11565,"perpage":20,"total":231283,"photo":[{"id":"51251177643","owner":"193107266@N07","secret":"b92053f2c3","server":"65535","farm":66,"title":"best cat dad ever custom t-shirt design and typography t-shirt designer","ispublic":1,"isfriend":0,"isfamily":0},{"id":"51250979281","owner":"158062764@N06","secret":"44c051ebaf","server":"65535","farm":66,"title":"Bella en Kitten","ispublic":1,"isfriend":0,"isfamily":0},{"id":"51251729529","owner":"158062764@N06","secret":"7587263f26","server":"65535","farm":66,"title":"Running kitten!","ispublic":1,"isfriend":0,"isfamily":0},{"id":"51251173508","owner":"158062764@N06","secret":"b255cb9a03","server":"65535","farm":66,"title":"Bella en Kitten","ispublic":1,"isfriend":0,"isfamily":0},{"id":"51251173538","owner":"158062764@N06","secret":"757da85a89","server":"65535","farm":66,"title":"Bella en Kitten","ispublic":1,"isfriend":0,"isfamily":0},{"id":"51250243482","owner":"89603825@N08","secret":"77d89bfd6e","server":"65535","farm":66,"title":"Pink Cat","ispublic":1,"isfriend":0,"isfamily":0},{"id":"51251131648","owner":"19432592@N08","secret":"25f7b2f19c","server":"65535","farm":66,"title":"Shioiri#3","ispublic":1,"isfriend":0,"isfamily":0},{"id":"51251973295","owner":"160880500@N04","secret":"33849ddc12","server":"65535","farm":66,"title":"Cat Bields","ispublic":1,"isfriend":0,"isfamily":0},{"id":"51250926071","owner":"160880500@N04","secret":"b3b5d054aa","server":"65535","farm":66,"title":"Cat Bields","ispublic":1,"isfriend":0,"isfamily":0},{"id":"51251972775","owner":"160880500@N04","secret":"7e7903bf5b","server":"65535","farm":66,"title":"Cat Bields","ispublic":1,"isfriend":0,"isfamily":0},{"id":"51251978715","owner":"188191502@N07","secret":"93afbd6761","server":"65535","farm":66,"title":"8 years old Tortoiseshell cat","ispublic":1,"isfriend":0,"isfamily":0},{"id":"51251673514","owner":"78517182@N07","secret":"9205595b3d","server":"65535","farm":66,"title":"Fur Ball","ispublic":1,"isfriend":0,"isfamily":0},{"id":"51250183437","owner":"37964029@N08","secret":"5e85998e87","server":"65535","farm":66,"title":"Mood in the back seat","ispublic":1,"isfriend":0,"isfamily":0},{"id":"51251957680","owner":"37964029@N08","secret":"acd5de082c","server":"65535","farm":66,"title":"Mood in the back seat","ispublic":1,"isfriend":0,"isfamily":0},{"id":"51251660814","owner":"37964029@N08","secret":"a61d1920a5","server":"65535","farm":66,"title":"Mood in the back seat","ispublic":1,"isfriend":0,"isfamily":0},{"id":"51251105053","owner":"37964029@N08","secret":"0f89d78934","server":"65535","farm":66,"title":"Mood in the back seat","ispublic":1,"isfriend":0,"isfamily":0},{"id":"51250910386","owner":"37964029@N08","secret":"25d71b502c","server":"65535","farm":66,"title":"Mood in the back seat","ispublic":1,"isfriend":0,"isfamily":0},{"id":"51250910271","owner":"37964029@N08","secret":"8e35bd0654","server":"65535","farm":66,"title":"Mood in the back seat","ispublic":1,"isfriend":0,"isfamily":0},{"id":"51251957135","owner":"37964029@N08","secret":"bedc3aa538","server":"65535","farm":66,"title":"Mood in the back seat","ispublic":1,"isfriend":0,"isfamily":0}]},"stat":"ok"}
"""
