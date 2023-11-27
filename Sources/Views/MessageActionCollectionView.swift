//
//  MessageActionCollectionView.swift
//  ChatLLM
//
//  Created by Daniel on 11/14/23.
//

import UIKit

public enum MessageAction {
    case copy
    case share
    case reask // copy & paste into input
    case regenerate // remove last user message and ai response, and reask automatically
    case visualize
    case stopStream
    case speakOn
    case speakOff
    
    var localizedTitle: String {
        switch self {
        case .copy:
            return "Copy"
        case .share:
            return "Share"
        case .reask:
            return "Re-Ask"
        case .regenerate:
            return "Regenerate"
        case .visualize:
            return "Visualize"
        case .stopStream:
            return "Stop"
        case .speakOn:
            return "Speak"
        case .speakOff:
            return "Stop"
        }
    }
    
    var symbol: String {
        switch self {
        case .copy:
            return "doc.on.doc"
        case .share:
            return "square.and.arrow.up"
        case .reask:
            return "arrow.clockwise"
        case .regenerate:
            return "arrow.clockwise"
        case .visualize:
            return "photo.artframe"
        case .stopStream:
            return "stop"
        case .speakOn:
            return "speaker.wave.2"
        case .speakOff:
            return "speaker.slash"
        }
    }
}

protocol MessageActionCollectionViewListener {
    func didSelectAction(action: MessageAction, actionCell: MessageActionCell)

}

protocol MessageActionCollectionViewDataSource {
    func localizedTitle(action: MessageAction) -> String?
    func symbol(action: MessageAction) -> String?
}

class MessageActionCollectionView: UIView {
    private let sidePadding: CGFloat = 12
    private let bottomPadding: CGFloat = 4

    public var listener: MessageActionCollectionViewListener?
    public var dataSource: MessageActionCollectionViewDataSource?

    public var actionBackgroundColor: UIColor?
    public var actions: [MessageAction] = [] {
        didSet {
            self.collectionView.reloadData()
        }
    }

    public lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.register(MessageActionCell.self, forCellWithReuseIdentifier: "MessageActionCell")
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: sidePadding, bottom: bottomPadding, right: sidePadding)
    
        return collectionView
    }()
    
    public init() {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func layout() {
        self.addSubview(collectionView)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: self.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -bottomPadding)
        ])
        
      
    }

}

extension MessageActionCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.actions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MessageActionCell", for: indexPath) as! MessageActionCell
        let action = self.actions[indexPath.item]
        let symbol: String = dataSource?.symbol(action: action) ?? action.symbol
        let localizedTitle: String = dataSource?.localizedTitle(action: action) ?? action.localizedTitle
        cell.configure(with: symbol, title: localizedTitle, baseBackgroundColor: self.actionBackgroundColor)
        return cell
    }
}

extension MessageActionCollectionView: UICollectionViewDelegate {
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let actionCell = collectionView.cellForItem(at: indexPath) as? MessageActionCell else {
            return
        }
        let action = self.actions[indexPath.item]
        self.listener?.didSelectAction(action: action, actionCell: actionCell)
        self.animateCellPush(collectionView, itemAt: indexPath)
    }
    
    func animateCellPush(_ collectionView: UICollectionView, itemAt indexPath: IndexPath) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { // Very short delay to allow for collectionView refresh or reload
            guard let cell = collectionView.cellForItem(at: indexPath) as? MessageActionCell else {
                return
            }
            UIView.animate(withDuration: 0.1,
                           animations: {
                cell.button.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            },
                           completion: { _ in
                UIView.animate(withDuration: 0.3) {
                    cell.button.transform = CGAffineTransform.identity
                }
            })
        }
    }
}

extension MessageActionCollectionView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let action = self.actions[indexPath.item]
        let symbol: String = dataSource?.symbol(action: action) ?? action.symbol
        let localizedTitle: String = dataSource?.localizedTitle(action: action) ?? action.localizedTitle
        let config = MessageActionCell.buttonConfiguration(with: symbol, title: localizedTitle)
        let button = UIButton(configuration: config, primaryAction: nil)
        button.sizeToFit()
        return CGSize(width: button.frame.width, height: 32)
    }
}

public class MessageActionCell: UICollectionViewCell {
    public let button = UIButton(configuration: .filled(), primaryAction: nil)

    static func buttonConfiguration(with symbolName: String, title: String, baseBackgroundColor: UIColor? = nil) -> UIButton.Configuration {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        if let baseBackgroundColor = baseBackgroundColor {
            config.baseBackgroundColor = baseBackgroundColor
        }
        config.attributedTitle = AttributedString(title,
                                                  attributes: AttributeContainer([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 13.5)]))
        config.image = UIImage(systemName: symbolName)?.applyingSymbolConfiguration(.init(pointSize: 12))
        config.imagePlacement = .leading
        config.imagePadding = 8
        return config
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupButton() {
        contentView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = false
        
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            button.topAnchor.constraint(equalTo: contentView.topAnchor),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with symbolName: String, title: String, baseBackgroundColor: UIColor?) {
        button.configuration = MessageActionCell.buttonConfiguration(with: symbolName, title: title, baseBackgroundColor: baseBackgroundColor)
    }
}

