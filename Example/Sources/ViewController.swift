//
//  ViewController.swift
//  Example
//
//  Created by Yoshimasa Niwa on 9/20/20.
//

import UIKit
import KeyboardGuide

class ViewController: UIViewController {
    var doneButton: UIBarButtonItem!

    init() {
        super.init(nibName: nil, bundle: nil)

        self.title = "編集"

        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneDidTap(_:)))
        self.navigationItem.rightBarButtonItem = doneButton
        self.doneButton = doneButton
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    private let maxLength = 300

    var label: UILabel?
    var textView: UITextView?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.systemBackground

        var constraints = [NSLayoutConstraint]()
        defer {
            NSLayoutConstraint.activate(constraints)
        }

        let label = UILabel()
        label.font = .systemFont(ofSize: 20.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(label.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 20.0))
        constraints.append(label.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor))
        view.addSubview(label)
        self.label = label

        let textView = UITextView()
        textView.textStorage.delegate = self
        textView.delegate = self
        textView.font = .systemFont(ofSize: 20.0)
        textView.text = .example
        textView.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(textView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20.0))
        constraints.append(textView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor))
        constraints.append(textView.bottomAnchor.constraint(equalTo: view.keyboardSafeArea.layoutGuide.bottomAnchor))
        constraints.append(textView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor))
        view.addSubview(textView)
        self.textView = textView

        update()
    }

    private var shouldUpdate: Bool = false

    private func setNeedsUpdate() {
        shouldUpdate = true
        RunLoop.main.perform { [weak self] in
            guard let self = self,
                  self.shouldUpdate else {
                return
            }
            self.shouldUpdate = false
            self.update()
        }
    }

    private func update() {
        guard let textView = textView,
              let label = label else {
            return
        }

        let remainingCount = maxLength - textView.text.utf16.count
        if remainingCount < 0 {
            label.text = "\(-remainingCount) 文字超過"
            label.textColor = .systemRed
            doneButton.isEnabled = false
        } else {
            label.text = "残り \(remainingCount)文字"
            label.textColor = .label
            doneButton.isEnabled = true
        }
    }

    // MARK: - Actions

    @objc
    func doneDidTap(_ sender: AnyObject) {
        // Callback for presenter here.
    }
}

// MARK: -

extension ViewController: NSTextStorageDelegate {
    func textStorage(_ textStorage: NSTextStorage,
                     didProcessEditing editedMask: NSTextStorage.EditActions,
                     range editedRange: NSRange,
                     changeInLength delta: Int) {
        guard editedMask.contains(.editedCharacters) else {
            return
        }

        let string = textStorage.string
        DispatchQueue.global(qos: .utility).async {
            let overflowedCount = min(self.maxLength - string.unicodeScalars.count, 0)
            let overflowedBeginIndex = string.unicodeScalars.index(string.unicodeScalars.endIndex, offsetBy: overflowedCount)
            let overflowedBeginOffset = overflowedBeginIndex.utf16Offset(in: string)
            let overflowedEndOffset = string.unicodeScalars.endIndex.utf16Offset(in: string)

            let overflowedRange = NSRange(location: overflowedBeginOffset,
                                          length: overflowedEndOffset - overflowedBeginOffset)

            DispatchQueue.main.async {
                guard textStorage.string == string else {
                    return
                }

                textStorage.beginEditing()
                textStorage.removeAttribute(.backgroundColor,
                                            range: NSRange(location: 0, length: textStorage.length))
                textStorage.addAttribute(.backgroundColor, value: UIColor.systemRed.withAlphaComponent(0.4),
                                         range: overflowedRange)
                textStorage.endEditing()
            }
        }
    }
}

// MARK: -

extension ViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if range.length == 0 && text.length == 0 {
            setNeedsUpdate()
        }
        return true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        setNeedsUpdate()
    }

    func textViewDidChange(_ textView: UITextView) {
        setNeedsUpdate()
    }
}

