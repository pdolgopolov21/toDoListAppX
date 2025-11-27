// TaskTableViewCell.swift
import UIKit

// не планируется наследовать
final class TaskTableViewCell: UITableViewCell {
    
    // MARK: - UI Elements 
        let checkboxButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var verticalStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, dateLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Properties
    static let identifier = "TaskCellIdentifier"
    
    private var taskId: UUID?
    var onCheckboxTapped: ((UUID) -> Void)?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupCheckboxButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods

    private func setupUI() {
        contentView.addSubview(checkboxButton)
        contentView.addSubview(verticalStackView)
        
        NSLayoutConstraint.activate([
            // Checkbox constraints
            checkboxButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            checkboxButton.topAnchor.constraint(equalTo: verticalStackView.topAnchor),
            checkboxButton.widthAnchor.constraint(equalToConstant: 24),
            checkboxButton.heightAnchor.constraint(equalToConstant: 24),
            
            // StackView constraints
            verticalStackView.leadingAnchor.constraint(equalTo: checkboxButton.trailingAnchor, constant: 12),
            verticalStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            verticalStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            verticalStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    private func setupCheckboxButton() {
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        checkboxButton.configuration = config
        
        checkboxButton.addTarget(self, action: #selector(checkboxButtonTapped), for: .touchUpInside)
    }
    
    @objc private func checkboxButtonTapped() {
        guard let taskId = taskId else { return }
        onCheckboxTapped?(taskId)
    }
    
    // MARK: - Configuration

    func configure(with task: Task) {
        self.taskId = task.id
        
        var updatedConfig = checkboxButton.configuration
        
        if task.isCompleted {
            updatedConfig?.image = UIImage(systemName: "checkmark.circle.fill")
            updatedConfig?.baseForegroundColor = .systemBlue
            
            // Зачеркиваем заголовок
            let attributedTitle = NSAttributedString(
                string: task.title,
                attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
            )
            titleLabel.attributedText = attributedTitle
            // Делаем заголовок и описание серыми
            titleLabel.textColor = .secondaryLabel
            descriptionLabel.textColor = .secondaryLabel
            
        } else {
            updatedConfig?.image = UIImage(systemName: "circle")
            updatedConfig?.baseForegroundColor = .systemGray3
            
            titleLabel.attributedText = nil
            // Возвращаем нормальный цвет
            titleLabel.text = task.title
            titleLabel.textColor = .label
            descriptionLabel.textColor = .label
        }
        
        checkboxButton.configuration = updatedConfig
        
        descriptionLabel.text = task.taskDescription.isEmpty ? "Нет описания" : task.taskDescription
        dateLabel.text = dateFormatter.string(from: task.createdDate)
    }
    
    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Сбрасываем все, что может вызывать конфликты
        taskId = nil
        onCheckboxTapped = nil
        
        // Сбрасываем состояние кнопки
        var config = checkboxButton.configuration
        config?.image = nil
        checkboxButton.configuration = config
        
        //  Сбрасываем и attributedText, и text
        titleLabel.attributedText = nil
        titleLabel.text = nil
        
        descriptionLabel.text = nil
        dateLabel.text = nil
    }
}
