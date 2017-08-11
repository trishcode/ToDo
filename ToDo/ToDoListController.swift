//
//  ToDoListController.swift
//  ToDo
//
//  Created by Tricia Rudloff on 8/10/17.
//  Copyright © 2017 TrishCode. All rights reserved.
//

import UIKit
import RealmSwift

class ToDoListController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableView: UITableView!
    
    let realm = try! Realm()
    let toDos = try! Realm().objects(ToDo.self).sorted(byKeyPath: "id")
    var notificationToken: NotificationToken?
    
    var sortKey = "id"
    var sortDirection = true
    var filterActive = false
    var searchPredicate: NSPredicate?
    var conditionedToDos: Results<ToDo>!
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter
    }()
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        navigationItem.leftBarButtonItem = editButtonItem
        
        conditionedToDos = toDos  //initialize with the database values
        
        // Set results notification block
        self.notificationToken = toDos.addNotificationBlock { (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                self.conditionToDos()
                break
            case .update:
                self.conditionToDos()
                break
            case .error(let err):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(err)")
                break
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("\(#function) in \(#file)")
    }
    
    
    // MARK: - Actions
    
    @IBAction func unwindToToDoList(sender: UIStoryboardSegue) {
        if let source = sender.source as? ToDoDetailController, let toDo = source.toDo {
            if source.editType == "edit" {
                //Update an existing ToDo.
                edit(toDo)
            } else if source.editType == "add" {
                //Add a new ToDo.
                add(toDo)
            }
        }
    }
    
    //Add a new To Do
    func add(_ toDo: ToDo) {
        realm.beginWrite()
        realm.create(ToDo.self, value: ["id": uniqueID(), "name": toDo.name, "priority": toDo.priority, "date": toDo.date])
        try! realm.commitWrite()
    }
    
    //Edit and existing To Do
    func edit(_ toDo: ToDo) {
        realm.beginWrite()
        realm.add(toDo, update: true)
        try! realm.commitWrite()
    }
    
    //Sort by priority
    @IBAction func priorityButton(_ sender: UIButton) {
        sortKey = "priority"
        if sortDirection == true {
            sortDirection = false
        } else {
            sortDirection = true
        }
        conditionToDos()
    }
    
    //Sort by date
    @IBAction func DateButton(_ sender: UIButton) {
        sortKey = "date"
        if sortDirection == true {
            sortDirection = false
        } else {
            sortDirection = true
        }
        conditionToDos()
    }
    
    //Condition the To Do's with filtering and sorting
    func conditionToDos() {
        if filterActive == true {
            if let predicate = searchPredicate {
                conditionedToDos = toDos.sorted(byKeyPath: sortKey, ascending: sortDirection).filter(predicate)
            } else {
                conditionedToDos = toDos.sorted(byKeyPath: sortKey, ascending: sortDirection)
            }
        } else {
            conditionedToDos = toDos.sorted(byKeyPath: sortKey, ascending: sortDirection)
        }
        tableView.reloadData()
    }
    
    //Required for table view editing
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    //To Do delete confirmation when row is selected
    func deleteConfirmation(row: Int) {
        let title = "Delete Confirmation"
        let message = "Are you sure you want to delete?"
        let alertController = UIAlertController (title: title, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler:
        { action in
            self.realm.beginWrite()
            self.realm.delete(self.conditionedToDos[row])
            try! self.realm.commitWrite()
        })
        
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: - Navigation
    
    //Pass the selected To Do to the detail screen if editing
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditToDo" {
            //Get the cell that generated this segue.
            let navController = segue.destination as! UINavigationController
            let toDoDetailController = navController.topViewController as! ToDoDetailController
            if let selectedCell = sender as? ToDoListCell {
                let indexPath = tableView.indexPath(for: selectedCell)!
                let selectedToDo = conditionedToDos[indexPath.row]
                toDoDetailController.toDo = selectedToDo
            }
        }
        else if segue.identifier == "AddToDo" {
            print("Adding new to do item.")
        }
        //Dismiss editing after navigating away from screen.
        self.setEditing(false, animated: false)
        tableView.setEditing(false, animated: false)
    }
    
}


// Helpers

//Use current time in Unix as the To Do primary key
func uniqueID() -> Int {
    return Int(Date().timeIntervalSince1970)
}


// MARK: - UITableViewDataSource and UITableViewDelegate

extension ToDoListController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conditionedToDos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoListCell", for: indexPath) as! ToDoListCell
        
        let toDo = conditionedToDos[indexPath.row]
        
        cell.nameLabel.text = toDo.name
        cell.priorityLabel.text = toDo.priority
        cell.dateLabel.text = dateFormatter.string(from: toDo.date)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { action, index in
            //programmatically go to the detail VC, using sender as the cell for Prepare for Segue
            let cell = tableView.cellForRow(at: indexPath)
            self.performSegue(withIdentifier: "EditToDo", sender: cell)
        }
        edit.backgroundColor = .lightGray
        
        let delete = UITableViewRowAction(style: .default, title: "Delete") { action, index in
            self.realm.beginWrite()
            self.realm.delete(self.conditionedToDos[indexPath.row])
            try! self.realm.commitWrite()
        }
        delete.backgroundColor = .red
        
        return [delete, edit]
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        deleteConfirmation(row: indexPath.row)
    }
    
}

extension ToDoListController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //Clear the search bar filter
        if let text = searchBar.text {
            if text == "" {
                filterActive = false
                conditionToDos()
            }
        }
        
        //Apply the search bar filter
        if let text = searchBar.text, text.characters.count > 1 {
            searchPredicate = NSPredicate(format: "name CONTAINS[c] %@", text)
            //let searchPredicate = NSPredicate(format: "name CONTAINS[c] %@", text)
            let filterResults = toDos.filter(searchPredicate!)
            if filterResults.count > 0 {
                filterActive = true
                conditionToDos()
            }
        }
    }
    
}

