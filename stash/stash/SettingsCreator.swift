//
//  SettingsCreator.swift
//  stash
//
//  Created by James Stidard on 17/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import CoreData

extension Settings
{
    class func createSettings(#touchID: Bool, context: NSManagedObjectContext) -> Settings?
    {
        var settings: Settings?
        
        context.performBlockAndWait
            {
                settings = NSEntityDescription.insertNewObjectForEntityForName("Settings", inManagedObjectContext: context) as? Settings
                
                settings?.touchIDEnabled = touchID
        }
        
        return settings
    }
}

