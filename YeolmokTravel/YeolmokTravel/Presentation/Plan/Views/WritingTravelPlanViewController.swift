//
//  WritingPlanViewController.swift
//  YeolmokTravel
//
//  Created by 김동욱 on 2022/12/20.
//

import UIKit
import Combine
import CoreLocation

protocol ScheduleTransferDelegate {
    func create(_ schedule: Schedule)
    func update(at index: Int, _ schedule: Schedule)
}

/*
 - 여행 계획의 자세한 일정 추가 및 수정을 위한 ViewController
 - Schedules의 coordinate(좌표 - 위도(latitude) 및 경도(longitude)) 정보를 취합해서 MKMapView로 표현
 */
final class WritingTravelPlanViewController: UIViewController, Writable {
    typealias WritableModelType = TravelPlan
    // MARK: - Properties
    var writingStyle: WritingStyle
    var delegate: TravelPlanTransferDelegate
    var planListIndex: Int?
    private let viewModel: ConcreteWritingTravelPlanViewModel
    private let mapProvider: Mappable
    
    private var subscriptions = Set<AnyCancellable>()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.isScrollEnabled = true
        return scrollView
    }()
    
    private let scrollViewContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    private let writingTravelPlanView: WritingTravelPlanView = {
        let writingTravelPlanView = WritingTravelPlanView()
        writingTravelPlanView.backgroundColor = .systemBackground
        return writingTravelPlanView
    }()
    
    private let scheduleTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(TravelPlanTableViewCell.self,
                           forCellReuseIdentifier: TravelPlanTableViewCell.identifier)
        tableView.backgroundColor = .systemBackground
        tableView.layer.cornerRadius = LayoutConstants.tableViewCornerRadius
        tableView.layer.borderWidth = AppLayoutConstants.borderWidth
        tableView.layer.borderColor = UIColor.white.cgColor
        tableView.isScrollEnabled = false
        return tableView
    }()
    
    private lazy var mapTitleLabel: UILabel = {
        let label = UILabel()
        label.text = TextConstants.map
        label.textAlignment = .center
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: AppLayoutConstants.largeFontSize)
        return label
    }()
    
    private let mapButtonSetView: MapButtonSetView = {
        let mapButtonSetView = MapButtonSetView()
        return mapButtonSetView
    }()
    
    init(_ viewModel: ConcreteWritingTravelPlanViewModel, _ mapProvider: Mappable, _ writingStyle: WritingStyle, delegate: TravelPlanTransferDelegate) {
        self.viewModel = viewModel
        self.mapProvider = mapProvider
        self.writingStyle = writingStyle
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        embedMapView()
        configure()
        configureWritingTravelPlanViewValue()
        setBindings()
    }
}

// MARK: - Configure View
private extension WritingTravelPlanViewController {
    func configureView() {
        view.backgroundColor = .systemBackground
        configureNavigationItems()
        configureHierarchy()
        configureLayoutConstraint()
    }
    
    func configureHierarchy() {
        [writingTravelPlanView, scheduleTableView].forEach {
            scrollViewContainer.addSubview($0)
        }
        
        scrollView.addSubview(scrollViewContainer)
        
        [scrollView].forEach {
            view.addSubview($0)
        }
    }
    
    func configureLayoutConstraint() {
        scrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
                .inset(AppLayoutConstants.spacing)
            $0.leading.bottom.trailing.equalToSuperview()
                .inset(AppLayoutConstants.spacing)
        }
        
        scrollViewContainer.snp.makeConstraints {
            $0.top.equalTo(scrollView.contentLayoutGuide.snp.top)
            $0.leading.equalTo(scrollView.contentLayoutGuide.snp.leading)
            $0.bottom.equalTo(scrollView.contentLayoutGuide.snp.bottom)
            $0.trailing.equalTo(scrollView.contentLayoutGuide.snp.trailing)
            
            $0.width.equalTo(scrollView.frameLayoutGuide.snp.width)
            $0.height.equalTo(viewModel.scrollViewContainerheight)
        }
        
        writingTravelPlanView.snp.makeConstraints {
            $0.top.equalTo(scrollViewContainer.snp.top)
                .inset(AppLayoutConstants.spacing)
            $0.width.equalTo(scrollViewContainer.snp.width)
            $0.height.equalTo(AppLayoutConstants.writingTravelPlanViewHeight)
        }
        
        scheduleTableView.snp.makeConstraints {
            $0.top.equalTo(writingTravelPlanView.snp.bottom)
                .offset(AppLayoutConstants.spacing)
            $0.width.equalTo(scrollViewContainer.snp.width)
            $0.height.equalTo(viewModel.model.value.schedules.count * Int(AppLayoutConstants.cellHeight))
        }
    }
    
    func configureWritingTravelPlanViewValue() {
        writingTravelPlanView.titleTextField.text = viewModel.model.value.title
        writingTravelPlanView.descriptionTextView.text = viewModel.model.value.description
        writingTravelPlanView.editScheduleButton.addTarget(self, action: #selector(touchUpEditButton), for: .touchUpInside)
        writingTravelPlanView.addScheduleButton.addTarget(self, action: #selector(touchUpCreateScheduleButton), for: .touchUpInside)
    }
    
    func configureNavigationItems() {
        navigationItem.title = "\(writingStyle.rawValue) \(TextConstants.plan)"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: AppTextConstants.leftBarButtonTitle, style: .plain, target: self, action: #selector(touchUpLeftBarButton))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: AppTextConstants.rightBarButtonTitle, style: .done, target: self, action: #selector(touchUpRightBarButton))
    }
    
    func configure() {
        scheduleTableView.delegate = self
        scheduleTableView.dataSource = self
    }
}

// MARK: - User Interaction
private extension WritingTravelPlanViewController {
    @objc func touchUpRightBarButton() {
        do {
            try viewModel.isValidSave()
            // set title, description이 왜 필요?
            save(viewModel.model.value, planListIndex)
            navigationController?.popViewController(animated: true)
        } catch {
            guard let error = error as? WritingTravelPlanError else { return }
            alertWillAppear(error.rawValue)
        }
    }
    
    func save(_ travelPlan: TravelPlan, _ index: Int?) {
        switch writingStyle {
        case .create:
            Task { try await delegate.create(travelPlan) }
        case .update:
            guard let index = index else { return }
            Task { try await delegate.update(at: index, travelPlan) }
        }
    }
    
    @objc func touchUpLeftBarButton() {
        viewModel.setPlan()
        if viewModel.travelPlanTracker.isChanged {
            let actionSheetText = fetchActionSheetText()
            actionSheetWillApear(actionSheetText.0, actionSheetText.1) { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func touchUpCreateScheduleButton() {
        let model = Schedule(title: "", description: "", coordinate: CLLocationCoordinate2D())
        let viewModel = WritingScheduleViewModel(model)
        let writingView = WritingScheduleViewController(viewModel, writingStyle: writingStyle)
        writingView.delegate = self
        navigationController?.pushViewController(writingView, animated: true)
    }
    
    private func didSelectRow(_ index: Int) {
        let model = viewModel.model.value.schedules[index]
        let viewModel = WritingScheduleViewModel(model)
        let writingView = WritingScheduleViewController(viewModel, writingStyle: writingStyle)
        writingView.delegate = self
        writingView.scheduleListIndex = index
        navigationController?.pushViewController(writingView, animated: true)
    }
    
    // 이전 좌표로 카메라 이동
    @objc func touchUpPreviousButton() {
        mapProvider.animateCameraToPreviousPoint()
    }
    
    // 중심으로 카메라 이동
    @objc func touchUpCenterButton() {
        mapProvider.animateCameraToCenterPoint()
    }
    
    // 다음 좌표로 카메라 이동
    @objc func touchUpNextButton() {
        mapProvider.animateCameraToNextPoint()
    }
    
    @objc func touchUpEditButton() {
        UIView.animate(withDuration: 0.2, delay: 0, animations: { [self] in
            scheduleTableView.isEditing.toggle()
        }, completion: { [self] _ in
            writingTravelPlanView.editScheduleButton.isEditingAtTintColor = scheduleTableView.isEditing
        })
    }
}

// MARK: - Binding
private extension WritingTravelPlanViewController {
    func setBindings() {
        bindingModel()
        bindingText()
    }
    
    func bindingModel() {
        viewModel.model
            .receive(on: RunLoop.main)
            .map { $0.schedules }
            .sink { [self] schedules in
                reload()
                modelDidChaged(schedules)
            }
            .store(in: &subscriptions)
    }
    
    func bindingText() {
        let input = ConcreteWritingTravelPlanViewModel.TextInput(
            titlePublisher: writingTravelPlanView.titleTextField
                .publisher(for: \.text)
                .compactMap { $0 }
                .eraseToAnyPublisher(),
            descriptionPublisher: writingTravelPlanView.descriptionTextView
                .publisher(for: \.text)
                .eraseToAnyPublisher()
        )
        
        viewModel.subscribeText(input: input)
    }
    
    func modelDidChaged(_ schedules: [Schedule]) {
        let coordinates = extractCoordinatesOfSchedules(schedules)
        
        if coordinates.count == .zero {
            removeMapContentsView()
            updateScrollViewContainerHeight()
        } else {
            updateMapView(coordinates)
        }
    }
    
    func extractCoordinatesOfSchedules(_ schedules: [Schedule]) -> [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D]()
        
        for schedule in schedules {
            coordinates.append(schedule.coordinate)
        }
        
        return coordinates
    }
}

// MARK: - MapView
private extension WritingTravelPlanViewController {
    func embedMapView() {
        mapProvider.configureMapView()
        addChild(mapProvider as! UIViewController)
        (mapProvider as! UIViewController).didMove(toParent: self)
        /*
         좌표 값이 없다면(새로운 TavelPlan 추가를 위한 초기 상태인 경우 or Schedule 추가를 안한 경우)
         불필요한 뷰 추가 없이, 임베드만 하고 종료
         */
        guard viewModel.model.value.schedules.count != .zero else { return }
        addMapContentsViews()
    }
    
    func addMapContentsViews() {
        addMapTitleLabel()
        addMapView()
        addMapButtonSet()
    }
    
    @MainActor func removeMapContentsView() {
        removeMapView()
        removeMapTitleLabel()
        removeMapButtonSet()
    }
    
    @MainActor func addMapTitleLabel() {
        scrollViewContainer.addSubview(mapTitleLabel)
        mapTitleLabel.snp.makeConstraints {
            $0.top.equalTo(scheduleTableView.snp.bottom)
                .offset(AppLayoutConstants.largeSpacing)
            $0.leading.equalToSuperview()
                .inset(AppLayoutConstants.spacing)
        }
    }
    
    @MainActor func addMapView() {
        scrollViewContainer.addSubview(mapProvider.mapView)
        mapProvider.mapView.snp.makeConstraints {
            $0.top.equalTo(mapTitleLabel.snp.bottom)
                .offset(AppLayoutConstants.spacing)
            $0.width.equalTo(scrollViewContainer.snp.width)
            $0.height.equalTo(AppLayoutConstants.mapViewHeight)
        }
    }
    
    @MainActor func addMapButtonSet() {
        mapButtonSetView.previousButton.addTarget(self, action: #selector(touchUpPreviousButton), for: .touchUpInside)
        mapButtonSetView.centerButton.addTarget(self, action: #selector(touchUpCenterButton), for: .touchUpInside)
        mapButtonSetView.nextButton.addTarget(self, action: #selector(touchUpNextButton), for: .touchUpInside)
        scrollViewContainer.addSubview(mapButtonSetView)
        mapButtonSetView.snp.makeConstraints {
            $0.top.equalTo(mapProvider.mapView.snp.bottom)
                .offset(AppLayoutConstants.spacing)
            $0.width.equalTo(scrollViewContainer.snp.width)
            $0.height.equalTo(AppLayoutConstants.buttonHeight)
        }
    }
    
    func removeMapView() {
        mapProvider.mapView.snp.removeConstraints()
        mapProvider.mapView.removeFromSuperview()
    }
    
    func removeMapTitleLabel() {
        mapTitleLabel.snp.removeConstraints()
        mapTitleLabel.removeFromSuperview()
    }
    
    func removeMapButtonSet() {
        mapButtonSetView.previousButton.removeTarget(self, action: #selector(touchUpPreviousButton), for: .touchUpInside)
        mapButtonSetView.centerButton.removeTarget(self, action: #selector(touchUpCenterButton), for: .touchUpInside)
        mapButtonSetView.nextButton.removeTarget(self, action: #selector(touchUpNextButton), for: .touchUpInside)
        mapButtonSetView.snp.removeConstraints()
        mapButtonSetView.removeFromSuperview()
    }
    
    // Map 관련 뷰가 subview에 있는지(+ 레이아웃 제약이 설정되어 있는지) 확인하는 메서드
    func mapContentsIsAdded() -> Bool {
        scrollViewContainer.subviews.contains {
            guard let label = $0.accessibilityLabel else { return false }
            return label == AppTextConstants.mapViewAccessibilityLabel
        }
    }
    
    func updateMapView(_ coordinates: [CLLocationCoordinate2D]) {
        // Map 관련 뷰가 없다면, ScrollView 높이를 갱신하고, Map 관련 뷰 추가
        if !mapContentsIsAdded() {
            updateScrollViewContainerHeight()
            addMapContentsViews()
        }
        mapProvider.updateMapView(coordinates)
    }
    
    @MainActor func reload() {
        updateScrollViewContainerHeight()
        updateTableViewConstraints()
        scheduleTableView.reloadData()
    }
    
    @MainActor func updateScrollViewContainerHeight() {
        scrollViewContainer.snp.updateConstraints {
            $0.height.equalTo(viewModel.scrollViewContainerheight)
        }
    }
    
    @MainActor func updateTableViewConstraints() {
        scheduleTableView.snp.updateConstraints {
            $0.height.equalTo(viewModel.model.value.schedules.count * Int(AppLayoutConstants.cellHeight))
        }
    }
}

// MARK: - Schedule TableView
extension WritingTravelPlanViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TravelPlanTableViewCell.identifier, for: indexPath) as? TravelPlanTableViewCell else { return UITableViewCell() }
        cell.titleLabel.text = viewModel.model.value.schedules[indexPath.row].title
        cell.descriptionLabel.text = viewModel.model.value.schedules[indexPath.row].description
        cell.dateLabel.text = viewModel.model.value.schedules[indexPath.row].date
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.model.value.schedules.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        AppLayoutConstants.cellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRow(indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            removeSchedule(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            updateTableViewConstraints()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        viewModel.swapSchedules(at: sourceIndexPath.row, to: destinationIndexPath.row)
    }
    
    private func removeSchedule(at index: Int) {
        viewModel.removeSchedule(at: index)
    }
}

extension WritingTravelPlanViewController: ScheduleTransferDelegate {
    func create(_ schedule: Schedule) {
        viewModel.createSchedule(schedule)
    }
    
    func update(at index: Int, _ schedule: Schedule) {
        viewModel.updateSchedule(at: index, schedule)
    }
}

private enum LayoutConstants {
    static let tableViewCornerRadius: CGFloat = 10
}

private enum TextConstants {
    static let plan = "Plan"
    static let map = "Map"
}
