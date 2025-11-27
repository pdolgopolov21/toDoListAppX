import UIKit

class AddEditTaskViewController: UIViewController {

    // MARK: - Properties
    
    var taskToEdit: Task?
    
    private var isEditMode: Bool {
        return taskToEdit != nil
    }
    
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
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter
    }()
    
    // Сохраняем начальные отступы текста
    private var originalTextViewInsets: UIEdgeInsets = .zero

    // MARK: - Lifecycle

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleTextField)
        view.addSubview(dateLabel)
        view.addSubview(descriptionTextView)
        
        setupUI()
        setupConstraints()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.largeTitleDisplayMode = .never
        self.title = ""
        
        descriptionTextView.delegate = self
        
        populateData()
        setupKeyboardObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isEditMode {
            descriptionTextView.becomeFirstResponder()
        } else {
            titleTextField.becomeFirstResponder()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent {
            
            let titleText = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let titleIsEmpty = titleText.isEmpty
            
            let descriptionText = descriptionTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let descriptionIsNotEmpty = !descriptionText.isEmpty && descriptionTextView.textColor == .label
            
            // генерируем заголовок если он пуст из описания
            var finalTitle = titleText
            if titleIsEmpty && descriptionIsNotEmpty {
                finalTitle = getWords(from: descriptionText, maxCount: 2)
            }
            
            if isEditMode {
                // заголовок пуст, удаляем задачу
                if finalTitle.isEmpty {
                    print("Заголовок и описание пусты. Удаляем задачу.")
                    guard let taskId = taskToEdit?.id else { return }
                    CoreDataService.shared.deleteTask(for: taskId) {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .taskDidUpdate, object: nil)
                        }
                    }
                    return
                }
            }

            guard !finalTitle.isEmpty else {
                print("Заголовок пуст, задача не будет создана.")
                return
            }
            
            titleTextField.text = finalTitle
            saveTask()
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        titleTextField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        dateLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        descriptionTextView.setContentHuggingPriority(.defaultLow, for: .vertical)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title TextField
            titleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Date Label
            dateLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 16),
            dateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Description TextView
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
        
        // Сохраняем начальные отступы при первом появлении клавиатуры
        if originalTextViewInsets == .zero {
            originalTextViewInsets = descriptionTextView.contentInset
        }
        
        // Устанавливаем отступы, чтобы текст не заезжал под клавиатуру
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight - view.safeAreaInsets.bottom, right: 0)
        descriptionTextView.contentInset = insets
        descriptionTextView.scrollIndicatorInsets = insets
        
        // Прокручиваем текстовое поле к курсору
        if descriptionTextView.isFirstResponder {
            let cursorRect = descriptionTextView.caretRect(for: descriptionTextView.selectedTextRange!.start)
            descriptionTextView.scrollRectToVisible(cursorRect, animated: true)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        // Возвращаем начальные отступы
        descriptionTextView.contentInset = originalTextViewInsets
        descriptionTextView.scrollIndicatorInsets = originalTextViewInsets
    }
    
    // MARK: - Data Population
    
    private func populateData() {
        if isEditMode {
            if let title = taskToEdit?.title, !title.isEmpty {
                titleTextField.text = title
                titleTextField.placeholder = nil
            } else if let description = taskToEdit?.taskDescription, !description.isEmpty {
                let generatedTitle = getWords(from: description, maxCount: 2)
                titleTextField.text = generatedTitle
                titleTextField.placeholder = nil
            } else {
                titleTextField.text = nil
                titleTextField.placeholder = "Новая задача"
            }
            
            if let desc = taskToEdit?.taskDescription, !desc.isEmpty {
                descriptionTextView.text = desc
                descriptionTextView.textColor = .label
            } else {
                descriptionTextView.text = "Описание задачи"
                descriptionTextView.textColor = .placeholderText
            }
            
            dateLabel.text = dateFormatter.string(from: taskToEdit?.createdDate ?? Date())
        } else {
            titleTextField.text = nil
            titleTextField.placeholder = "Новая задача"
            dateLabel.text = dateFormatter.string(from: Date())
        }
    }
    
    // MARK: - Helper Methods
    
    private func getWords(from string: String, maxCount: Int) -> String {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = trimmedString.components(separatedBy: .whitespacesAndNewlines)
        let selectedWords = words.prefix(maxCount)
        return selectedWords.joined(separator: " ")
    }
    
    // MARK: - Saving Logic

    private func saveTask() {
        // Используем trim() для проверки заголовка
        guard let title = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
            print("Попытка сохранить задачу с пустым заголовком. Операция отменена.")
            return
        }
        
        // Извлекаем и очищаем описание
        var description = ""
        if descriptionTextView.textColor == .label {
            description = descriptionTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        
        if isEditMode {
            guard let taskId = taskToEdit?.id else { return }
            CoreDataService.shared.updateTask(id: taskId, title: title, description: description) {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .taskDidUpdate, object: nil)
                }
            }
        } else {
            CoreDataService.shared.createTask(title: title, description: description) {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .taskDidUpdate, object: nil)
                }
            }
        }
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
        // Удаляем  trim лишнее
        if textView.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            textView.text = "Описание задачи"
            textView.textColor = .placeholderText
        }
    }
}
