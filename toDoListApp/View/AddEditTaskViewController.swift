//
//  AddEditTaskViewController.swift
//  toDoListApp
//
//  Created by Pavel Dolgopolov on 27.11.2025.
//

import UIKit

final class AddEditTaskViewController: UIViewController {

    // MARK: - Properties
    
    var taskToEdit: Task?
    
    private var model: AddEditTaskModel!

    // MARK: - UI Elements
    
    private lazy var titleTextField: UITextField = {
        let textField = UITextField()
        textField.accessibilityIdentifier = "titleTextField"
        textField.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        textField.textAlignment = .left
        textField.placeholder = "Новая задача"
        textField.textColor = .label
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.accessibilityIdentifier = "descriptionTextView"
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.layer.cornerRadius = 8.0
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private var originalTextViewInsets: UIEdgeInsets = .zero
    
    // свойство для хранения констрейнта заголовка
    private var titleTextFieldTopConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.model = AddEditTaskModel(taskToEdit: taskToEdit, dataService: CoreDataService.shared)
        
        self.navigationItem.largeTitleDisplayMode = .never
        self.title = ""
        
        descriptionTextView.delegate = self
        
        setupView()
        populateDataFromModel()
        setupKeyboardObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if model.isEditMode {
            descriptionTextView.becomeFirstResponder()
        } else {
            titleTextField.becomeFirstResponder()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent {
            let titleText = titleTextField.text ?? ""
            let descriptionText = descriptionTextView.textColor == .label ? descriptionTextView.text ?? "" : ""
            
            model.update(title: titleText, description: descriptionText)
            model.saveOrDelete()
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        view = UIView()
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleTextField)
        view.addSubview(dateLabel)
        view.addSubview(descriptionTextView)
        
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        titleTextField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        dateLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        descriptionTextView.setContentHuggingPriority(.defaultLow, for: .vertical)
    }
    
    private func setupConstraints() {
        // Создаем и сохраняем констрейнт, а не активируем его сразу
        titleTextFieldTopConstraint = titleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)
        
        NSLayoutConstraint.activate([
            // Используем сохраненный констрейнт
            titleTextFieldTopConstraint,
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            dateLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 16),
            dateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            descriptionTextView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 16),
            descriptionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            descriptionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            descriptionTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - Keyboard Handling
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardHeight = keyboardFrame.cgRectValue.height
        
        if originalTextViewInsets == .zero {
            originalTextViewInsets = descriptionTextView.contentInset
        }
        
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight - view.safeAreaInsets.bottom, right: 0)
        descriptionTextView.contentInset = insets
        descriptionTextView.scrollIndicatorInsets = insets
        
        if descriptionTextView.isFirstResponder {
            let cursorRect = descriptionTextView.caretRect(for: descriptionTextView.selectedTextRange!.start)
            descriptionTextView.scrollRectToVisible(cursorRect, animated: true)
        }
        
        // логика для горизонтальной ориентации
        // Проверяем текущую ориентацию интерфейса
        let isLandscape = view.window?.windowScene?.interfaceOrientation.isLandscape ?? false

        if isLandscape {
            // Скрываем кнопку "Назад"
            navigationItem.hidesBackButton = true
            
            // Поднимаем заголовок, изменяя константу констрейнта
            // Отрицательное значение поднимет его выше безопасной области
            titleTextFieldTopConstraint.constant = -30

            // Анимируем изменения для плавности
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        descriptionTextView.contentInset = originalTextViewInsets
        descriptionTextView.scrollIndicatorInsets = originalTextViewInsets
        
        // все в исходное состояние
        // Показываем кнопку "Назад"
        navigationItem.hidesBackButton = false
        
        // Возвращаем заголовок на исходную позицию
        titleTextFieldTopConstraint.constant = 8
        
        // Анимируем изменения
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Data Population
    
    private func populateDataFromModel() {
        let initialData = model.getInitialData()
        
        titleTextField.text = initialData.title
        titleTextField.placeholder = initialData.title == nil ? initialData.placeholder : nil
        
        if let description = initialData.description {
            descriptionTextView.text = description
            descriptionTextView.textColor = .label
        } else {
            descriptionTextView.text = "Описание задачи"
            descriptionTextView.textColor = .placeholderText
        }
        
        dateLabel.text = initialData.date
    }
}

// MARK: - UITextViewDelegate

extension AddEditTaskViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = nil
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            textView.text = "Описание задачи"
            textView.textColor = .placeholderText
        }
    }
}
