import * as React from 'react';

import { ExpoSpeechRecognitionViewProps } from './ExpoSpeechRecognition.types';

export default function ExpoSpeechRecognitionView(props: ExpoSpeechRecognitionViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
