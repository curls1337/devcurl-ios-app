import UIKit

public class MessageCell: UITableViewCell {
    public static let identifier = "MessageCell"

    private let bubbleView = UIView()
    private let senderLabel = UILabel()
    private let contentLabel = UILabel()

    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        bubbleView.layer.cornerRadius = 18
        bubbleView.layer.masksToBounds = true
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)

        senderLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        senderLabel.textColor = UIColor(white: 0.65, alpha: 1.0)
        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(senderLabel)

        contentLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(contentLabel)

        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14)

        NSLayoutConstraint.activate([
            senderLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            senderLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 4),

            bubbleView.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 3),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.82),

            contentLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            contentLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
            contentLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            contentLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14)
        ])
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(with message: Message) {
        contentLabel.text = message.content

        if message.isUser {
            bubbleView.backgroundColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0) // iOS System Blue
            contentLabel.textColor = .white
            senderLabel.text = "Pak cURLdev"
            senderLabel.textAlignment = .right

            leadingConstraint.isActive = false
            trailingConstraint.isActive = true
        } else {
            bubbleView.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.0) // Deep Dark Slate
            contentLabel.textColor = UIColor(white: 0.95, alpha: 1.0)
            senderLabel.text = message.sender
            senderLabel.textAlignment = .left

            trailingConstraint.isActive = false
            leadingConstraint.isActive = true
        }
    }
}
