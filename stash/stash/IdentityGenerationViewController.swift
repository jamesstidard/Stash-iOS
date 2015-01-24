//
//  IdentityGenerationViewController.swift
//  stash
//
//  Created by James Stidard on 24/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import UIKit

class IdentityGenerationViewController: UIViewController {
    
    let entropyMachine = EntropyMachine()
    lazy var harvesters: [EntropyHarvester]                 = [self.gyroHarvester, self.accelerometerHarvester]
    lazy var gyroHarvester: GyroHarvester                   = GyroHarvester(machine: self.entropyMachine)
    lazy var accelerometerHarvester: AccelerometerHarvester = AccelerometerHarvester(machine: self.entropyMachine)
    
    @IBOutlet weak var nameTextField: UITextField!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.entropyMachine.start()
        self.harvesters.map({$0.start()}) // start harvesters gathering entropy for the machine
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func continueButtonPressed(sender: UIButton) {
        // Stop the harvester and get the seed
        self.harvesters.map({$0.stop()})
        if let seed = self.entropyMachine.stop() {
            if let context = Stash.sharedInstance.context {
                let newIdentity = Identity.createIdentity(nameTextField.text, seed: seed, context: context)
                println("name: \(newIdentity?.name)")
                println("ILK: \(newIdentity?.lockKey)")
                println("IUK: \(newIdentity?.unlockKey)")
                
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
