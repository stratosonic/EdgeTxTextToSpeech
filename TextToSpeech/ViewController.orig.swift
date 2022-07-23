//
//  ViewController.swift
//  TextToSpeech
//
//  Created by stratosonic on 9/7/16.
//  Copyright © 2016 flitey.com. All rights reserved.
//

import Cocoa
import AudioToolbox

class ViewControllerOrig: NSViewController, NSSpeechSynthesizerDelegate, NSComboBoxDelegate {
    
    var availableVoices:[NSSpeechSynthesizer.VoiceName] = []
    
    @IBOutlet weak var voiceComboBox: NSComboBox!
    @IBOutlet weak var speechRateTextField: NSTextField!
    @IBOutlet weak var speechTextSourceFile: NSTextField!
    @IBOutlet weak var destinationFolder: NSTextField!
    @IBOutlet weak var generateSoundsButtom: NSButton!
    
    @IBOutlet weak var progressSpinner: NSProgressIndicator!
    @IBOutlet weak var progressLabel: NSTextField!
    
    var textFieldBackgroundColor: NSColor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        availableVoices = NSSpeechSynthesizer.availableVoices
        
        progressSpinner.isHidden = true
        progressLabel.stringValue = ""
        textFieldBackgroundColor = speechTextSourceFile.backgroundColor
        
        print(availableVoices)
        
        // availableVoices is an array of voice names with the following format:
        // com.apple.speech.synthesis.voice.Name
        // or
        // com.apple.speech.synthesis.voice.Name.premium
        for voice in availableVoices {
            let components = voice.rawValue.components(separatedBy: ".")
            let voiceName = components[5]
            voiceComboBox.addItem(withObjectValue: voiceName.capitalized)
        }
        
        voiceComboBox.delegate = self
        voiceComboBox.selectItem(at: 0)
        
        speechRateTextField.floatValue = 200
    }
    
    /*override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }*/
    
    @IBAction func generateSounds(_ sender: Any) {
        
        DispatchQueue.main.async {
            self.generateSoundsButtom.isEnabled = false
            self.progressSpinner.isHidden = false
        }
        
        // DispatchQueue.global(qos: .background).async {
        var loopCount = 0
        
        self.destinationFolder.backgroundColor = self.textFieldBackgroundColor
        self.speechTextSourceFile.backgroundColor = self.textFieldBackgroundColor
        
        print(self.voiceComboBox.indexOfSelectedItem)
        
        let selectedVoice = self.availableVoices[self.voiceComboBox.indexOfSelectedItem]
        
        let synth = SpeechSynth(voice: selectedVoice.rawValue, rate: self.speechRateTextField.floatValue);
        
        var validFilePath = false
        var validDestinationFolder = false
        
        var filePath = ""
        if !self.speechTextSourceFile.stringValue.isEmpty {
            validFilePath = true
        } else {
            print("No source file selected")
            self.speechTextSourceFile.backgroundColor = NSColor.red
        }
        
        if !self.destinationFolder.stringValue.isEmpty {
            validDestinationFolder = true
        } else {
            print("No destination folder selected")
            self.destinationFolder.backgroundColor = NSColor.red
        }
        
        if validFilePath && validDestinationFolder {
            
            filePath = self.speechTextSourceFile.stringValue
            print("Source file: \(filePath)")
            
            var savePathRoot = self.destinationFolder.stringValue
            print("Destination folder: \(savePathRoot)")
            
            //let saveURL = URL(fileURLWithPath: savePathRoot + "/" +  "test1.aiff")
            //synth.speakThis(url: saveURL, stringToRead: "Testing")
            
                        
            if let aStreamReader = StreamReader(path: filePath) {
                defer {
                    aStreamReader.close()
                }
                while let line = aStreamReader.nextLine() {
                    
                    if !line.hasPrefix("#") {
                        let lineComponents = line.components(separatedBy: "|")
                        let folder = lineComponents[0]
                        let name = lineComponents[1]
                        let textToSpeak = lineComponents[2].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        
                        DispatchQueue.main.async {
                            self.progressLabel.stringValue = "Generating \"\(textToSpeak)\""
                        }
                        
                        do {
                            try FileManager.default.createDirectory(atPath: savePathRoot + "/" + folder, withIntermediateDirectories: true, attributes: nil)
                        } catch {
                            print(error)
                        }
                        
                        let saveURL = URL(fileURLWithPath: savePathRoot + "/" + folder + "/" + name + ".aiff")
                        print("Saving [\(textToSpeak)] to \(saveURL)")
                        
                        loopCount += 1
                        
                        //DispatchQueue.global(qos: .background).async {
                        let queue = DispatchQueue(label: "textToSpeech.queue", qos: .background)
                        queue.sync {
                            synth.speakThis(url: saveURL, stringToRead: textToSpeak)
                        //}
                        }
                        
                        //while synth.isBuildingText {
                        //    print("waiting")
                        //}
                    }
                }
            }
        }
        
        print("Done generating files!")
        
        //}
        
        DispatchQueue.main.async {
            self.generateSoundsButtom.isEnabled = true
            self.progressSpinner.isHidden = true
            self.progressLabel.stringValue = ""
        }
    }
    
    
    func reportError(error: OSStatus) {
        // Handle error
    }
    
    func convertAudio(_ url: URL, outputURL: URL) {
        var error : OSStatus = noErr
        var destinationFile: ExtAudioFileRef? = nil
        var sourceFile : ExtAudioFileRef? = nil
        
        var srcFormat : AudioStreamBasicDescription = AudioStreamBasicDescription()
        var dstFormat : AudioStreamBasicDescription = AudioStreamBasicDescription()
        
        ExtAudioFileOpenURL(url as CFURL, &sourceFile)
        
        var thePropertySize: UInt32 = UInt32(MemoryLayout.stride(ofValue: srcFormat))
        
        ExtAudioFileGetProperty(sourceFile!,
                                kExtAudioFileProperty_FileDataFormat,
                                &thePropertySize, &srcFormat)
        
        dstFormat.mSampleRate = 32000  //Set sample rate
        dstFormat.mFormatID = kAudioFormatLinearPCM
        dstFormat.mChannelsPerFrame = 1
        dstFormat.mBitsPerChannel = 16
        dstFormat.mBytesPerPacket = 2 * dstFormat.mChannelsPerFrame
        dstFormat.mBytesPerFrame = 2 * dstFormat.mChannelsPerFrame
        dstFormat.mFramesPerPacket = 1
        dstFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked |
        kAudioFormatFlagIsSignedInteger
        
        // Create destination file
        error = ExtAudioFileCreateWithURL(
            outputURL as CFURL,
            kAudioFileWAVEType,
            &dstFormat,
            nil,
            AudioFileFlags.eraseFile.rawValue,
            &destinationFile)
        print("Error 1 in convertAudio: \(error.description)")
        
        error = ExtAudioFileSetProperty(sourceFile!,
                                        kExtAudioFileProperty_ClientDataFormat,
                                        thePropertySize,
                                        &dstFormat)
        print("Error 2 in convertAudio: \(error.description)")
        
        error = ExtAudioFileSetProperty(destinationFile!,
                                        kExtAudioFileProperty_ClientDataFormat,
                                        thePropertySize,
                                        &dstFormat)
        print("Error 3 in convertAudio: \(error.description)")
        
        let bufferByteSize : UInt32 = 32768
        var srcBuffer = [UInt8](repeating: 0, count: 32768)
        var sourceFrameOffset : ULONG = 0
        
        while(true){
            var fillBufList = AudioBufferList(
                mNumberBuffers: 1,
                mBuffers: AudioBuffer(
                    mNumberChannels: 2,
                    mDataByteSize: UInt32(srcBuffer.count),
                    mData: &srcBuffer
                )
            )
            var numFrames : UInt32 = 0
            
            if(dstFormat.mBytesPerFrame > 0){
                numFrames = bufferByteSize / dstFormat.mBytesPerFrame
            }
            
            error = ExtAudioFileRead(sourceFile!, &numFrames, &fillBufList)
            print("Error 4 in convertAudio: \(error.description)")
            
            if(numFrames == 0){
                error = noErr;
                break;
            }
            
            sourceFrameOffset += numFrames
            error = ExtAudioFileWrite(destinationFile!, numFrames, &fillBufList)
            print("Error 5 in convertAudio: \(error.description)")
        }
        
        error = ExtAudioFileDispose(destinationFile!)
        print("Error 6 in convertAudio: \(error.description)")
        error = ExtAudioFileDispose(sourceFile!)
        print("Error 7 in convertAudio: \(error.description)")
    }
    
    @IBAction func browseSourceFile(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a .psv file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = false;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["psv"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                speechTextSourceFile.stringValue = path
                speechTextSourceFile.backgroundColor = textFieldBackgroundColor
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    
    @IBAction func browseDestinationFolder(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a destination folder";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canChooseFiles          = false;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                destinationFolder.stringValue = path
                destinationFolder.backgroundColor = textFieldBackgroundColor
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
}

