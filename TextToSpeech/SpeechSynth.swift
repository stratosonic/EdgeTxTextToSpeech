//
//  SpeechSynth.swift
//  TextToSpeech
//
//  Created by stratosonic on 2/8/17.
//  Copyright © 2017 flitey.com. All rights reserved.
//

import Foundation
import Cocoa

class SpeechSynth: NSObject, NSApplicationDelegate, NSSpeechSynthesizerDelegate {
    
    var speechSynth: NSSpeechSynthesizer = NSSpeechSynthesizer()
    
    var isBuildingText = false
    
    init(voice: String, rate: Float) {
        super.init()
        
        print("Using voice: \(voice)")
        print("Speech rate: \(rate)")
        speechSynth = NSSpeechSynthesizer.init(voice: NSSpeechSynthesizer.VoiceName(rawValue: voice))!
        speechSynth.delegate = self
        speechSynth.rate = rate
    }
    
    func speakThis(url: URL, stringToRead: String) {
        //isBuildingText = true
        
        print("SpeechSynth [startSpeaking]: preparing to speak \"\(stringToRead)\"")
        
        let success = self.speechSynth.startSpeaking(stringToRead, to: url)
        if success {
            self.isBuildingText = true
            print("SpeechSynth [startSpeaking]: started speaking")
        } else {
            print("SpeechSynth [startSpeaking]: failed to start speaking")
        }
    }
    
    func speechSynthesizer(_ sender: NSSpeechSynthesizer, willSpeakWord characterRange: NSRange, of string: String) {

        print("SpeechSynth [willSpeakWord]: starting to speak a word from: \(string)")
    }
    
    func speechSynthesizer(_ sender: NSSpeechSynthesizer, didFinishSpeaking finishedSpeaking: Bool) {
        //DispatchQueue.main.async {
            if finishedSpeaking {
                print("SpeechSynth [didFinishSpeaking]: Finished speaking")
            } else {
                print ("SpeechSynth [didFinishSpeaking]: An error occurred")
            }
            self.isBuildingText = false
        //}
    }
    
    func speechSynthesizer(_ sender: NSSpeechSynthesizer, didEncounterErrorAt characterIndex: Int, of string: String, message: String) {
        print("SpeechSynth [didEncounterErrorAt]: \(string) - \(message)")
    }
}
