package expo.modules.speechrecognition

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.content.ContextCompat
import expo.modules.kotlin.Promise
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class ExpoSpeechRecognitionModule : Module() {
  private var speechRecognizer: SpeechRecognizer? = null
  private var isListening = false

  override fun definition() = ModuleDefinition {
    Name("ExpoSpeechRecognition")

    Events("onResult", "onError", "onVolumeLevel")

    AsyncFunction("isAvailableAsync") {
      val context = appContext.reactContext
        ?: throw IllegalStateException("React context not available")
      SpeechRecognizer.isRecognitionAvailable(context)
    }

    AsyncFunction("getPermissionsAsync") {
      val context = appContext.reactContext
        ?: throw IllegalStateException("React context not available")
      val granted = ContextCompat.checkSelfPermission(
        context, Manifest.permission.RECORD_AUDIO
      ) == PackageManager.PERMISSION_GRANTED
      mapOf("microphone" to if (granted) "granted" else "denied")
    }

    AsyncFunction("requestPermissionsAsync") { promise: Promise ->
      val activity: Activity? = appContext.currentActivity
      if (activity == null) {
        promise.resolve(mapOf("microphone" to "unavailable"))
      } else {
        // Recommend requesting permission in app layer; resolve immediately here
        promise.resolve(mapOf("microphone" to "requested"))
      }
    }

    AsyncFunction("start") { options: Map<String, Any?> ->
      Handler(Looper.getMainLooper()).post { startListening(options) }
    }

    Function("stop") {
      Handler(Looper.getMainLooper()).post { stopListening(true) }
    }

    Function("cancel") {
      Handler(Looper.getMainLooper()).post { stopListening(false) }
    }
  }

  private fun startListening(options: Map<String, Any?>) {
    if (isListening) stopListening(false)

    val lang = (options["language"] as? String) ?: "sv-SE"
    val wantInterim = (options["interimResults"] as? Boolean) ?: true

    val context = appContext.reactContext
      ?: throw IllegalStateException("React context not available")

    speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context).apply {
      setRecognitionListener(object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {}
        override fun onBeginningOfSpeech() {}
        override fun onRmsChanged(rmsdB: Float) {
          sendEvent("onVolumeLevel", mapOf("rmsDb" to rmsdB.toDouble()))
        }
        override fun onBufferReceived(buffer: ByteArray?) {}
        override fun onEndOfSpeech() {}
        override fun onError(error: Int) {
          sendEvent("onError", mapOf("error" to "code $error"))
          stopListening(false)
        }
        override fun onPartialResults(partialResults: Bundle?) {
          if (!wantInterim) return
          val data = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
          val text = data?.firstOrNull() ?: ""
          sendEvent("onResult", mapOf("text" to text, "isFinal" to false))
        }
        override fun onResults(results: Bundle?) {
          val data = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
          val text = data?.firstOrNull() ?: ""
          sendEvent("onResult", mapOf("text" to text, "isFinal" to true))
          stopListening(true)
        }
        override fun onEvent(eventType: Int, params: Bundle?) {}
      })
    }

    val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
      putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
      putExtra(RecognizerIntent.EXTRA_LANGUAGE, lang)
      putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, wantInterim)
      putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
    }

    speechRecognizer?.startListening(intent)
    isListening = true
  }

  private fun stopListening(finalStop: Boolean) {
    if (!isListening) return
    isListening = false
    speechRecognizer?.apply {
      if (finalStop) stopListening() else cancel()
      destroy()
    }
    speechRecognizer = null
  }
}
