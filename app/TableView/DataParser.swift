//
//  DataParser.swift
//  TableView
//
//  Created by Jai Lafferty on 13/5/19.
//  Copyright © 2019 Jai Lafferty. All rights reserved.
//

import Foundation
import UIKit

class DataParser {
    let session:URLSession
    
    init() {
        session = URLSession(configuration: .default)
    }
    
    func begin(tv: UITableView) {
        fetchAlbumData(tv: tv)
    }
    
    // Gets data from the API
    func fetchAlbumData(tv: UITableView) {
        var dataTask: URLSessionDataTask?
        
        dataTask?.cancel()
        
        if var urlComponents = URLComponents(string: "https://itunes.apple.com/lookup") {
            urlComponents.query = "id=\(currentArtist.id)&entity=album"
            
            guard let url = urlComponents.url else {return} // failed
            
            //Actual API Call
            dataTask = session.dataTask(with: url, completionHandler: {(data, response, error) in
                
                if let error = error {
                    print("error: " + error.localizedDescription)
                } else if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                    // If we have a 200 status (OK) then continue
                    self.parseAlbumData(data: data, tv: tv)
                }
            })
        }
        dataTask?.resume()
    }
    
    
    func parseAlbumData(data: Data, tv: UITableView) {
        var response:[String: Any]
        
        do {
            response = try (JSONSerialization.jsonObject(with: data, options: []) as? [String:Any])!
            
            // Make sure we actually have results
            guard let array = response["results"] as? [Any] else {
                return
            }
            
            print(response)
            
            for albumDict in array {
                if let AlbumDictionary = albumDict as? [String:Any],
                    let title = AlbumDictionary["collectionName"] as? String,
                    let id = AlbumDictionary["collectionId"] as? Int,
                    let url = AlbumDictionary["artworkUrl100"] as? String{
                    
                    let strID = String(id) // ID stored as an int in the JSON
                    currentArtist.albums.append(memAlbum(itunesID: strID, title: title, tracks: [], url: url))
                } else {
                    print("Error placing Album Data into Structs - If only one of these appears that's fine!")
                }
            }
            DispatchQueue.main.async{
                tv.reloadData()
            }
        } catch {
            print("Error Parsing Album Data")
            return
        }
    }
    
    func fetchTracks(collID : String) {
        var dataTask: URLSessionDataTask?
        
        dataTask?.cancel()
        
        if var urlComponents = URLComponents(string: "https://itunes.apple.com/lookup") {
            urlComponents.query = "id=\(collID)&entity=song"
            
            guard let url = urlComponents.url else {return} // failed
            
            //Actual API Call
            dataTask = session.dataTask(with: url, completionHandler: {(data, response, error) in
                
                if let error = error {
                    print("error: " + error.localizedDescription)
                } else if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                    // If we have a 200 status (OK) then continue
                    self.parseTracks(collID: collID, data: data)
                }
            })
        }
        dataTask?.resume()
    }
    
    func parseTracks(collID : String, data: Data) {
        var response:[String: Any]
        
        do {
            response = try (JSONSerialization.jsonObject(with: data, options: []) as? [String:Any])!
            
            // Make sure we actually have results
            guard let array = response["results"] as? [Any] else {
                return
            }
            
            let targetIndex = findAlbumInCurrentArtist(id: collID)
            
            
            for trackDict in array {
                if let trackDictionary = trackDict as? [String:Any],
                    let title = trackDictionary["trackName"] as? String,
                    let trackNo = trackDictionary["trackNumber"] as? Int{
                    
                    if targetIndex != nil {
                        currentArtist.albums[targetIndex!].tracks.append(memTrack(title: title, trackNo: trackNo))
                    } else {
                        print("Could not find relevant album in data")
                    }
                    
                } else {
                    print("Error placing Track Data into Album - If only one of these appears that's fine!")
                }
            }
            print("Tracks Added")
        } catch {
            print("Error Parsing Track Data")
            return
        }
    }
    
    func findArtist(searchTerm: String, callback: @escaping ((name: String?, id: String?)) -> Void){
        var dataTask: URLSessionDataTask?
        
        var parsed: (name: String?, id: String?) = (nil,nil)

        
        dataTask?.cancel()
        
        if var urlComponents = URLComponents(string: "https://itunes.apple.com/search") {
            urlComponents.query = "term=\(searchTerm)&entity=musicArtist"
            
            guard let url = urlComponents.url else {
                return
            } // failed
            
            
            //Actual API Call
            dataTask = session.dataTask(with: url, completionHandler: {(data, response, error) in
                
                if let error = error {
                    print("API Error: " + error.localizedDescription)
                } else if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                    // If we have a 200 status (OK) then continue
                    parsed = self.parseFoundArtist(data: data)
                    callback(parsed)
                }
            })
        }
        dataTask?.resume()
    }
    
    func parseFoundArtist(data: Data) -> (name: String?, id: String?) {
        do {
            var dataSet:[String:Any]
            
            dataSet = try (JSONSerialization.jsonObject(with: data, options: []) as? [String:Any])!
            
            guard let results = dataSet["results"] as? [Any] else {
                return (nil, nil)
            }
            
            let firstArtist = results[0]
            
            if let firstArtistDict = firstArtist as? [String:Any],
                let name = firstArtistDict["artistName"],
                let id = firstArtistDict["artistId"] {
                print("Artist Found: \(name)(\(id))")

                return (name as? String, String(id as! Int))
            }
            
        } catch {
            print("Error Finding Artist")
        }
        
        return (nil,nil)
    }
    
    func findAlbumInCurrentArtist(id: String) -> Int? {
        for a in currentArtist.albums {
            if a.itunesID == id {
                return currentArtist.albums.index(of: a)
            }
        }
        return nil
    }
    
    
}