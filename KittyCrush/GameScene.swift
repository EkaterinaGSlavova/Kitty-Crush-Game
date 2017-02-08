//
//  GameScene.swift
//  KittyCrush
//
//  Created by Ekaterina on 2/12/16.
//  Copyright (c) 2016 Ekaterina. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    var level: Level! {
        didSet {
            removeTiles()
            removeBars()
            addTiles()
        }
    }
    var swipeHandler: ((Swap) -> ())?
    
    let TileWidth: CGFloat = 32.0
    let TileHeight: CGFloat = 36.0
    
    let gameLayer = SKNode()
    let kittiesLayer = SKNode()
    let tilesLayer = SKNode()
    let barsLayer = SKNode()
    let surprisedKitty = SKSpriteNode(imageNamed: "surprisedCat")
    let comboKitty = SKSpriteNode(imageNamed: "comboCat")
    
    let cropLayer = SKCropNode()
    let maskLayer = SKNode()
    
    var swipeFromColumn: Int?
    var swipeFromRow: Int?
    
    // Sprite that is drawn on top of the kitty that the player is trying to swap
    var selectionSprite = SKSpriteNode()
    
    // Pre-load the sounds
    let swapSound = SKAction.playSoundFileNamed("Chomp.wav", waitForCompletion: false)
    let invalidSwapSound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
    let matchSound = SKAction.playSoundFileNamed("meow.wav", waitForCompletion:false)
    let fallingKittySound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion:false)
    let addKittySound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion:false)
    let surprisedKittySound = SKAction.playSoundFileNamed("Nope.mp3", waitForCompletion: false)
    let comboKittySound = SKAction.playSoundFileNamed("Wohoo.mp3", waitForCompletion: false)

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not used in this app")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let background = SKSpriteNode(imageNamed: "Yarn")
        background.size = size
        addChild(background)
        addChild(gameLayer)
        gameLayer.isHidden = true
        
        let layerPosition = CGPoint(x: -TileWidth * CGFloat(NumColumns) / 2, y: -TileHeight * CGFloat(NumRows) / 2)
        surprisedKitty.anchorPoint = CGPoint(x:0.0, y:0.0)
        comboKitty.anchorPoint = CGPoint(x:0.0, y:0.0)
        surprisedKitty.position = CGPoint(x: size.width/2, y: -size.height/2 + 200)
        comboKitty.position = CGPoint(x: size.width/2, y: -size.height/2 + 100)
    
        addChild(surprisedKitty)
        addChild(comboKitty)
        
        tilesLayer.position = layerPosition
        gameLayer.addChild(tilesLayer)
        
        gameLayer.addChild(cropLayer)
        maskLayer.position = layerPosition
        cropLayer.maskNode = maskLayer
        
        kittiesLayer.position = layerPosition
        //gameLayer.addChild(kittiesLayer)
        cropLayer.addChild(kittiesLayer)
        
        barsLayer.position = layerPosition
        gameLayer.addChild(barsLayer)
        
        swipeFromColumn = nil
        swipeFromRow = nil
    }
    
    func animateComboKitty() {
        comboKitty.run(SKAction.sequence([
            SKAction.rotate(toAngle: CGFloat(M_PI/3), duration: 0.3),
            SKAction.wait(forDuration: 0.3),
            SKAction.rotate(toAngle: 0, duration: 0.3)
            ]))
        run(comboKittySound)
    }
    func animateSurprisedKitty()  {
        surprisedKitty.run(SKAction.sequence([
            SKAction.rotate(toAngle: CGFloat(M_PI/3), duration: 0.3),
            SKAction.wait(forDuration: 0.3),
            SKAction.rotate(toAngle: 0, duration: 0.3)
        ]))
        run(surprisedKittySound)
    }
    // Add the sprites to the screen
    func addSpritesForKitties(_ kitties: Set<Kitty>) {
        
        for kitty in kitties {
            // Create a new sprite for the kitty and add it to the kittyLayer
            let sprite = SKSpriteNode(imageNamed: kitty.kittyType.spriteName)
            sprite.position = pointForColumn(kitty.column, row:kitty.row)
            kittiesLayer.addChild(sprite)
            kitty.sprite = sprite
            
            // Give each kitty sprite a small, random delay, then fade them in
            sprite.alpha = 0
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            
            sprite.run(
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.25, withRange: 0.5),
                    SKAction.group([
                        SKAction.fadeIn(withDuration: 0.25),
                        SKAction.scale(to: 1.0, duration: 0.25)
                        ])
                    ]))
        }
    }
    
    func addTiles() {
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if let _ = level.tileAtColumn(column, row: row) {
                    //let tileNode = SKSpriteNode(imageNamed: "Tile")
                    let tileNode = SKSpriteNode(imageNamed: "Tile")
                    
                    tileNode.position = pointForColumn(column, row: row)
                    //tilesLayer.addChild(tileNode)
                    maskLayer.addChild(tileNode)
                }
                
                if let bars = level.barsAtColumn(column, row: row) {
                    let barNode = SKSpriteNode(imageNamed: "Bar")
                    barNode.position = pointForColumn(column, row: row)
                    bars.sprite = barNode
                    barsLayer.addChild(barNode)
                }
            }
        }
        for row in 0...NumRows {
            for column in 0...NumColumns {
                let topLeft     = (column > 0) && (row < NumRows)
                    && level.tileAtColumn(column - 1, row: row) != nil
                let bottomLeft  = (column > 0) && (row > 0)
                    && level.tileAtColumn(column - 1, row: row - 1) != nil
                let topRight    = (column < NumColumns) && (row < NumRows)
                    && level.tileAtColumn(column, row: row) != nil
                let bottomRight = (column < NumColumns) && (row > 0)
                    && level.tileAtColumn(column, row: row - 1) != nil
                
                // The tiles are named from 0 to 15, according to the bitmask that is
                // made by combining these four values.
                let value = Int(topLeft.hashValue) | Int(topRight.hashValue) << 1 | Int(bottomLeft.hashValue) << 2 | Int(bottomRight.hashValue) << 3
                
                // Values 0 (no tiles), 6 and 9 (two opposite tiles) are not drawn.
                if value != 0 && value != 6 && value != 9 {
                    let name = String(format: "Tile_%ld", value)
                    let tileNode = SKSpriteNode(imageNamed: name)
                    var point = pointForColumn(column, row: row)
                    point.x -= TileWidth/2
                    point.y -= TileHeight/2
                    tileNode.position = point
                    tilesLayer.addChild(tileNode)
                }
            }
        }

    }
    
    func removeTiles() {
        tilesLayer.removeAllChildren()
    }
    func removeBars() {
        barsLayer.removeAllChildren()
    }
    func pointForColumn(_ column: Int, row: Int) -> CGPoint {
        return CGPoint (x: (CGFloat(column) + 0.5)*TileWidth, y: (CGFloat(row) + 0.5)*TileHeight)
    }
    
    // Convert the point to column and row
    func convertPoint(_ point: CGPoint) -> (success: Bool, column: Int, row: Int) {
        if point.x >= 0 && point.x < CGFloat(NumColumns)*TileWidth &&
            point.y >= 0 && point.y < CGFloat(NumRows)*TileHeight {
                return (true, Int(point.x / TileWidth), Int(point.y / TileHeight))
        } else {
            return (false, 0, 0)  // invalid location
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // Convert the touch location to a point relative to the kittiesLayer.
        let touch = touches.first! as UITouch
        let location = touch.location(in: kittiesLayer)
        
        
        let (success, column, row) = convertPoint(location)
        if success {
            
            // The touch must be on a kitty, not on an empty tile
            if let kitty = level.kittyAtColumn(column, row: row) {
                
                // Record the column and row where the swipe started
                swipeFromColumn = column
                swipeFromRow = row
                
                showSelectionIndicatorForKitty(kitty)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if swipeFromColumn == nil { return }
        
        let touch = touches.first! as UITouch
        let location = touch.location(in: kittiesLayer)
        
        let (success, column, row) = convertPoint(location)
        if success {
            
            var horzDelta = 0, vertDelta = 0
            if column < swipeFromColumn! {          // swipe left
                horzDelta = -1
            } else if column > swipeFromColumn! {   // swipe right
                horzDelta = 1
            } else if row < swipeFromRow! {         // swipe down
                vertDelta = -1
            } else if row > swipeFromRow! {         // swipe up
                vertDelta = 1
            }
            
            // Only try swapping when the user swiped into a new square
            if horzDelta != 0 || vertDelta != 0 {
                trySwapHorizontal(horzDelta, vertical: vertDelta)
                hideSelectionIndicator()
                
                // Ignore the rest of this swipe motion from now on
                swipeFromColumn = nil
            }
        }
    }
    
    func trySwapHorizontal(_ horzDelta: Int, vertical vertDelta: Int) {
        let toColumn = swipeFromColumn! + horzDelta
        let toRow = swipeFromRow! + vertDelta
        
        // Check if going outside the bounds of the array. This happens when the user swipes over the edge of the grid. Ignore such swipes
        if toColumn < 0 || toColumn >= NumColumns { return }
        if toRow < 0 || toRow >= NumRows { return }
        
        // Restrict swap if there is no kitty to swap with
        if let toKitty = level.kittyAtColumn(toColumn, row: toRow),
            let fromKitty = level.kittyAtColumn(swipeFromColumn!, row: swipeFromRow!),
            let _ = swipeHandler {
                
                // Communicate this swap request back to the ViewController
                if let handler = swipeHandler {
                    let swap = Swap(kittyA: fromKitty, kittyB: toKitty)
                    handler(swap)
               }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // Remove the selection indicator with a fade-out
        if selectionSprite.parent != nil && swipeFromColumn != nil {
            hideSelectionIndicator()
        }
        
        // If the gesture ended, regardless of whether if was a valid swipe or not, reset the starting column and row numbers
        swipeFromColumn = nil
        swipeFromRow = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    func animateSwap(_ swap: Swap, completion: @escaping () -> ()) {
        let spriteA = swap.kittyA.sprite!
        let spriteB = swap.kittyB.sprite!
        
        // Put the kitty you started with on top.
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let Duration: TimeInterval = 0.3
        
        let moveA = SKAction.move(to: spriteB.position, duration: Duration)
        moveA.timingMode = .easeOut
        spriteA.run(moveA, completion: completion)
        
        let moveB = SKAction.move(to: spriteA.position, duration: Duration)
        moveB.timingMode = .easeOut
        spriteB.run(moveB)
        
        run(swapSound)
    }
    
    func animateInvalidSwap(_ swap: Swap, completion: @escaping () -> ()) {
        let spriteA = swap.kittyA.sprite!
        let spriteB = swap.kittyB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let Duration: TimeInterval = 0.2
        
        let moveA = SKAction.move(to: spriteB.position, duration: Duration)
        moveA.timingMode = .easeOut
        
        let moveB = SKAction.move(to: spriteA.position, duration: Duration)
        moveB.timingMode = .easeOut
        
        spriteA.run(SKAction.sequence([moveA, moveB]), completion: completion)
        spriteB.run(SKAction.sequence([moveB, moveA]))
        
        run(invalidSwapSound)
        animateSurprisedKitty()
    }
    
    // MARK: Selection Indicator

    func showSelectionIndicatorForKitty(_ kitty: Kitty) {
        // If the selection indicator is still visible, then first remove it.
        if selectionSprite.parent != nil {
            selectionSprite.removeFromParent()
        }
        
        if let sprite = kitty.sprite {
            let texture = SKTexture(imageNamed: kitty.kittyType.highlightedSpriteName)
            selectionSprite.size = texture.size()
            selectionSprite.run(SKAction.setTexture(texture))
            
            sprite.addChild(selectionSprite)
            selectionSprite.alpha = 1.0
        }
    }

    func hideSelectionIndicator() {
        selectionSprite.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()]))
    }
    func animateMatchedKitties(_ chains: Set<Chain>, completion: @escaping () -> ()) {
        
        for chain in chains {
            animateScoreForChains(chain)
            for kitty in chain.kitties {
                if let sprite = kitty.sprite {
                    if sprite.action(forKey: "removing") == nil {
                        let scaleAction = SKAction.scale(to: 0.1, duration: 0.3)
                        scaleAction.timingMode = .easeOut
                        sprite.run(SKAction.sequence([scaleAction, SKAction.removeFromParent()]), withKey: "removing")
                        run(matchSound)
                    }
                }
            }
        }
        
        run(SKAction.wait(forDuration: 0.3), completion: completion)
    }
    
    func animateFallingKitties(_ colums: [[Kitty]], completion: @escaping () -> ()) {
        var longestDuration: TimeInterval = 0
        for array in colums {
            for (idx, kitty) in array.enumerated(){
                let newPosition = pointForColumn(kitty.column, row: kitty.row)
                let delay = 0.5 + 0.15*TimeInterval(idx)
                let sprite = kitty.sprite!
                let duration = TimeInterval(((sprite.position.y - newPosition.y) / TileHeight) * 0.1)
                longestDuration = max(longestDuration, duration + delay)
                
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                sprite.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.group([moveAction, fallingKittySound])]))
                
            }
        }
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
    
    func animateNewKitties(_ columns: [[Kitty]], completion: @escaping () -> ()) {
        
        var longestDuration: TimeInterval = 0
        
        for array in columns {
            let startRow = array[0].row + 1
            
            for (idx, kitty) in array.enumerated() {
                let sprite = SKSpriteNode(imageNamed: kitty.kittyType.spriteName)
                sprite.position = pointForColumn(kitty.column, row: startRow)
                kittiesLayer.addChild(sprite)
                kitty.sprite = sprite
                
                let delay = 0.1 + 0.2 * TimeInterval(array.count - idx - 1)
                let duration = TimeInterval(startRow - kitty.row) * 0.1
                longestDuration = max(longestDuration, duration + delay)
                
                let newPosition = pointForColumn(kitty.column, row: kitty.row)
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                sprite.alpha = 0
                sprite.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.group([SKAction.fadeIn(withDuration: 0.05), moveAction, addKittySound])]))
            }
        }
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
    
    func animateScoreForChains(_ chain: Chain) {
        
        // Figure out what the midpoint of the chain is
        let firstSprite = chain.firstKitty().sprite!
        let lastSprite = chain.lastKitty().sprite!
        let centerPosition = CGPoint(x:(firstSprite.position.x + lastSprite.position.x) / 2, y: (firstSprite.position.y + lastSprite.position.y) / 2 - 8)
        
        // Add a label for the score that floats up
        
        let scoreLabel = SKLabelNode(fontNamed: "GillSans-BoldItalic")
        scoreLabel.fontSize = 16
        scoreLabel.text = String(format: "%ld", chain.score)
        scoreLabel.position = centerPosition
        scoreLabel.zPosition = 300
        kittiesLayer.addChild(scoreLabel)
        
        let moveAction = SKAction.move(by: CGVector(dx: 0, dy: 3), duration: 0.7)
        moveAction.timingMode = .easeOut
        scoreLabel.run(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
    }
    
    func animateGameOver(_ completion: @escaping () -> ()) {
        let action = SKAction.move(by: CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .easeIn
        gameLayer.run(action, completion: completion)
    }
    
    func animateBeginGame(_ completion: @escaping () -> ()) {
        gameLayer.isHidden = false
        gameLayer.position = CGPoint(x: 0, y: size.height)
        let action = SKAction.move(by: CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .easeOut
        gameLayer.run(action, completion: completion)
    }
    func removeAllKittySprites() {
        kittiesLayer.removeAllChildren()
    }
    
}

