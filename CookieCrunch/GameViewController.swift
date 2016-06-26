//
//  GameViewController.swift
//  CookieCrunch
//
//  Created by Jeremiah on 4/2/16.
//  Copyright (c) 2016 Jeremiah. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

class GameViewController: UIViewController {
    var scene: GameScene!
    var level: Level!
    
    lazy var backgroundMusic: AVAudioPlayer? = {
        let url = NSBundle.mainBundle().URLForResource("Mining by Moonlight", withExtension: "mp3")
        do {
            let player = try AVAudioPlayer(contentsOfURL: url!)
            player.numberOfLoops = -1
            return player
        }
        catch {
            return nil
        }
    }()
    
    var movesLeft = 0
    var score = 0
    var currentLevel = 0
    let maxLevel = 6
    
    @IBOutlet weak var targetLabel: UILabel!
    @IBOutlet weak var movesLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var gameOverPanel: UIImageView!
    @IBOutlet weak var shuffleButton: UIButton!
    
    var tapGestureRecognizer: UITapGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()

        let skView = view as! SKView
        skView.multipleTouchEnabled = false
        
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        
        loadLevel()
        
        scene.swipeHandler = handleSwipe
        gameOverPanel.hidden = true
        
        self.shuffleButton.layer.cornerRadius = 10.0
        
        skView.presentScene(scene)
        
        backgroundMusic!.play()
        
        beginGame()
    }
    
    func loadLevel() {
        level = Level(filename: "Level_" + String(currentLevel))
        scene.level = level
        scene.addTiles()
    }
    
    func shuffle() {
        scene.removeAllCookieSprites()
        let newCookies = level.shuffle()
        scene.addSpritesForCookies(newCookies)
    }
    
    func beginGame() {
        movesLeft = level.maximumMoves
        score = 0
        updateLabels()
        level.resetComboMultiplier()
        scene.animateBeginGame() {
            self.shuffleButton.hidden = false
        }
        shuffle()
    }

    func handleSwipe(swap: Swap) {
        view.userInteractionEnabled = false
        
        if level.isPossibleSwap(swap) {
            level.performSwap(swap)
            scene.animateSwap(swap) {
                self.handleMatches()
            }
        }
        else {
            scene.animateInvalidSwap(swap) {
                self.view.userInteractionEnabled = true
            }
        }
    }
    
    func handleMatches() {
        let chains = level.removeMatches()
        if chains.count == 0 {
            beginNextTurn()
            return
        }
        scene.animateMatchedCookies(chains) {
            for chain in chains {
                self.score += chain.score
            }
            self.updateLabels()
            let columns = self.level.fillHoles()
            self.scene.animateFallingCookies(columns) {
                let columns = self.level.topOffCookies()
                self.scene.animateNewCookies(columns) {
                    self.handleMatches()
                }
            }
        }
    }
    
    func beginNextTurn() {
        level.resetComboMultiplier()
        level.detectPossibleSwaps()
        updateMoves()
        self.view.userInteractionEnabled = true
    }
    
    func updateLabels() {
        targetLabel.text = String(format: "%ld", level.targetScore)
        movesLabel.text = String(format: "%ld", movesLeft)
        scoreLabel.text = String(format: "%ld", score)
    }
    
    func updateMoves() {
        movesLeft -= 1
        updateLabels()
        if score >= level.targetScore {
            gameOverPanel.image = UIImage(named: "LevelComplete")
            showGameOver()
            currentLevel += 1
            if currentLevel > maxLevel {
                currentLevel = 0
            }
        }
        else if movesLeft == 0 {
            gameOverPanel.image = UIImage(named: "GameOver")
            showGameOver()
            currentLevel = 0
        }
    }
    
    func showGameOver() {
        shuffleButton.hidden = true
        gameOverPanel.hidden = false
        scene.userInteractionEnabled = false
        
        scene.animateGameOver() {
            self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(GameViewController.hideGameOver))
            self.view.addGestureRecognizer(self.tapGestureRecognizer)
        }
    }
    
    func hideGameOver() {
        view.removeGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer = nil
        
        gameOverPanel.hidden = true
        scene.userInteractionEnabled = true
        
        loadLevel()
        
        beginGame()
    }
    
    @IBAction func shuffleButtonPressed(sender: AnyObject) {
        shuffle()
        updateMoves()
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait, .PortraitUpsideDown]
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
}
