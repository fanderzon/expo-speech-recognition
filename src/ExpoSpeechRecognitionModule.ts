import { NativeModule, requireNativeModule } from 'expo';

import { ExpoSpeechRecognitionModuleEvents } from './ExpoSpeechRecognition.types';

declare class ExpoSpeechRecognitionModule extends NativeModule<ExpoSpeechRecognitionModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoSpeechRecognitionModule>('ExpoSpeechRecognition');
