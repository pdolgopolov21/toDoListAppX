import UIKit

final class TaskPreviewViewController: UIViewController {
    
    private let task: Task
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    init(task: Task) {
        self.task = task
        super.init(nibName: nil, bundle: nil)
        
        //выравнивание не помогло - но оставим
        preferredContentSize = CGSize(width: UIScreen.main.bounds.width, height: 300)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:)") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupUI()
        fillData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let availableTextWidth = view.bounds.width - 32
        let fittingSize = CGSize(width: availableTextWidth, height: .greatestFiniteMagnitude)
        
        let requiredHeight = contentView.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height + 32 // Добавляем отступы сверху и снизу
        
        let maxHeight = UIScreen.main.bounds.height * 0.8
        
        preferredContentSize.height = min(requiredHeight, maxHeight)
    }
    
    private func setupUI() {
        // scroll
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // content
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // ЛЕЙБЛЫ
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.numberOfLines = 0
        
        dateLabel.font = .systemFont(ofSize: 14)
        dateLabel.textColor = .secondaryLabel
        
        descriptionLabel.font = .systemFont(ofSize: 17)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byTruncatingTail
        descriptionLabel.text = description
        
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            dateLabel,
            descriptionLabel
        ])
        
        stack.axis = .vertical
        stack.spacing = 8
        
        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        // Эти ограничения создают визуальные отступы в 16pt с каждой стороны
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func fillData() {
        let title = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = task.taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        titleLabel.text = title
        dateLabel.text = DateFormatter.taskDateFormatter.string(from: task.createdDate)
        descriptionLabel.text = description
        
        if task.isCompleted {
            titleLabel.attributedText = NSAttributedString(
                string: title,
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: UIColor.secondaryLabel
                ]
            )
        } else {
            titleLabel.attributedText = NSAttributedString(
                string: title,
                attributes: [.foregroundColor: UIColor.label]
            )
        }
    }
}

extension DateFormatter {
    static let taskDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yy"
        return f
    }()
}
