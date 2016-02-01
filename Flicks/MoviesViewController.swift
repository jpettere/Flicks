//
//  MoviesViewController.swift
//  Flicks
//
//  Created by Julia Pettere on 1/7/16.
//  Copyright © 2016 Julia Pettere. All rights reserved.
//
import UIKit
import AFNetworking
import SwiftLoader


class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var networkErrorView: UIView!

    
    var config : SwiftLoader.Config = SwiftLoader.Config()
    
    var movies: [NSDictionary]?
    
    var filteredMovies: [NSDictionary]?
    
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        
        self.loadingImage()
        self.getMovieData()
        self.controlRefresh()
        

    }

    @IBAction func didTapNetworkErrorView(sender: UITapGestureRecognizer) {
        self.getMovieData()
    }

    func getMovieData() {
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string:"https://api.themoviedb.org/3/movie/now_playing?api_key=\(apiKey)")
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue())
        
        self.networkErrorView.backgroundColor = UIColor.lightGrayColor()
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                
                self.refreshControl.endRefreshing()
                
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            //NSLog("response: \(responseDictionary)")
                            
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            self.filteredMovies = self.movies
                            self.tableView.reloadData()
                            
                            self.networkErrorView.hidden = true
                    }
                } else {
                    self.networkErrorView.hidden = false
                }
        });
        task.resume()
    }
    
    func onRefresh() {
        self.getMovieData()
    }
    
    func loadingImage() {
        
        config.size = 150
        config.spinnerColor = .redColor()
        config.foregroundColor = .blackColor()
        config.foregroundAlpha = 0.5
        SwiftLoader.setConfig(config)
    
    }
    
    func controlRefresh() {
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: "onRefresh", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.insertSubview(refreshControl, atIndex: 0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let unwrappedFilteredMovies = filteredMovies {
            return unwrappedFilteredMovies.count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        let movie = self.filteredMovies![indexPath.row]
        let title = movie["title"] as! String
        cell.titleLabel.textColor = UIColor.init(red: 77.0/255.0, green: 125.0/255.0, blue: 1.0, alpha: 1.0)
        let overview = movie["overview"] as! String
        
        let baseUrl = "http://image.tmdb.org/t/p/w500"
        if let posterPath = movie["poster_path"] as? String {
            let imageUrl = NSURLRequest(URL: NSURL(string: baseUrl + posterPath)!)
            cell.posterView.setImageWithURLRequest(imageUrl,
                placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                    
                    // imageResponse will be nil if the image is cached
                    if imageResponse != nil {
                        print("Image was NOT cached, fade in image")
                        cell.posterView.alpha = 0.0
                        cell.posterView.image = image
                        UIView.animateWithDuration(0.3, animations: { () -> Void in
                            cell.posterView.alpha = 1.0
                        })
                    } else {
                        print("Image was cached so just update the image")
                        cell.posterView.image = image
                    }
                },
                failure: { (imageRequest, imageResponse, error) -> Void in
            })
        }
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
       // cell.backgroundColor = UIColor.clearColor()
    
        return cell
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filteredMovies = searchText.isEmpty ? movies : movies!.filter({(movie: NSDictionary) -> Bool in
            return (movie["title"] as! String).rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
        })
        
        tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        SwiftLoader.show(title: "Loading...", animated: true)
        SwiftLoader.hide()
    }
    
    @IBAction func didTapTableView(sender: AnyObject) {
        
        view.endEditing(true)
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
