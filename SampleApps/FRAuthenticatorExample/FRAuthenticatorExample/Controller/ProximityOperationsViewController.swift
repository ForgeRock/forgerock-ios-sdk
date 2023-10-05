import UIKit
import AuthenticatorBluetooth

class ProximityOperationsViewController: UIViewController {
            
    @IBOutlet weak var tableView: UITableView!
    
    var proximiyOperations: [ProximityOperation] = []
    
    private var proximityManager: ProximityManager = ProximiyManagerImpl.shared
    
    let proximityOperationCellIdentifier = "ProximityOperationCell"
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "ProximityOperationViewCell", bundle: nil), forCellReuseIdentifier: proximityOperationCellIdentifier)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        proximityManager.addDelegate(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        proximityManager.removeDelegate(self)
    }
    
    func approveAuth() {
        proximityManager.approveAuth()
    }
    
    func denyAuth() {
        proximityManager.denyAuth()
    }
    
}

// MARK: - TableView delgate and datasource

extension ProximityOperationsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = proximiyOperations.count
        
        if (count == 0) {
            dismiss(animated: true, completion: nil)
        }
        
        return proximiyOperations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: proximityOperationCellIdentifier, for: indexPath) as? ProximityOperationViewCell {
            let proximityOperation = proximiyOperations[indexPath.row]
            cell.messageLabel.text = proximityOperation.message
            cell.statusLabel.text = String(describing: proximityOperation.state)
            cell.errorLabel.isHidden = proximityOperation.state != .failed
            cell.proximityOperation = proximityOperation
            cell.delegate = self
            return cell
        }
        return UITableViewCell()
    }
    
}

// MARK: - Proximity Manager delgate

extension ProximityOperationsViewController: ProximityManagerDelegate {
    func onProximityOperationsUpdate(_ proximityManager: ProximityManager, proximityOperations: [ProximityOperation]) {
        self.proximiyOperations = proximityOperations
        tableView.reloadData()
    }
}

// MARK: - Proximity Operation View delgate

extension ProximityOperationsViewController: ProximityOperationCellDelegate {
    
    func didPressApproveButton(proximityOperation: ProximityOperation) {
        approveAuth()
    }
    
    func didPressCancelButton(proximityOperation: ProximityOperation) {
        denyAuth()
    }
    
}
