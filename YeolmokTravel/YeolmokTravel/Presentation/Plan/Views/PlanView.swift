//
//  PlanView.swift
//  YeolmokTravel
//
//  Created by 김동욱 on 2022/12/20.
//

import UIKit
import SnapKit
import Combine

/// TravelPlan View
final class PlanView: UIViewController {
    // MARK: - Properties
    var viewModel: TravelPlaner!
    private var subscriptions = Set<AnyCancellable>()
    private var titleLabel: UILabel = {
        let label = UILabel()
        
        label.textAlignment = .center
        label.textColor = .white
        label.text = TextConstants.title
        label.font = .boldSystemFont(ofSize: AppLayoutConstants.titleFontSize)
        
        return label
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .custom)
        
        button.setBackgroundImage(UIImage(systemName: TextConstants.plusIconName), for: .normal)
        button.tintColor = AppStyles.mainColor
        button.addTarget(self, action: #selector(touchUpAddButton), for: .touchUpInside)
        
        return button
    }()
    
    private var planTableView: UITableView = {
        let tableView = UITableView()
        
        tableView.register(PlanTableViewCell.self,
                           forCellReuseIdentifier: PlanTableViewCell.identifier)
        tableView.backgroundColor = .black
        tableView.layer.cornerRadius = LayoutConstants.cornerRadius
        tableView.layer.borderWidth = AppLayoutConstants.borderWidth
        tableView.layer.borderColor = UIColor.white.cgColor
        tableView.isScrollEnabled = false
        
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configure()
        setBindings()
    }
}

// MARK: - Configure View
private extension PlanView {
    private func configureView() {
        view.backgroundColor = .black
        configureHierarchy()
        configureLayoutConstraint()
    }
    
    func configureHierarchy() {
        [titleLabel, addButton, planTableView].forEach {
            view.addSubview($0)
        }
    }
    
    func configureLayoutConstraint() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.equalToSuperview()
                .inset(AppLayoutConstants.spacing)
        }
        
        addButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel.snp.centerY)
            $0.trailing.equalToSuperview()
                .inset(AppLayoutConstants.spacing)
            $0.size.equalTo(LayoutConstants.buttonSize)
        }
        
        planTableView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom)
                .offset(LayoutConstants.planTableViewTopOffset)
            $0.leading.trailing.equalToSuperview()
                .inset(AppLayoutConstants.spacing)
            $0.height.equalTo(viewModel.planCount * Int(LayoutConstants.cellHeight))
        }
    }
    
    func configure() {
        planTableView.delegate = self
        planTableView.dataSource = self
    }
}

// MARK: - User Interaction
private extension PlanView {
    func setBindings() {
        viewModel.publisher
            .sink { self.reload() }
            .store(in: &subscriptions)
    }
    
    @objc func touchUpAddButton() {
        present(viewModel.setUpWritingView(.add), animated: true)
    }
    
    @MainActor func reload() {
        planTableView.snp.updateConstraints {
            $0.height.equalTo(viewModel.planCount * Int(LayoutConstants.cellHeight))
        }
        planTableView.reloadData()
    }
}

// MARK: - TableView
extension PlanView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PlanTableViewCell.identifier, for: indexPath) as? PlanTableViewCell else { return UITableViewCell() }
        cell.titleLabel.text = viewModel.title(indexPath.row)
        cell.dateLabel.text = viewModel.date(indexPath.row)
        cell.descriptionLabel.text = viewModel.description(indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.planCount
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.delete(indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            planTableView.snp.updateConstraints {
                $0.height.equalTo(viewModel.planCount * Int(LayoutConstants.cellHeight))
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        LayoutConstants.cellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        present(viewModel.setUpWritingView(at: indexPath.row, .edit), animated: true)
    }
}

private enum TextConstants {
    static let title = "Plans"
    static let plusIconName = "plus"
}

private enum LayoutConstants {
    static let buttonSize = CGSize(width: 44.44, height: 44.44)
    static let planTableViewTopOffset: CGFloat = 20
    static let cornerRadius: CGFloat = 10
    static let cellHeight: CGFloat = 100
}
