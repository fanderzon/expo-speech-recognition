import { requireNativeView } from 'expo';
import * as React from 'react';

import { ExpoSpeechRecognitionViewProps } from './ExpoSpeechRecognition.types';

const NativeView: React.ComponentType<ExpoSpeechRecognitionViewProps> =
  requireNativeView('ExpoSpeechRecognition');

export default function ExpoSpeechRecognitionView(props: ExpoSpeechRecognitionViewProps) {
  return <NativeView {...props} />;
}
