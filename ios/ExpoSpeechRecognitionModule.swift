import ExpoModulesCore
import Speech
import AVFoundation

public class ExpoSpeechRecognitionModule: Module {
  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  private let audioEngine = AVAudioEngine()
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  private var speechRecognizer: SFSpeechRecognizer?
  private var timeoutTimer: Timer?

  public func definition() -> ModuleDefinition {
    // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
    // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
    // The module will be accessible from `requireNativeModule('ExpoSpeechRecognition')` in JavaScript.
    Name("ExpoSpeechRecognition")

    Events("onResult", "onError", "onVolumeLevel")

    AsyncFunction("isAvailableAsync") { () -> Bool in
      return SFSpeechRecognizer(locale: Locale(identifier: "sv-SE"))?.isAvailable ?? true
    }

    AsyncFunction("getPermissionsAsync") { () -> [String: String] in
      let mic = AVAudioSession.sharedInstance().recordPermission
      let speech = SFSpeechRecognizer.authorizationStatus()
      return [
        "microphone": "\(mic.rawValue)",
        "speech": "\(speech.rawValue)"
      ]
    }

    AsyncFunction("requestPermissionsAsync") { (promise: Promise) in
      AVAudioSession.sharedInstance().requestRecordPermission { _ in
        SFSpeechRecognizer.requestAuthorization { status in
          promise.resolve(["speech": status.rawValue])
        }
      }
    }

    AsyncFunction("start") { (options: [String: Any]) in
      self.startRecognition(options: options)
    }

    Function("stop") {
      self.stopRecognition(finalStop: true)
    }

    Function("cancel") {
      self.stopRecognition(finalStop: false)
    }

    // Enables the module to be used as a native view. Definition components that are accepted as part of the
    // view definition: Prop, Events.
    // No native view needed
  }

  private func startRecognition(options: [String: Any]) {
    let localeId = options["language"] as? String ?? Locale.current.identifier
    let wantInterim = options["interimResults"] as? Bool ?? true
    let maxSeconds = options["maxSeconds"] as? Double

    speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeId))
    guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
      self.sendEvent("onError", ["error": "recognizer not available"])
      return
    }

    stopRecognition(finalStop: false)

    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    recognitionRequest?.shouldReportPartialResults = wantInterim

    let audioSession = AVAudioSession.sharedInstance()
    try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
    try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

    let inputNode = audioEngine.inputNode
    let format = inputNode.outputFormat(forBus: 0)
    inputNode.removeTap(onBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
      self.recognitionRequest?.append(buffer)
      // Optional: compute RMS for volume level
      let rms = self.computeRMS(buffer: buffer)
      self.sendEvent("onVolumeLevel", ["rmsDb": rms])
    }

    audioEngine.prepare()
    try? audioEngine.start()

    if let maxSeconds = maxSeconds, maxSeconds > 0 {
      timeoutTimer?.invalidate()
      timeoutTimer = Timer.scheduledTimer(withTimeInterval: maxSeconds, repeats: false) { _ in
        self.sendEvent("onError", ["error": "timeout"])
        self.stopRecognition(finalStop: true)
      }
    }

    recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { result, error in
      if let error = error {
        self.sendEvent("onError", ["error": error.localizedDescription])
        self.stopRecognition(finalStop: false)
        return
      }
      guard let result = result else { return }
      self.sendEvent("onResult", ["text": result.bestTranscription.formattedString, "isFinal": result.isFinal])
      if result.isFinal {
        self.stopRecognition(finalStop: true)
      }
    }
  }

  private func stopRecognition(finalStop: Bool) {
    timeoutTimer?.invalidate(); timeoutTimer = nil
    if audioEngine.isRunning {
      audioEngine.stop()
      audioEngine.inputNode.removeTap(onBus: 0)
    }
    recognitionRequest?.endAudio()
    recognitionTask?.cancel(); recognitionTask = nil
    recognitionRequest = nil
    if finalStop {
      try? AVAudioSession.sharedInstance().setActive(false)
    }
  }

  private func computeRMS(buffer: AVAudioPCMBuffer) -> Double {
    guard let channelData = buffer.floatChannelData?[0] else { return 0 }
    let frameLength = Int(buffer.frameLength)
    var sum: Float = 0
    vDSP_measqv(channelData, 1, &sum, vDSP_Length(frameLength))
    let rms = sqrt(sum)
    let db = 20 * log10(Double(rms) + 1e-7)
    return db
  }
}
