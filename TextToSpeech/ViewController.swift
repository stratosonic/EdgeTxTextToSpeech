//
//  ViewController.swift
//  TextToSpeech
//
//  Created by stratosonic on 9/7/16.
//  Copyright © 2016 flitey.com All rights reserved.
//

import Cocoa
import AudioToolbox

class ViewController: NSViewController, NSSpeechSynthesizerDelegate, NSComboBoxDelegate {
    
    var speechSynth: NSSpeechSynthesizer = NSSpeechSynthesizer()
    var availableVoices:[NSSpeechSynthesizer.VoiceName] = []
    var textFieldBackgroundColor: NSColor?
    var numberOfFilesGenerated = 0
    var speechItems:[SpeechItem] = []
    
    @IBOutlet weak var voiceComboBox: NSComboBox!
    @IBOutlet weak var speechRateTextField: NSTextField!
    @IBOutlet weak var speechTextSourceFile: NSTextField!
    @IBOutlet weak var speechTextSourceBrowseButton: NSButton!
    @IBOutlet weak var destinationFolder: NSTextField!
    @IBOutlet weak var destinationFolderBrowseButton: NSButton!
    @IBOutlet weak var generateSoundsButtom: NSButton!
    
    @IBOutlet weak var progressSpinner: NSProgressIndicator!
    @IBOutlet weak var progressLabel: NSTextField!
    
    let PSV_SEPARATOR = "|"
    let CSV_SEPARATOR = ","
    
    var isSpeaking = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        availableVoices = NSSpeechSynthesizer.availableVoices
        
        
        progressSpinner.isHidden = true
        progressSpinner.isIndeterminate = true
        progressSpinner.usesThreadedAnimation = true
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
        
        speechRateTextField.floatValue = 160
    }
    
    @IBAction func generateSounds(_ sender: Any) {
        
        numberOfFilesGenerated = 0
        
        DispatchQueue.main.async {
            self.speechTextSourceFile.isEnabled = false
            self.speechTextSourceBrowseButton.isEnabled = false
            self.destinationFolder.isEnabled = false
            self.destinationFolderBrowseButton.isEnabled = false
            self.voiceComboBox.isEnabled = false
            self.speechRateTextField.isEnabled = false
            self.generateSoundsButtom.isEnabled = false
            self.progressSpinner.isHidden = false
            self.progressSpinner.startAnimation(nil)
        }
        
        destinationFolder.backgroundColor = textFieldBackgroundColor
        speechTextSourceFile.backgroundColor = textFieldBackgroundColor
        
        print(voiceComboBox.indexOfSelectedItem)
        
        let selectedVoiceLongName = availableVoices[voiceComboBox.indexOfSelectedItem]
        
        let components = selectedVoiceLongName.rawValue.components(separatedBy: ".")
        let selectedVoiceShortName = components[5].uppercased()
        
        speechSynth = NSSpeechSynthesizer.init(voice: NSSpeechSynthesizer.VoiceName(rawValue: selectedVoiceLongName.rawValue))!
        speechSynth.delegate = self
        speechSynth.rate = speechRateTextField.floatValue
        speechSynth.volume = 1.0
        
        var validFilePath = false
        var validDestinationFolder = false
        
        var filePath = ""
        if !speechTextSourceFile.stringValue.isEmpty {
            validFilePath = true
        } else {
            print("No source file selected")
            speechTextSourceFile.backgroundColor = NSColor.red
        }
        
        if !destinationFolder.stringValue.isEmpty {
            validDestinationFolder = true
        } else {
            print("No destination folder selected")
            destinationFolder.backgroundColor = NSColor.red
        }
        
        if validFilePath && validDestinationFolder {
            
            filePath = speechTextSourceFile.stringValue
            print("Source file: \(filePath)")
            let filePathComponents = filePath.components(separatedBy: ".")
            let sourceFileType = filePathComponents[filePathComponents.count - 1]
            print(sourceFileType)
            
            let fileTypes = ["csv", "psv"]
            if fileTypes.contains(sourceFileType) {
                
                var separator: String
                if sourceFileType == "psv" {
                    separator = PSV_SEPARATOR
                } else {
                    separator = CSV_SEPARATOR
                }
                
                let savePathRoot = destinationFolder.stringValue
                print("Destination folder: \(savePathRoot)")
                
                if let aStreamReader = StreamReader(path: filePath) {
                    defer {
                        aStreamReader.close()
                    }
                    
                    var line_count = 0
                    while let line = aStreamReader.nextLine() {
                        if line_count == 0 {
                            line_count += 1
                        } else {
                            line_count += 1
                                                       
                            let lineComponents = line.components(separatedBy: separator)
                            let en_text = lineComponents[1].replacingOccurrences(of: "\"", with: "")
                            let text = lineComponents[2].replacingOccurrences(of: "\"", with: "")
                            let folder = lineComponents[4].replacingOccurrences(of: "\"", with: "")
                            var filename = lineComponents[5].replacingOccurrences(of: "\"", with: "")
                            
                            let textToSpeak = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                            
                            // split the name at the decimal (if it exists). Drop anything after the decimal (such as .wav)
                            let nameComponents = filename.components(separatedBy: ".")
                            if nameComponents.count > 1 {
                                filename = nameComponents[0]
                            }
                            
                            let speechItem = SpeechItem(folderName: folder, fileName: filename, textToSpeak: textToSpeak)
                            speechItems.append(speechItem)
                            
                            let path = savePathRoot + "/" + selectedVoiceShortName + "/" + folder
                            
                            DispatchQueue.main.async {
                                self.progressLabel.stringValue = "Generating folder path:\"\(path)\""
                            }
                            /*
                             let folder = lineComponents[0]
                             var name = lineComponents[1]
                             let textToSpeak = lineComponents[2].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                             
                             // split the name at the decimal (if it exists). Drop anything after the decimal (such as .wav)
                             let nameComponents = name.components(separatedBy: ".")
                             if nameComponents.count > 1 {
                             name = nameComponents[0]
                             }
                             
                             let speechItem = SpeechItem(folderName: folder, fileName: name, textToSpeak: textToSpeak)
                             speechItems.append(speechItem)
                             
                             let path = savePathRoot + "/" + selectedVoiceShortName + "/" + folder
                             
                             DispatchQueue.main.async {
                             self.progressLabel.stringValue = "Generating folder path:\"\(path)\""
                             }
                             */
                            do {
                                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                            } catch {
                                print(error)
                            }
                            
                        }
                    }
                }
            }
            
            DispatchQueue.global(qos: .background).async {
                if !self.speechItems.isEmpty {
                    
                    let savePathRoot = self.destinationFolder.stringValue
                    
                    for speechItem in self.speechItems {
                        
                        self.isSpeaking = true
                        
                        DispatchQueue.main.async {
                            self.progressLabel.stringValue = "Generating \"\(speechItem.textToSpeak)\""
                        }
                        
                        let path = savePathRoot + "/" + selectedVoiceShortName + "/" + speechItem.folderName
                        
                        let saveURL = URL(fileURLWithPath: path + "/" + speechItem.fileName + ".aiff")
                        print("Saving \"\(speechItem.textToSpeak)\" to \(saveURL)")
                        
                        
                        let success = self.speechSynth.startSpeaking(speechItem.textToSpeak, to: saveURL)
                        if success {
                            print("SpeechSynth [startSpeaking]: started speaking \"\(speechItem.textToSpeak)\"")
                        } else {
                            print("SpeechSynth [startSpeaking]: failed to start speaking \"\(speechItem.textToSpeak)\"")
                        }
                        
                        while(self.isSpeaking) {
                            print("waiting")
                            usleep(100000)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.progressLabel.stringValue = "Converting files to .wav format"
                    }
                    self.convertToWav()
                    
                    DispatchQueue.main.async {
                        self.speechTextSourceFile.isEnabled = true
                        self.speechTextSourceBrowseButton.isEnabled = false
                        self.destinationFolder.isEnabled = false
                        self.destinationFolderBrowseButton.isEnabled = false
                        self.voiceComboBox.isEnabled = true
                        self.speechRateTextField.isEnabled = true
                        self.generateSoundsButtom.isEnabled = true
                        self.progressSpinner.isHidden = true
                        self.progressSpinner.stopAnimation(nil)
                        self.progressLabel.stringValue = ""
                    }
                }
            }
            
            print("Done generating files!")
            
        }
    }
    
    func speechSynthesizer(_ sender: NSSpeechSynthesizer, didFinishSpeaking finishedSpeaking: Bool) {
        autoreleasepool {
            DispatchQueue.main.async {
                self.numberOfFilesGenerated = self.numberOfFilesGenerated - 1
                
                if finishedSpeaking {
                    self.isSpeaking = false
                    print("SpeechSynth [didFinishSpeaking]: Finished speaking")
                } else {
                    //self.isSpeaking = false
                    sender.continueSpeaking()
                    print ("SpeechSynth [didFinishSpeaking]: An error occurred")
                }
            }
        }
    }
    
    func convertToWav() {
        
        do {
            let fileManager = FileManager()
            let directoryContents = fileManager.listFiles(path: destinationFolder.stringValue)
            //print(directoryContents)
            
            let aiffFiles = directoryContents.filter{ $0.pathExtension == "aiff" }
            print("aiff urls:", aiffFiles)
            
            for aiffFile in aiffFiles {
                var destAiffFile = aiffFile.absoluteURL
                
                destAiffFile.deletePathExtension()
                destAiffFile.appendPathExtension("wav")
                
                print("converting from \(aiffFile.absoluteString) to \(destAiffFile.absoluteString)")
                self.convertAudio(aiffFile, outputURL: destAiffFile)
                
                print("deleting aiff file")
                try fileManager.removeItem(at: aiffFile)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        print("Done converting files")
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
        
        dialog.title                   = "Choose a .psv or .csv file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = false;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["psv", "csv"];
        
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

extension FileManager {
    func listFiles(path: String) -> [URL] {
        let baseurl: URL = URL(fileURLWithPath: path)
        var urls = [URL]()
        enumerator(atPath: path)?.forEach({ (e) in
            guard let s = e as? String else { return }
            let relativeURL = URL(fileURLWithPath: s, relativeTo: baseurl)
            let url = relativeURL.absoluteURL
            urls.append(url)
        })
        return urls
    }
}
