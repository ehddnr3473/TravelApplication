//
//  WritingPlanViewController.swift
//  YeolmokTravel
//
//  Created by 김동욱 on 2022/12/20.
//

import UIKit
import SnapKit

final class WritingPlanViewController: UIViewController, Writable {
    typealias Model = WritablePlan
    // MARK: - Properties
    var model: Model!
    var writingStyle: WritingStyle!
    var addDelegate: PlanTransfer?
    var editDelegate: PlanTransfer?
    var planListIndex: Int?
    
    private let topBarStackView: UIStackView = {
        let stackView = UIStackView()
        
        stackView.axis = .horizontal
        stackView.distribution = .equalCentering
        stackView.backgroundColor = .darkGray
        stackView.layer.cornerRadius = LayoutConstants.stackViewCornerRadius
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: LayoutConstants.topBottomMargin,
                                               left: LayoutConstants.sideMargin,
                                               bottom: LayoutConstants.topBottomMargin,
                                               right: LayoutConstants.sideMargin)
        stackView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        return stackView
    }()
    
    private let barTitleLabel: UILabel = {
        let label = UILabel()
        
        label.textAlignment = .center
        label.font = .boldSystemFont(ofSize: LayoutConstants.largeFontSize)
        label.textColor = .white
        
        return label
    }()
    
    private lazy var saveBarButton: UIButton = {
        let button = UIButton(type: .custom)
        
        button.setTitle(TextConstants.saveButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(touchUpSaveBarButton), for: .touchUpInside)
        button.setTitleColor(AppStyles.mainColor, for: .normal)
        
        return button
    }()
    
    private lazy var cancelBarButton: UIButton = {
        let button = UIButton(type: .custom)
        
        button.setTitle(TextConstants.cancelButtonTItle, for: .normal)
        button.addTarget(self, action: #selector(touchUpCancelBarButton), for: .touchUpInside)
        
        return button
    }()
    
    private let titleTextField: UITextField = {
        let textField = UITextField()
        
        textField.textColor = .white
        textField.backgroundColor = .black
        textField.placeholder = TextConstants.placeholder
        textField.layer.cornerRadius = LayoutConstants.cornerRadius
        textField.layer.borderWidth = LayoutConstants.borderWidth
        textField.layer.borderColor = UIColor.white.cgColor
        textField.font = .boldSystemFont(ofSize: LayoutConstants.largeFontSize)
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        
        textField.leftView = UIView(frame: CGRect(x: .zero,
                                                  y: .zero,
                                                  width: LayoutConstants.spacing,
                                                  height: .zero))
        textField.leftViewMode = .always
        
        return textField
    }()
    
    private let descriptionTextView: UITextView = {
        let textView = UITextView()
        
        textView.textColor = .white
        textView.backgroundColor = .black
        textView.layer.cornerRadius = LayoutConstants.cornerRadius
        textView.layer.borderWidth = LayoutConstants.borderWidth
        textView.layer.borderColor = UIColor.white.cgColor
        textView.font = .boldSystemFont(ofSize: LayoutConstants.mediumFontSize)
        
        return textView
    }()
    
    private let scheduleTitleLabel: UILabel = {
        let label = UILabel()
        
        label.text = TextConstants.schedule
        label.textAlignment = .center
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: LayoutConstants.largeFontSize)
        
        return label
    }()
    
    private lazy var addScheduleButton: UIButton = {
        let button = UIButton(type: .custom)
        
        button.setImage(UIImage(systemName: TextConstants.plusIcon), for: .normal)
        button.addTarget(self, action: #selector(touchUpAddScheduleButton), for: .touchUpInside)
        button.tintColor = AppStyles.mainColor
        
        return button
    }()
    
    private let scheduleTableView: UITableView = {
        let tableView = UITableView()
        
        tableView.register(ScheduleTableViewCell.self,
                           forCellReuseIdentifier: ScheduleTableViewCell.identifier)
        tableView.backgroundColor = .black
        tableView.layer.cornerRadius = LayoutConstants.tableViewCornerRadius
        tableView.layer.borderWidth = LayoutConstants.borderWidth
        tableView.layer.borderColor = UIColor.white.cgColor
        
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpUI()
        configure()
    }
}

// MARK: - SetUp View
extension WritingPlanViewController {
    private func setUpUI() {
        view.backgroundColor = .black
        
        switch writingStyle {
        case .add:
            barTitleLabel.text = "\(writingStyle.rawValue) \(TextConstants.plan)"
        case .edit:
            barTitleLabel.text = "\(writingStyle.rawValue) \(TextConstants.plan)"
        case .none:
            break
        }
        
        titleTextField.text = model.title
        descriptionTextView.text = model.description
        
        setUpHierachy()
        setUpLayout()
    }
    private func setUpHierachy() {
        [cancelBarButton, barTitleLabel, saveBarButton].forEach {
            topBarStackView.addArrangedSubview($0)
        }
        
        [topBarStackView, titleTextField, descriptionTextView, scheduleTitleLabel, addScheduleButton, scheduleTableView].forEach {
            view.addSubview($0)
        }
    }
    
    private func setUpLayout() {
        topBarStackView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.width.equalToSuperview()
            $0.height.greaterThanOrEqualTo(LayoutConstants.stackViewHeight)
        }
        
        titleTextField.snp.makeConstraints {
            $0.top.equalTo(topBarStackView.snp.bottom).offset(LayoutConstants.largeSpacing)
            $0.leading.trailing.equalToSuperview()
                .inset(LayoutConstants.spacing)
        }
        
        descriptionTextView.snp.makeConstraints {
            $0.top.equalTo(titleTextField.snp.bottom)
                .offset(LayoutConstants.spacing)
            $0.leading.trailing.equalToSuperview()
                .inset(LayoutConstants.spacing)
            $0.height.equalTo(100)
        }
        
        scheduleTitleLabel.snp.makeConstraints {
            $0.top.equalTo(descriptionTextView.snp.bottom)
                .offset(LayoutConstants.largeSpacing)
            $0.leading.equalToSuperview()
                .inset(LayoutConstants.schedultTitleLeading)
        }
        
        addScheduleButton.snp.makeConstraints {
            $0.centerY.equalTo(scheduleTitleLabel)
            $0.trailing.equalToSuperview()
                .inset(LayoutConstants.largeSpacing)
        }
        
        scheduleTableView.snp.makeConstraints {
            $0.top.equalTo(scheduleTitleLabel.snp.bottom)
                .offset(LayoutConstants.spacing)
            $0.leading.trailing.equalToSuperview()
                .inset(LayoutConstants.spacing)
            $0.height.equalTo(model.schedulesCount * Int(LayoutConstants.cellHeight))
        }
    }
    
    private func configure() {
        scheduleTableView.delegate = self
        scheduleTableView.dataSource = self
    }
    
    @objc func touchUpSaveBarButton() {
        model.setPlan(titleTextField.text ?? "", descriptionTextView.text)
        if model.verifyTitleText() {
            alertWillAppear()
            return
        } else {
            switch writingStyle {
            case .add:
                addDelegate?.writingHandler(model.plan, nil)
                addDelegate = nil
                dismiss(animated: true)
            case .edit:
                if let index = planListIndex {
                    editDelegate?.writingHandler(model.plan, index)
                    editDelegate = nil
                    dismiss(animated: true)
                }
            case .none:
                dismiss(animated: true)
            }
        }
    }
    
    @objc func touchUpCancelBarButton() {
        model.setPlan(titleTextField.text ?? "", descriptionTextView.text)
        if model.isChanged {
            switch writingStyle {
            case .add:
                actionSheetWillApear(AlertText.addTitle, AlertText.message)
            case .edit:
                actionSheetWillApear(AlertText.editTitle, AlertText.message)
            case .none:
                dismiss(animated: true)
            }
        } else {
            dismiss(animated: true)
        }
    }
    
    @objc func touchUpAddScheduleButton() {
        print("touch")
    }
    
}

extension WritingPlanViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ScheduleTableViewCell.identifier,
                                                       for: indexPath) as? ScheduleTableViewCell else { return UITableViewCell() }
        let schedule = model.schedule(indexPath.row)
        cell.titleLabel.text = schedule.title
        cell.descriptionLabel.text = schedule.description
        cell.dateLabel.text = schedule.date?.formatted()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        model.schedulesCount
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }
}

private enum LayoutConstants {
    static let spacing: CGFloat = 8
    static let largeSpacing: CGFloat = 20
    static let stackViewCornerRadius: CGFloat = 10
    static let cornerRadius: CGFloat = 5
    static let tableViewCornerRadius: CGFloat = 10
    static let borderWidth: CGFloat = 1
    static let largeFontSize: CGFloat = 25
    static let mediumFontSize: CGFloat = 20
    static let topBottomMargin: CGFloat = 10
    static let sideMargin: CGFloat = 15
    static let stackViewHeight: CGFloat = 50
    static let schedultTitleLeading: CGFloat = 15
    static let cellHeight: CGFloat = 100
}

private enum TextConstants {
    static let saveButtonTitle = "Save"
    static let cancelButtonTItle = "Cancel"
    static let plan = "Plan"
    static let placeholder = "제목"
    static let descriptionPlaceolder = "상세"
    static let schedule = "Schedule"
    static let plusIcon = "plus"
}

private enum AlertText {
    static let addTitle = "입력한 내용이 있습니다."
    static let editTitle = "변경된 내용이 있습니다."
    static let message = "저장하지 않고 돌아가시겠습니까?"
}
