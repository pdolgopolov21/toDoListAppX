//
//  TaskListViewController.swift
//  toDoListApp
//
//  Created by Pavel Dolgopolov on 24.11.2025.
//

import UIKit

final class TaskListViewController: UITableViewController {

    // MARK: - IB Outlets

    @IBOutlet var searchBar: UISearchBar!
    
    private var taskCountLabel: UILabel!
    
    // MARK: - Properties
    private let viewModel = TaskListViewModel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Задачи"
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
        
        setupSearchBar()
        setupBottomToolbar()
        setupBindings()
        setupNotifications()
        
        tableView.register(TaskTableViewCell.self, forCellReuseIdentifier: TaskTableViewCell.identifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refreshTasks()
        updateTaskCountLabel()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup Methods
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        //searchBar.searchBarStyle = .minimal // .prominent
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
                searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            ])
    }
   
    private func setupBottomToolbar() {
       
        let addButton = UIButton(type: .system)
        addButton.accessibilityIdentifier = "addButton"
        addButton.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        addButton.tintColor = .systemYellow // .systemBlue
        
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        let iconBarButton = UIBarButtonItem(customView: addButton)
        
        let textStyle = UIFont.TextStyle.caption1
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        
        let longestString = "много Задач"
        // Рассчитываем размер на основе системного шрифта для этого стиля
        let stringSize = (longestString as NSString).size(withAttributes: [.font: metrics.scaledFont(for: .systemFont(ofSize: 17, weight: .medium))])
        let requiredWidth = stringSize.width + 8
        
        taskCountLabel = UILabel()
        taskCountLabel.accessibilityIdentifier = "taskCountLabel"
        
        taskCountLabel.font = metrics.scaledFont(for: .systemFont(ofSize: 15, weight: .medium))
        taskCountLabel.textColor = .label
        taskCountLabel.textAlignment = .center
        taskCountLabel.text = viewModel.taskCountString
        
        taskCountLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            taskCountLabel.widthAnchor.constraint(equalToConstant: requiredWidth)
        ])
        
        let labelBarButton = UIBarButtonItem(customView: taskCountLabel)
        
        let flexibleSpaceLeft = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let flexibleSpaceRight = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        self.toolbarItems = [flexibleSpaceLeft, labelBarButton, flexibleSpaceRight, iconBarButton]
        
        self.navigationController?.isToolbarHidden = false
        self.navigationController?.toolbar.isTranslucent = false
    }
    
    private func updateTaskCountLabel() {
        taskCountLabel.text = viewModel.taskCountString
    }
    
    @objc private func addButtonTapped() {
        print("Add button tapped")
        performSegue(withIdentifier: "showAddEditScreen", sender: nil)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInitialDataLoad),
            name: .initialDataDidLoad,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTaskUpdate),
            name: .taskDidUpdate,
            object: nil
        )
    }

    @objc private func handleInitialDataLoad() {
        print("Получено уведомление о загрузке данных. Обновляем UI.")
        viewModel.fetchTasks()
    }
    
    @objc private func handleTaskUpdate() {
        print("Получено уведомление об обновлении задачи. Обновляем UI.")
        viewModel.refreshTasks()
    }
    
    private func setupBindings() {
        viewModel.onDataUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.updateTaskCountLabel()
                self?.tableView.reloadData()
            }
        }
        
        viewModel.onSingleTaskUpdated = { [weak self] taskId in
            guard let self = self else { return }
            
            let dataSource = self.viewModel.isSearching ? self.viewModel.filteredTasks : self.viewModel.tasks
            guard let rowIndex = dataSource.firstIndex(where: { $0.id == taskId }) else { return }
            let indexPath = IndexPath(row: rowIndex, section: 0)
            
            if let visibleCell = self.tableView.cellForRow(at: indexPath) as? TaskTableViewCell {
                let updatedTask = self.viewModel.task(at: indexPath)
                visibleCell.configure(with: updatedTask)
            }
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAddEditScreen" {
            let destinationVC = segue.destination as! AddEditTaskViewController
            if let indexPath = sender as? IndexPath {
                let taskToEdit = viewModel.task(at: indexPath)
                destinationVC.taskToEdit = taskToEdit
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension TaskListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TaskTableViewCell.identifier, for: indexPath) as! TaskTableViewCell
        let task = viewModel.task(at: indexPath)
        cell.configure(with: task)
        
        cell.onCheckboxTapped = { [weak self] taskId in
            self?.viewModel.toggleTaskCompletion(for: taskId)
        }
        
        return cell
    }
}


// MARK: - UITableViewDelegate
extension TaskListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "showAddEditScreen", sender: indexPath)
    }
    
    // MARK: - Context Menu Configuration
    override func tableView(_ tableView: UITableView,
                      contextMenuConfigurationForRowAt indexPath: IndexPath,
                      point: CGPoint) -> UIContextMenuConfiguration? {
           
           let task = viewModel.task(at: indexPath)

           return UIContextMenuConfiguration(
               identifier: indexPath as NSCopying,
               previewProvider: {
                   TaskPreviewViewController(task: task)
               },
               actionProvider: { _ in
                   let edit = UIAction(title: "Редактировать", image: UIImage(systemName: "square.and.pencil")) { [weak self] _ in
                       self?.performSegue(withIdentifier: "showAddEditScreen", sender: indexPath)
                   }

                   let share = UIAction(title: "Поделиться", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                       self?.shareTask(title: task.title)
                   }

                   let delete = UIAction(title: "Удалить", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                       self?.deleteTask(taskId: task.id)
                   }

                   return UIMenu(title: "", children: [edit, share, delete])
               }
           )
       }

       func tableView(_ tableView: UITableView,
                      contextMenuConfiguration configuration: UIContextMenuConfiguration,
                      highlightPreviewForItemAt indexPath: IndexPath) -> UITargetedPreview? {

           // Получаем ячейку, чтобы вычислить ее центр по вертикали
           guard let cell = tableView.cellForRow(at: indexPath) else {
               return nil
           }
           
           let target = UIPreviewTarget(
                   container: tableView,
                   center: CGPoint(x: tableView.bounds.midX, y: cell.frame.midY) // <--- ВОТ ОНО!
               )

           let dummyView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
           dummyView.backgroundColor = .clear
           
           let parameters = UIPreviewParameters()
           parameters.backgroundColor = .clear

           return UITargetedPreview(view: dummyView, parameters: parameters, target: target)
       }
  
}


// MARK: - UISearchBarDelegate
extension TaskListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.filterTasks(with: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.text = ""
        searchBar.resignFirstResponder()
        viewModel.clearSearch()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
}

// MARK: - Private Actions
extension TaskListViewController {
    private func shareTask(title: String) {
        let activityViewController = UIActivityViewController(activityItems: [title], applicationActivities: nil)
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        present(activityViewController, animated: true)
    }

    private func deleteTask(taskId: UUID) {
        viewModel.deleteTask(for: taskId)
    }
    
}
