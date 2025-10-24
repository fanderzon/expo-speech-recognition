// Reexport the native module. On web, it will be resolved to ExpoSpeechRecognitionModule.web.ts
// and on native platforms to ExpoSpeechRecognitionModule.ts
export { default } from './ExpoSpeechRecognitionModule';
export { default as ExpoSpeechRecognitionView } from './ExpoSpeechRecognitionView';
export * from  './ExpoSpeechRecognition.types';
