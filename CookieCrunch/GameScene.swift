//
//  GameScene.swift
//  CookieCrunch
//
//  Created by Jeremiah on 4/2/16.
//  Copyright (c) 2016 Jeremiah. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    var swipeHandler: ((Swap) -> ())?
    
    var level: Level!
    let tileWidth: CGFloat = 32.0
    let tileHeight: CGFloat = 36.0
    
    let gameLayer = SKNode()
    let cookiesLayer = SKNode()
    let tilesLayer = SKNode()
    let cropLayer = SKCropNode()
    let maskLayer = SKNode()
    
    var swipeFromColumn: Int?
    var swipeFromRow: Int?
    
    var selectionSprite = SKSpriteNode()

    let swapSound = SKAction.playSoundFileNamed("Chomp.wav", waitForCompletion: false)
    let invalidSwapSound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
    let matchSound = SKAction.playSoundFileNamed("Ka-Ching.wav", waitForCompletion: false)
    let fallingCookieSound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
    let addCookieSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) not used in this app")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        anchorPoint = CGPointMake(0.5, 0.5)
        
        let background = SKSpriteNode(imageNamed: "Background")
        addChild(background)
        
        gameLayer.hidden = true
        addChild(gameLayer)
        
        let layerPosition = CGPoint(
            x: -tileWidth * CGFloat(NumColumns) / 2.0,
            y: -tileHeight * CGFloat(NumRows) / 2.0
        )
        
        tilesLayer.position = layerPosition
        gameLayer.addChild(tilesLayer)
        
        cookiesLayer.position = layerPosition
        cropLayer.addChild(cookiesLayer)
        
        
        gameLayer.addChild(cropLayer)
        maskLayer.position = layerPosition
        cropLayer.maskNode = maskLayer
        
        swipeFromColumn = nil
        swipeFromRow = nil
        
        _ = SKLabelNode(fontNamed: "GillSans-BoldItalic")
    }
    
    func pointForColumn(column: Int, row: Int) -> CGPoint {
        return CGPoint(
            x: CGFloat(column) * tileWidth + tileWidth / 2,
            y: CGFloat(row) * tileHeight + tileHeight / 2
        )
    }
    
    func addSpritesForCookies(cookies: Set<Cookie>) {
        for cookie in cookies {
            let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
            sprite.position = pointForColumn(cookie.column, row: cookie.row)
            cookiesLayer.addChild(sprite)
            cookie.sprite = sprite

            sprite.alpha = 0
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            
            sprite.runAction(SKAction.sequence([SKAction.waitForDuration(0.25, withRange: 0.5), SKAction.group([SKAction.fadeInWithDuration(0.25), SKAction.scaleTo(1.0, duration: 0.25)])]))
        }
    }
    
    func addTiles() {
        maskLayer.removeAllChildren()
        tilesLayer.removeAllChildren()
        
        for row in 0 ..< NumRows {
            for column in 0 ..< NumColumns {
                if level.tileAtColumn(column, row: row) != nil {
                    let tileNode = SKSpriteNode(imageNamed: "MaskTile")
                    tileNode.position = pointForColumn(column, row: row)
                    maskLayer.addChild(tileNode)
                }
            }
        }
        
        for row in 0 ... NumRows {
            for column in 0 ... NumColumns {
                let topLeft = (column > 0) && (row < NumRows) && level.tileAtColumn(column - 1, row: row) != nil
                let bottomLeft = (column > 0) && (row > 0) && level.tileAtColumn(column - 1, row: row - 1) != nil
                let topRight = (column < NumColumns) && (row < NumRows) && level.tileAtColumn(column, row: row) != nil
                let bottomRight = (column < NumColumns) && (row > 0) && level.tileAtColumn(column, row: row - 1) != nil
                
                let value = Int(topLeft) | Int(topRight) << 1 | Int(bottomLeft) << 2 | Int(bottomRight) << 3
                
                if value != 0 && value != 6 && value != 9 {
                    let name = String(format: "Tile_%ld", value)
                    let tileNode = SKSpriteNode(imageNamed: name)
                    var point = pointForColumn(column, row: row)
                    point.x -= tileWidth / 2
                    point.y -= tileHeight / 2
                    tileNode.position = point
                    tilesLayer.addChild(tileNode)
                }
            }
        }
    }
    
    func convertPoint(point: CGPoint) -> (success: Bool, column: Int, row: Int) {
        if point.x >= 0 && point.x < CGFloat(NumColumns) * tileWidth && point.y >= 0 && point.y < CGFloat(NumRows) * tileHeight {
            return (true, Int(point.x / tileWidth), Int(point.y / tileHeight))
        }
        else {
            return (false, 0, 0)
        }
    }
    
    func trySwapHorizontal(horizontal horzDelta: Int, vertical vertDelta: Int) {
        let toColumn = swipeFromColumn! + horzDelta
        let toRow = swipeFromRow! + vertDelta
        
        if toColumn < 0 || toColumn >= NumColumns || toRow < 0 || toRow >= NumRows {
            return
        }
        
        if let toCookie = level.cookieAtColumn(toColumn, row: toRow) {
            if let fromCookie = level.cookieAtColumn(swipeFromColumn!, row: swipeFromRow!) {
                if let handler = swipeHandler {
                    let swap = Swap(CookieA: fromCookie, CookieB: toCookie)
                    handler(swap)
                }
            }
        }
    }
    
    func animateSwap(swap: Swap, completion: () -> ()) {
        let spriteA = swap.CookieA.sprite!
        let spriteB = swap.CookieB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let duration: NSTimeInterval = 0.3
        
        let moveA = SKAction.moveTo(spriteB.position, duration: duration)
        moveA.timingMode = .EaseOut
        spriteA.runAction(moveA, completion: completion)
        
        let moveB = SKAction.moveTo(spriteA.position, duration: duration)
        moveB.timingMode = .EaseOut
        spriteB.runAction(moveB)
        
        runAction(swapSound)
    }
    
    func animateInvalidSwap(swap: Swap, completion: () -> ()) {
        let spriteA = swap.CookieA.sprite!
        let spriteB = swap.CookieB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let duration: NSTimeInterval = 0.2
        
        let moveA = SKAction.moveTo(spriteB.position, duration: duration)
        moveA.timingMode = .EaseOut
        
        let moveB = SKAction.moveTo(spriteA.position, duration: duration)
        moveB.timingMode = .EaseOut
        
        spriteA.runAction(SKAction.sequence([moveA, moveB]), completion: completion)
        spriteB.runAction(SKAction.sequence([moveB, moveA]))
        
        runAction(invalidSwapSound)
    }
    
    func animateMatchedCookies(chains: Set<Chain>, completion: () -> ()) {
        for chain in chains {
            animateScoreForChain(chain)
            for cookie in chain.cookies {
                if let sprite = cookie.sprite {
                    if sprite.actionForKey("removing") == nil {
                        let scaleAction = SKAction.scaleTo(0.1, duration: 0.3)
                        scaleAction.timingMode = .EaseOut
                        sprite.runAction(SKAction.sequence([scaleAction, SKAction.removeFromParent()]), withKey: "removing")
                    }
                }
            }
        }
        runAction(matchSound)
        runAction(SKAction.waitForDuration(0.3), completion: completion)
    }
    
    func animateFallingCookies(columns: [[Cookie]], completion: () -> ()) {
        var longestDuration: NSTimeInterval = 0
        
        for array in columns {
            for (index, cookie) in array.enumerate() {
                let newPosition = pointForColumn(cookie.column, row: cookie.row)
                let delay = 0.05 + 0.15 * NSTimeInterval(index)
                let sprite = cookie.sprite!
                let duration = NSTimeInterval(((sprite.position.y - newPosition.y) / tileHeight) * 0.1)
                longestDuration = max(longestDuration, duration + delay)
                let moveAction = SKAction.moveTo(newPosition, duration: duration)
                moveAction.timingMode = .EaseOut
                sprite.runAction(SKAction.sequence([SKAction.waitForDuration(delay), SKAction.group([moveAction, fallingCookieSound])]))
            }
        }
        runAction(SKAction.waitForDuration(longestDuration), completion: completion)
    }
    
    func animateNewCookies(columns: [[Cookie]], completion: () -> ()) {
        var longestDuration: NSTimeInterval = 0
        
        for array in columns {
            let startRow = array[0].row + 1
            
            for (index, cookie) in array.enumerate() {
                let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
                sprite.position = pointForColumn(cookie.column, row: startRow)
                cookiesLayer.addChild(sprite)
                cookie.sprite = sprite
                let delay = 0.1 + 0.2 * NSTimeInterval(array.count - index - 1)
                let duration = NSTimeInterval(startRow - cookie.row) * 0.1
                longestDuration = max(longestDuration, delay + duration)
                let newPosition = pointForColumn(cookie.column, row: cookie.row)
                let moveAction = SKAction.moveTo(newPosition, duration: duration)
                moveAction.timingMode = .EaseOut
                sprite.alpha = 0
                sprite.runAction(SKAction.sequence([SKAction.waitForDuration(delay), SKAction.group([SKAction.fadeInWithDuration(0.05), moveAction, addCookieSound])]))
            }
        }
        runAction(SKAction.waitForDuration(longestDuration), completion: completion)
    }
    
    func animateScoreForChain(chain: Chain) {
        let firstSprite = chain.firstCookie().sprite!
        let lastSprite = chain.lastCookie().sprite!
        let centerPosition = CGPoint(x: (firstSprite.position.x + lastSprite.position.x) / 2, y: (firstSprite.position.y + lastSprite.position.y) / 2 - 8)
        let scoreLabelNode = SKLabelNode(fontNamed: "GillSans-BoldItalic")
        scoreLabelNode.fontSize = 16
        scoreLabelNode.text = String(format: "%ld", chain.score)
        scoreLabelNode.position = centerPosition
        scoreLabelNode.zPosition = 300
        cookiesLayer.addChild(scoreLabelNode)
        let moveAction = SKAction.moveBy(CGVector(dx: 0, dy: 3), duration: 0.7)
        moveAction.timingMode = .EaseOut
        scoreLabelNode.runAction(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
    }
    
    func animateGameOver(completion: () -> ()) {
        let action = SKAction.moveBy(CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .EaseIn
        gameLayer.runAction(action, completion: completion)
    }
    
    func animateBeginGame(completion: () -> ()) {
        gameLayer.hidden = false
        gameLayer.position = CGPoint(x: 0.0, y: size.height)
        let action = SKAction.moveBy(CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .EaseOut
        gameLayer.runAction(action, completion: completion)
    }
    
    func showSelectionIndicatorForCookie(cookie: Cookie) {
        if selectionSprite.parent != nil {
            selectionSprite.removeFromParent()
        }
        
        if let sprite = cookie.sprite {
            let texture = SKTexture(imageNamed: cookie.cookieType.spriteNameHighlighted)
            selectionSprite.size = texture.size()
            selectionSprite.runAction(SKAction.setTexture(texture))
            sprite.addChild(selectionSprite)
            selectionSprite.alpha = 1.0
        }
    }
    
    func hideSelectionIndicator() {
        selectionSprite.runAction(SKAction.sequence([
        SKAction.fadeOutWithDuration(0.3),
        SKAction.removeFromParent()
        ]))
    }
    
    func removeAllCookieSprites() {
        cookiesLayer.removeAllChildren()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first! as UITouch
        let location = touch.locationInNode(cookiesLayer)
        let (success, column, row) = convertPoint(location)
        if success {
            if let cookie = level.cookieAtColumn(column, row: row) {
                showSelectionIndicatorForCookie(cookie)
                swipeFromColumn = column
                swipeFromRow = row
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if swipeFromColumn == nil {
            return
        }
        
        let touch = touches.first! as UITouch
        let location = touch.locationInNode(cookiesLayer)
        let (success, column, row) = convertPoint(location)
        if success {
            var horzDelta = 0
            var vertDelta = 0
            
            if column < swipeFromColumn! {
                horzDelta = -1
            }
            else if column > swipeFromColumn! {
                horzDelta = 1
            }
            else if row < swipeFromRow! {
                vertDelta = -1
            }
            else if row > swipeFromRow! {
                vertDelta = 1
            }
            
            if horzDelta != 0 || vertDelta != 0 {
                trySwapHorizontal(horizontal: horzDelta, vertical: vertDelta)
                hideSelectionIndicator()
                swipeFromColumn = nil
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if selectionSprite.parent != nil && swipeFromColumn != nil {
            hideSelectionIndicator()
        }
        swipeFromColumn = nil
        swipeFromRow = nil
    }
    
    override func touchesCancelled(touches: Set<UITouch>, withEvent event: UIEvent?) {
        touchesEnded(touches, withEvent: event)
    }
}
