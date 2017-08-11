//
//  ToDoDetailController.swift
//  ToDo
//
//  Created by Tricia Rudloff on 8/10/17.
//  Copyright © 2017 TrishCode. All rights reserved.
//

import UIKit

class ToDoDetailController: UIViewController {
    
    // MARK: - Properties
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var priorityPicker: UIPickerView!
    @IBOutlet var datePicker: UIDatePicker!
    
    var toDo: ToDo?
    let priorityValues: [String] = ["1", "2", "3", "4", "5"]
    var editType: String!  //specify whether the operation is an edit or an add
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        priorityPicker.delegate = self
        priorityPicker.dataSource = self
        nameTextField.delegate = self
        
        //To Do is existing
        if let toDo = toDo {
            navigationItem.title = "Edit To Do"
            nameTextField.text = toDo.name
            setPickerPriority(toDo.priority)
            datePicker.date = toDo.date
            editType = "edit"
            
        //To Do is new
        } else {
            navigationItem.title = "Add To Do"
            setPickerPriority("3")  //default picker priority
            editType = "add"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("\(#function) in \(#file)")
    }
    
    
    //MARK: Navigation
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //if the To Do is existing, pass the id back to the list controller
        var id: Int = 0
        if let passedToDo = toDo {
            id = passedToDo.id
        }
        
        if let name = nameTextField.text {
        
            //Get the selected priority from the picker
            let selectedPriorityRow = priorityPicker.selectedRow(inComponent: 0)
            let priority = priorityValues[selectedPriorityRow]
            
            let date = datePicker.date
            
            //Set the To Do to be passed to ToDoListController after the unwind segue.
            //Note, id will be the existing id if this is an existing To Do and 0 if this is a new To Do. If the To Do is new, a unique id will be assigned when it is written to the database.
            toDo = ToDo(value: ["id": id, "name": name, "priority": priority, "date": date])
        }
    }
    
    
    //MARK: Helper
    
    func setPickerPriority(_ priority: String) {
        if let index = priorityValues.index(of: priority) {
            priorityPicker.selectRow(index, inComponent: 0, animated: true)
        }
    }

}


extension ToDoDetailController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return priorityValues.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return priorityValues[row]
    }
    
    
}


extension ToDoDetailController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Resigning first responder results in hiding the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
}

