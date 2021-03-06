//
//  PeopleVC.swift
//  Internet Archive
//
//  Created by mac-admin on 6/14/18.
//  Copyright © 2018 mac-admin. All rights reserved.
//

import UIKit

class PeopleVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var lblMovies: UILabel!
    @IBOutlet weak var lblMusic: UILabel!
    @IBOutlet weak var clsMovies: UICollectionView!
    @IBOutlet weak var clsMusic: UICollectionView!
    
    var identifier: String?
    var name: String?
    var movieItems = [[String: Any]]()
    var musicItems = [[String: Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.clsMovies.isHidden = true
        self.clsMusic.isHidden = true
        self.lblMovies.isHidden = true
        self.lblMusic.isHidden = true
        
        loadData()
    }
    
    private func loadData() {
        if identifier == nil { return }
        
        let username = identifier!.suffix(identifier!.count - 1)
        
        AppProgressHUD.sharedManager.show(view: self.view)
        
        APIManager.sharedManager.getFavoriteItems(username: String(username))
        { (success, errCode, favorites) in
            
            if (success) {
                
                if let favorites = favorites, favorites.count > 0 {
                    var identifiers = [String]()
                    
                    for item in favorites {
                        if let mediaType = item["mediatype"] as? String {
                            if mediaType == "movies" || mediaType == "audio" {
                                identifiers.append(item["identifier"] as! String)
                            }
                        }
                    }
                    
                    let options = [
                        "fl[]" : "identifier,title,year,downloads,date,creator,description,mediatype",
                        "sort[]" : "date+desc"
                    ]
                    
                    let query = identifiers.joined(separator: " OR ")
                    
                    APIManager.sharedManager.search(query: "identifier:(\(query))", options: options, completion: { (data, error) in
                        
                        self.movieItems.removeAll()
                        self.musicItems.removeAll()
                        
                        if let data = data {
                            let items = data["docs"] as! [[String : Any]]
                            
                            for item in items {
                                let mediaType = item["mediatype"] as! String
                                
                                if mediaType == "movies" {
                                    self.movieItems.append(item)
                                } else if (mediaType == "audio") {
                                    self.musicItems.append(item)
                                }
                            }
                        }
                        
                        // Reload the collection view to reflect the changes.
                        self.clsMovies.reloadData()
                        self.clsMusic.reloadData()
                        self.clsMovies.isHidden = false
                        self.clsMusic.isHidden = false
                        self.lblMovies.isHidden = false
                        self.lblMusic.isHidden = false
                        
                        AppProgressHUD.sharedManager.hide()
                    })
                } else {
                    AppProgressHUD.sharedManager.hide()
                }
                
            } else {
                AppProgressHUD.sharedManager.hide()
                Global.showAlert(title: "", message: "Error occured while downloading favorites \n \(errCode!)", target: self)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == clsMovies {
            return movieItems.count
        } else if collectionView == clsMusic {
            return musicItems.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let itemCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath as IndexPath) as! ItemCell
        var items = [[String: Any]]()
        
        if collectionView == clsMovies {
            items = movieItems
        } else if collectionView == clsMusic {
            items = musicItems
        }
        
        let imageURL = URL(string: "https://archive.org/services/get-item-image.php?identifier=\(items[indexPath.row]["identifier"]!)")
        itemCell.itemTitle.text = "\(items[indexPath.row]["title"]!)"
        itemCell.itemImage.af_setImage(withURL: imageURL!)
        
        return itemCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var items = [[String: Any]]()
        
        if collectionView == clsMovies {
            items = movieItems
        } else if collectionView == clsMusic {
            items = musicItems
        }
        
        let data = items[indexPath.row]
        let identifier = data["identifier"] as? String
        let title = data["title"] as? String
        let archivedBy = data["creator"] as? String
        let date = data["date"] as? String
        let description = data["description"] as? String
        let mediaType = data["mediatype"] as? String
        let imageURL = URL(string: "https://archive.org/services/get-item-image.php?identifier=\(data["identifier"] as! String)")
        
        let itemVC = self.storyboard?.instantiateViewController(withIdentifier: "ItemVC") as! ItemVC
        
        itemVC.iIdentifier = identifier
        itemVC.iTitle = (title != nil) ? title! : ""
        itemVC.iArchivedBy = (archivedBy != nil) ? archivedBy! : ""
        itemVC.iDate = (date != nil) ? date! : ""
        itemVC.iDescription = (description != nil) ? description! : ""
        itemVC.iMediaType = (mediaType != nil) ? mediaType! : ""
        itemVC.iImageURL = imageURL
        
        self.present(itemVC, animated: true, completion: nil)
    }
    
}
