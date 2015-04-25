//
//  IdentityGenerationViewController.swift
//  stash
//
//  Created by James Stidard on 24/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import UIKit
import CoreData
import LocalAuthentication

class IdentityGenerationViewController: UIViewController, ContextDriven {
    
    static let SegueID = "IdentityCreationSegue"
    
    @IBOutlet weak var navigationCancelButton: UIBarButtonItem!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var passwordConfimationField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var touchIDLabel: UILabel!
    @IBOutlet weak var touchIDSwitch: UISwitch!
    @IBOutlet weak var continueButton: UIButton!
    
    var context: NSManagedObjectContext?
    var entropyMachine                              = EntropyMachine()
    lazy var harvesters: [EntropyHarvester]         = [self.gyroHarvester, self.accelHarvester]
    lazy var gyroHarvester: GyroHarvester           = GyroHarvester(machine: self.entropyMachine)
    lazy var accelHarvester: AccelerometerHarvester = AccelerometerHarvester(machine: self.entropyMachine)
    lazy var progressHud: MBProgressHUD             = MBProgressHUD()
    
    private lazy var touchIDAvalible: Bool = {
        return LAContext().canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: nil)
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start harvesting entropy to seed new identity
        self.startHarvesting()
        
        // Disable or enable touchID settings depending on if it's avalible on the device
        self.touchIDLabel.enabled  = self.touchIDAvalible
        self.touchIDSwitch.enabled = self.touchIDAvalible
        
        // Bool signal indicating if the name field value is valid
        let validName = self.nameField.rac_textSignal()
            .map { return count($0 as! String) > 0 }
        
        // Bool signal indicating if the password fields are valid
        let validPasswords =
            RACSignal.combineLatest([self.passwordField.rac_textSignal(), self.passwordConfimationField.rac_textSignal()])
                .map {
                    let passwords = ($0 as! RACTuple).allObjects() as! [String]
                    return count(passwords[0]) > 0 && passwords[0] == passwords[1]
                }
        
        // change background colour of fields to display is they are valid
        validName
            .map { return ($0 as! Bool) ? UIColor.whiteColor() : UIColor.softRed() }
            .subscribeNext { self.nameField.backgroundColor = ($0 as! UIColor) }
        
        self.passwordField.rac_textSignal()
            .map { return count($0 as! String) > 0 }
            .map { return ($0 as! Bool) ? UIColor.whiteColor() : UIColor.softRed() }
            .subscribeNext { self.passwordField.backgroundColor = ($0 as! UIColor) }
        
        validPasswords
            .map { return ($0 as! Bool) ? UIColor.whiteColor() : UIColor.softRed() }
            .subscribeNext { self.passwordConfimationField.backgroundColor = ($0 as! UIColor) }
        
        // Signal indicating the entire form is valid
        let validForm = RACSignal.combineLatest([validName, validPasswords])
            .map {
                let bools = ($0 as! RACTuple).allObjects() as! [Bool]
                return bools.reduce(true, combine: { (sum, current) -> Bool in
                    return sum && current
                })
        }
        
        // A command that can only be executed when the form is valid. On execution it gets a Identity creation signal that tracks the identities creation
        let createIdentity = RACCommand(enabled: validForm) { (seed) -> RACSignal! in
            let name     = self.nameField.text as String
            var password = self.passwordField.text as String
            var seed     = seed as! NSData
            let touchID  = (self.touchIDAvalible) ? self.touchIDSwitch.on : false
            
            return Identity.createIdentitySignal(
                name,
                password: &password,
                seed: &seed,
                context: self.context!).materialize().deliverOn(RACScheduler.mainThreadScheduler())
            // Materialize so we can get the error (otherwise cached by command) and deliever on the main thread
        }
        
        // When a command is exicuted the signal it dynmically creates (above) can be grabed here.
        // Once grabed we can subscribe to it's results
        createIdentity.executionSignals.subscribeNext {
            let createIdentityReponse = $0 as! RACSignal
            
            createIdentityReponse.dematerialize().subscribeNext({
                let tuple = ($0 as! RACTuple)
                self.performSegueWithIdentifier(RescueCodeViewController.SegueID, sender: tuple)
            }, error: { _ in
                self.progressHud.hide(
                    animated: true,
                    labelText: "Failed",
                    detailsText: "Identity with name already exists",
                    success: false,
                    delay: 4)
            }, completed: { _ in
                self.progressHud.hide(false)
            })
        }
        
        // Bind continue button press to starting the identity creation command and informs the user while it executes
        self.continueButton.rac_signalForControlEvents(.TouchUpInside)
            .subscribeNext { _ in
                self.progressHud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                
                // If we have a valid seed to generate an identity with
                if let seed = self.stopHarvesting() {
                    self.progressHud.labelText        = "Creating Identity"
                    self.progressHud.detailsLabelText = "This will take a few moments"
                    self.resignFirstResponder()
                    
                    createIdentity.execute(seed)
                }
                // else: tell you user and start the entropy machine again
                else {
                    self.progressHud.hide(
                        animated: true,
                        labelText: "Error",
                        detailsText: "Couldn't generate random seed",
                        success: false,
                        delay: 4)
                    
                    self.startHarvesting()
                }
                
            }
        
        // Enable / disable continue button based on form validity and if an identity is currently being created
        RACSignal.combineLatest([validForm, createIdentity.executing])
            .map {
                let bools                         = ($0 as! RACTuple).allObjects() as! [Bool]
                let (validForm, creatingIdentity) = (bools[0], bools[1])
                return validForm && !creatingIdentity && self.context != nil
            }.subscribeNext {
                self.continueButton.enabled = $0 as! Bool
            }
        
        // Enable or disable UI elements if an Identity is being created
        createIdentity.executing.not()
            .subscribeNext {
                let notExecuting                      = $0 as! Bool
                self.nameField.enabled                = notExecuting
                self.passwordField.enabled            = notExecuting
                self.passwordConfimationField.enabled = notExecuting
                self.navigationCancelButton.enabled   = notExecuting
                self.touchIDSwitch.enabled            = notExecuting && self.touchIDAvalible
                self.touchIDLabel.enabled             = notExecuting && self.touchIDAvalible
            }
    }
    
    private func startHarvesting() {
        self.activityIndicator.startAnimating()
        self.entropyMachine.start()
        self.harvesters.map({$0.start()}) // start harvesters gathering entropy for the machine
    }
    
    private func stopHarvesting() -> NSData? {
        self.activityIndicator.stopAnimating()
        self.harvesters.map({$0.stop()})
        return self.entropyMachine.stop()
    }
    
    @IBAction func cancelButtonPressed(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let
            destinationVC = segue.destinationViewController as? RescueCodeViewController,
            tuple         = sender as? RACTuple,
            identity      = tuple[0] as? Identity,
            rescueCode    = tuple[1] as? String
        {
            destinationVC.identity   = identity
            destinationVC.rescueCode = rescueCode
        }
    }
}
