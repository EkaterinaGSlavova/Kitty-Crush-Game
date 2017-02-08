//
//  GameViewController.swift
//  KittyCrush
//
//  Created by Ekaterina on 2/12/16.
//  Copyright (c) 2016 Ekaterina. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

class GameViewController: UIViewController {
    
    var scene: GameScene!
    var level: Level!
    var movesLeft = 0
    var score = 0
    var levelArray = ["Level_0", "Level_1", "Level_2", "Level_3", "Level_4", "Level_5", "Level_6", "Level_7", "Level_8", "Level_9", "Level_10", "Level_11", "Level_12", "Level_13", "Level_14", "Level_15"]
    var levelNumber = -1
    
    @IBOutlet weak var soundButton: UIButton!
    @IBOutlet weak var targetLabel: UILabel!
    @IBOutlet weak var movesLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var gameOverImageView: UIImageView!
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var nextLevelButton: UIButton!
    @IBOutlet weak var StartOverButton: UIButton!
    @IBOutlet weak var levelLabel: UILabel!
    
     lazy var backgroundMusic: AVAudioPlayer = {
        let url = Bundle.main.url(forResource: "BackgroundMusic", withExtension: "mp3")
        let player = try? AVAudioPlayer(contentsOf: url!)
        player!.numberOfLoops = -1
        return player!
    }()

    override var shouldAutorotate : Bool {
         return true
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.allButUpsideDown
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view
        let skView = view as! SKView
        skView.isMultipleTouchEnabled = false
        
        // Create and configure the scene
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        nextLevelButton.isHidden = true
        soundButton.isSelected = false
        soundButton.setImage(UIImage(named: "on"), for: UIControlState())
        // Load the level
        loadNextLevel()
        
        scene.swipeHandler = handleSwipe
        
        gameOverImageView.isHidden = true
        StartOverButton.isHidden = true
        // Present the scene
        skView.presentScene(scene)
        backgroundMusic.play()
        beginGame()
    }
    
    func loadLevels(_ name: String) {
        level = Level(filename: name)
        updateLabels()
        levelLabel.isHidden = false
        scene.level = level
    }
    
    func beginGame() {
        movesLeft = level.maximumMoves
        //score = 0
        updateLabels()
        level.resetMultiplier()
        scene.animateBeginGame() { self.shuffleButton.isHidden = false; self.nextLevelButton.isHidden = true}
        shuffle()
    }
    
    func loadNextLevel() {
        levelNumber += 1
        let name = levelArray[levelNumber]
        loadLevels(name)
    }

    func shuffle() {
        scene.removeAllKittySprites()
        let newKitties = level.shuffle()
        scene.addSpritesForKitties(newKitties)
    }
    
    func handleSwipe(_ swap: Swap) {
        
        view.isUserInteractionEnabled = false
        
        if level.isPossibleSwap(swap) {
            level.performSwap(swap)
            scene.animateSwap(swap, completion: handleMatches)
        } else if level.isThereBarsInSwap(swap) {
            view.isUserInteractionEnabled = true
        } else {
            scene.animateInvalidSwap(swap) {
                self.view.isUserInteractionEnabled = true
            }
        }
    }
    
    func handleMatches() {
        
        let chains = level.removeMatches()
        if chains.count == 0 {
            beginNextTurn()
            return
        }
        scene.animateMatchedKitties(chains) {
            let columns = self.level.fillHoles()
            for chain in chains {
                self.score += chain.score
                if chain.score >= 180 {
                    self.scene.animateComboKitty()
                }
            }
            self.updateLabels()
            self.scene.animateFallingKitties(columns) {
                let columns = self.level.topUpKitties()
                self.scene.animateNewKitties(columns) {
                    self.handleMatches()
                }
            }
        }
    }
    
    func beginNextTurn() {
        level.resetMultiplier()
        level.detectPossibleSwaps()
        view.isUserInteractionEnabled = true
        decrementMoves()
    }
    
    func updateLabels() {
        targetLabel.text = String(format: "%ld", level.targetScore)
        movesLabel.text = String(format: "%ld", movesLeft)
        scoreLabel.text = String(format: "%ld", score)
        levelLabel.text = String(format: "Level %ld", levelNumber)
    }
    
    func decrementMoves() {
 
        movesLeft -= 1
        updateLabels()
        
        if score >= level.targetScore {
            nextLevelButton.isHidden = false
            levelLabel.isHidden = false
            gameOverImageView.image = UIImage(named: "LevelComplete")
            showGameOver()
        } else if movesLeft == 0 {
            gameOverImageView.image = UIImage(named: "GameOver")
            showGameOver()
            nextLevelButton.isHidden = true
            StartOverButton.isHidden = false
            levelLabel.isHidden = true
        }
    }
    
    func showGameOver() {
       
        gameOverImageView.isHidden = false
        scene.isUserInteractionEnabled = false
        shuffleButton.isHidden = true
        
        
        if levelArray.count - 1 == levelNumber {
            nextLevelButton.isHidden = true
        }
        
        scene.animateGameOver() {}
    }
    
    func hideGameOver() {
        
        gameOverImageView.isHidden = true
        StartOverButton.isHidden = true
        scene.isUserInteractionEnabled = true
        
        beginGame()
    }
    
    @IBAction func nextLevelPressed(_ sender: AnyObject) {
        loadNextLevel()
        hideGameOver()
    }
    @IBAction func soundButtonPressed(_ sender: AnyObject) {
        
        soundButton.isSelected = !soundButton.isSelected
        if soundButton.isSelected  {
             backgroundMusic.stop()
        } else {
            backgroundMusic.play()
        }
    }

    @IBAction func StartOverPressed(_ sender: AnyObject) {
        levelNumber = 0
        score = 0
        updateLabels()
        loadLevels("Level_0")
        hideGameOver()
    }
    @IBAction func shuffleButtonPressed(_: AnyObject) {
        shuffle()
        decrementMoves()
    }
}
