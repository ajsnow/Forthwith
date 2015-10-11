//
//  LifeView.swift
//  Forthwith
//
//  Created by Andrew Snow on 10/10/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation
import Forthwith

public class LifeView: NSView {
    
    let aliveColor = NSColor(red: 0.33, green: 0.83, blue: 1, alpha: 1) // A pretty, light blue.
    
    public override func drawRect(dirtyRect: NSRect) {
//        NSBezierPath.fillRect(dirtyRect)
        aliveColor.set()
        drawLife(dirtyRect)
    }
    
    func drawLife(rect: NSRect) {
        let s = Stack<Cell>()
        let path = NSBezierPath()
        
        let critSizeX = self.bounds.width / CGFloat(width)
        let critSizeY = self.bounds.height / CGFloat(height)
        
        func createRect() -> CGRect { return CGRect(x: CGFloat(x) * critSizeX, y: CGFloat(y) * critSizeY, width: critSizeX, height: critSizeY) }
        
        let drawLivingCritter = { $0 .. path .. createRect .. NSBezierPath.appendBezierPathWithOvalInRect }
        let drawCritter = { $0 .. getCritter .. Critter.Alive .. critterEq .. `if`(drawLivingCritter) }
        let drawWorld = { $0 .. tick(doNothing) .. tick(drawCritter) .. uponWorld }
        
        s .. drawWorld .. path .. NSBezierPath.fill
    }
}