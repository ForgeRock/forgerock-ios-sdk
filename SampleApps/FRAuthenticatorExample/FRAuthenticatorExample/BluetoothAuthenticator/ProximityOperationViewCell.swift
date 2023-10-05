import UIKit

protocol ProximityOperationCellDelegate: AnyObject {
    func didPressApproveButton(proximityOperation: ProximityOperation)
    func didPressCancelButton(proximityOperation: ProximityOperation)
}
class ProximityOperationViewCell: UITableViewCell {
        
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var errorLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var approveButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    
    var proximityOperation: ProximityOperation? = nil
    
    var delegate: ProximityOperationCellDelegate? = nil
        
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        errorLabel.isHidden = true
    }
    
    @IBAction func didPressApprove() {
        guard let proximityOperation = proximityOperation else { return }
        delegate?.didPressApproveButton(proximityOperation: proximityOperation)
    }
    
    @IBAction func didPressCancel() {
        guard let proximityOperation = proximityOperation else { return }
        delegate?.didPressCancelButton(proximityOperation: proximityOperation)
    }
}
