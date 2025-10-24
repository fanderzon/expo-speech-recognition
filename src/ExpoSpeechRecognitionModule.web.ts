import { registerWebModule, NativeModule } from 'expo';

import { ExpoSpeechRecognitionModuleEvents } from './ExpoSpeechRecognition.types';

class ExpoSpeechRecognitionModule extends NativeModule<ExpoSpeechRecognitionModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(ExpoSpeechRecognitionModule, 'ExpoSpeechRecognitionModule');
