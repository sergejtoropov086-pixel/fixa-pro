import UIKit
import CoreData

class MainViewController: UIViewController {
    
    private var tableView = UITableView()
    private var statsLabel = UILabel()
    private var searchBar = UISearchBar()
    
    private var appliances: [Appliance] = []
    private var filteredAppliances: [Appliance] = []
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private var isSearching = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    private func setupUI() {
        title = "Fixa Pro Premium"
        view.backgroundColor = .systemBackground
        
        // Search Bar
        searchBar.placeholder = "Поиск по моделям, брендам..."
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        // Stats Label
        statsLabel.textAlignment = .center
        statsLabel.font = .systemFont(ofSize: 14)
        statsLabel.textColor = .secondaryLabel
        statsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statsLabel)
        
        // Table View
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Add Button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTapped)
        )
        
        // Layout
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            statsLabel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 10),
            statsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: statsLabel.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc private func addTapped() {
        let alert = UIAlertController(title: "Добавить технику", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Модель (Bosch WAT28440)" }
        alert.addTextField { $0.placeholder = "Бренд (Bosch, Indesit, Atlant)" }
        alert.addTextField { $0.placeholder = "Тип (стиралка, холодильник)" }
        
        let action = UIAlertAction(title: "Статус запчасти", style: .default) { _ in
            let sheet = UIAlertController(title: "Статус", message: nil, preferredStyle: .actionSheet)
            ["В наличии", "Ожидается", "Куплено"].forEach { status in
                sheet.addAction(UIAlertAction(title: status, style: .default) { _ in
                    self.saveAppliance(
                        name: alert.textFields?[0].text ?? "",
                        brand: alert.textFields?[1].text ?? "—",
                        type: alert.textFields?[2].text ?? "—",
                        partStatus: status
                    )
                })
            }
            sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            self.present(sheet, animated: true)
        }
        alert.addAction(action)
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    private func saveAppliance(name: String, brand: String, type: String, partStatus: String) {
        guard !name.isEmpty else { return }
        let appliance = Appliance(context: context)
        appliance.name = name
        appliance.brand = brand
        appliance.type = type
        appliance.partStatus = partStatus
        try? context.save()
        loadData()
    }
    
    private func loadData() {
        let request: NSFetchRequest<Appliance> = Appliance.fetchRequest()
        do {
            appliances = try context.fetch(request)
            filteredAppliances = appliances
            tableView.reloadData()
            updateStats()
        } catch { print("Load error") }
    }
    
    private func updateStats() {
        let total = appliances.count
        let withParts = appliances.filter { $0.partStatus != "—" }.count
        statsLabel.text = "Техника: \(total) | Запчасти: \(withParts)"
    }
}

// MARK: - UITableViewDataSource
extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (isSearching ? filteredAppliances : appliances).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let app = (isSearching ? filteredAppliances : appliances)[indexPath.row]
        cell.textLabel?.text = app.name
        cell.detailTextLabel?.text = "\(app.brand) — \(app.partStatus)"
        cell.imageView?.image = app.photoData.flatMap { UIImage(data: $0) }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let exportAction = UIContextualAction(style: .normal, title: "Экспорт") { _, _, _ in
            // Здесь можно добавить экспорт одной записи
        }
        exportAction.backgroundColor = .systemBlue
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _, _, _ in
            let app = (self?.isSearching == true ? self!.filteredAppliances : self!.appliances)[indexPath.row]
            self?.context.delete(app)
            try? self?.context.save()
            self?.loadData()
        }
        return UISwipeActionsConfiguration(actions: [deleteAction, exportAction])
    }
}

// MARK: - UISearchBarDelegate
extension MainViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearching = false
        } else {
            isSearching = true
            filteredAppliances = appliances.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.brand.localizedCaseInsensitiveContains(searchText) ||
                $0.type.localizedCaseInsensitiveContains(searchText)
            }
        }
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
        searchBar.text = ""
        tableView.reloadData()
    }
}
