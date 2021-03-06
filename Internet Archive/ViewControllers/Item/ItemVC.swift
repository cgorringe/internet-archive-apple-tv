//
//  ItemVC.swift
//  Internet Archive
//
//  Created by mac-admin on 5/29/18.
//  Copyright © 2018 mac-admin. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import TvOSMoreButton
import TvOSTextViewer

class ItemVC: UIViewController, AVPlayerViewControllerDelegate, AVAudioPlayerDelegate {

    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnFavorite: UIButton!
    @IBOutlet weak var txtTitle: UILabel!
    @IBOutlet weak var txtArchivedBy: UILabel!
    @IBOutlet weak var txtDate: UILabel!
    @IBOutlet weak var txtDescription: TvOSMoreButton!
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var slider: Slider!
    
    var iIdentifier: String?
    var iTitle: String?
    var iArchivedBy: String?
    var iDate: String?
    var iDescription: String?
    var iImageURL: URL?
    var iMediaType: String?
    
    var player: AVPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        btnPlay.setImage(UIImage(named: "play.png"), for: UIControlState.normal)
        
        txtTitle.text = iTitle
        txtArchivedBy.text = "Archived By:  \(iArchivedBy ?? "")"
        txtDate.text = "Date:  \(iDate ?? "")"
        txtDescription.text = iDescription
        itemImage.af_setImage(withURL: iImageURL!)
        txtDescription.buttonWasPressed = onMoreButtonPressed
        btnPlay.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        btnFavorite.imageView?.contentMode = UIViewContentMode.scaleAspectFit

        self.slider.isHidden = true
        self.slider.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let favorites = Global.getFavoriteData(), favorites.contains(iIdentifier!) {
            btnFavorite.setImage(UIImage(named: "favorited.png"), for: UIControlState.normal)
            btnFavorite.tag = 1
        } else {
            btnFavorite.setImage(UIImage(named: "favorite.png"), for: UIControlState.normal)
            btnFavorite.tag = 0
        }
    }

    @IBAction func onPlay(_ sender: Any) {
        if self.btnPlay.tag == 1 {
            stopPlyaing()
            return
        }
        
        var filesToPlay = [[String: Any]]()
        AppProgressHUD.sharedManager.show(view: self.view)
        
        APIManager.sharedManager.getMetaData(identifier: iIdentifier!) { (data, err) in
            AppProgressHUD.sharedManager.hide()

            if let data = data {
                for file in data["files"] as! [[String: Any]] {
                    let filename = file["name"] as! String
                    let ext = filename.suffix(4)

                    if ext == ".mp4", self.iMediaType! == "movies" {
                        filesToPlay.append(file)
                    } else if ext == ".mp3", self.iMediaType! == "etree" {
                        filesToPlay.append(file)
                    }
                }

                if filesToPlay.count == 0 {
                    Global.showAlert(title: "Error", message: "There is no playable content", target: self)
                    return
                }

                let filename = filesToPlay[0]["name"] as! String
                let url = "https://archive.org/download/\(self.iIdentifier!)/\(filename.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
                let mediaURL = URL(string: url)!

                let asset = AVAsset(url: mediaURL)
                let playerItem = AVPlayerItem(asset: asset)
                self.player = AVPlayer(playerItem: playerItem)
                
                if self.iMediaType! == "movies" {
                    let playerViewController = AVPlayerViewController()
                    playerViewController.delegate = self
                    playerViewController.player = self.player
                    
                    self.present(playerViewController, animated: true) {
                        self.player.play()
                    }
                } else if self.iMediaType! == "etree" {
                    self.startPlaying()
                }
                
            } else {
                Global.showAlert(title: "Error", message: "Error ocurred while downloading content", target: self)
            }
        }
    }
    
    @IBAction func onFavorite(_ sender: Any) {
        
        if let userData = Global.getUserData(),
            let email = userData["email"] as? String,
            let password = userData["password"] as? String,
            !email.isEmpty,
            !password.isEmpty {
            
            if btnFavorite.tag == 0 {
                btnFavorite.setImage(UIImage(named: "favorited.png"), for: UIControlState.normal)
                btnFavorite.tag = 1
                Global.saveFavoriteData(identifier: iIdentifier!)
            } else {
                btnFavorite.setImage(UIImage(named: "favorite.png"), for: UIControlState.normal)
                btnFavorite.tag = 0
                Global.removeFavoriteData(identifier: iIdentifier!)
            }
            
            APIManager.sharedManager.saveFavoriteItem(email: email, password: password, identifier: iIdentifier!, mediatype: iMediaType!, title: iTitle!) { (_, _) in }
            
        } else {
            Global.showAlert(title: "Error", message: "Login is required", target: self)
        }
        
    }
    
    private func onMoreButtonPressed(text: String?) {
        guard let text = text else {
            return
        }
        
        let textViewerController = TvOSTextViewerViewController()
        textViewerController.text = text
        textViewerController.textEdgeInsets = UIEdgeInsets(top: 100, left: 250, bottom: 100, right: 250)
        present(textViewerController, animated: true, completion: nil)
    }
    
    @objc func playerDidFinishPlaying(not: NSNotification) {
        stopPlyaing()
    }
    
    func _normalizedPowerLevelFromDecibels(_ decibels: Float) -> Float {
        if decibels < -60.0 || decibels == 0.0 {
            return 0.0
        }
        return powf((powf(10.0, 0.05 * decibels) - powf(10.0, 0.05 * -60.0)) * (1.0 / (1.0 - powf(10.0, 0.05 * -60.0))), 1.0 / 2.0)
    }
    
    func startPlaying() {
        self.player.play()
        self.btnPlay.tag = 1
        self.btnPlay.setImage(UIImage(named: "stop.png"), for: UIControlState.normal)
        self.slider.leftLabel.text = format(forTime: 0.0)
        self.slider.max = (player.currentItem?.asset.duration.seconds)!
        self.slider.isHidden = false
        UIApplication.shared.isIdleTimerDisabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }
    
    func stopPlyaing() {
        if self.player.rate != 0 && self.player.error == nil {
            self.player.pause()
        }
        
        self.btnPlay.tag = 0
        self.btnPlay.setImage(UIImage(named: "play.png"), for: UIControlState.normal)
        UIApplication.shared.isIdleTimerDisabled = false
        self.slider.set(value: 0.0, animated: false)
        self.slider.isHidden = true
    }
    
    private func format(forTime time: Double) -> String {
        let sign = time < 0 ? -1.0 : 1.0
        let minutes = Int(time * sign) / 60
        let seconds = Int(time * sign) % 60
        return (sign < 0 ? "-" : "") + "\(minutes):" + String(format: "%02d", seconds)
    }
}

extension ItemVC: SliderDelegate {
    func sliderDidTap(slider: Slider) {
        print("tapped")
    }

    func slider(_ slider: Slider, textWithValue value: Double) -> String {
        return format(forTime: value)
    }

    func slider(_ slider: Slider, didChangeValue value: Double) {
        slider.rightLabel.text = format(forTime: value - slider.max)
    }
}
