import { EventEmitter, requireNativeModule } from 'expo-modules-core';
import type { StartOptions, ResultPayload, ErrorPayload, VolumePayload } from './ExpoSpeechRecognition.types';

type NativeModuleShape = {
  isAvailableAsync(): Promise<boolean>;
  getPermissionsAsync(): Promise<Record<string, string>>;
  requestPermissionsAsync(): Promise<Record<string, unknown>>;
  start(options: StartOptions): Promise<void>;
  stop(): void;
  cancel(): void;
};

const NativeModule = requireNativeModule<NativeModuleShape>('ExpoSpeechRecognition');
const emitter = new EventEmitter(NativeModule as any);

let resultSub: any = null;
let errorSub: any = null;
let volumeSub: any = null;

export async function isAvailableAsync() {
  return NativeModule.isAvailableAsync();
}

export async function getPermissionsAsync() {
  return NativeModule.getPermissionsAsync();
}

export async function requestPermissionsAsync() {
  return NativeModule.requestPermissionsAsync();
}

export async function start(
  options: StartOptions,
  onResult: (text: string, isFinal: boolean) => void,
  onError?: (error: string) => void,
  onVolumeLevel?: (rmsDb: number) => void
) {
  resultSub?.remove();
  errorSub?.remove();
  volumeSub?.remove();

  resultSub = (emitter as any).addListener('onResult', (e: ResultPayload) => {
    onResult(e.text, e.isFinal);
  });

  errorSub = (emitter as any).addListener('onError', (e: ErrorPayload) => {
    onError?.(e.error);
  });

  if (onVolumeLevel) {
    volumeSub = (emitter as any).addListener('onVolumeLevel', (e: VolumePayload) => {
      onVolumeLevel(e.rmsDb);
    });
  }

  await NativeModule.start({
    language: options.language ?? 'sv-SE',
    interimResults: options.interimResults ?? true,
    continuous: !!options.continuous,
    maxSeconds: options.maxSeconds,
  });
}

export function stop() {
  NativeModule.stop();
}

export function cancel() {
  NativeModule.cancel();
}

export function removeListeners() {
  resultSub?.remove(); resultSub = null;
  errorSub?.remove();  errorSub = null;
  volumeSub?.remove(); volumeSub = null;
}

export default {
  isAvailableAsync,
  getPermissionsAsync,
  requestPermissionsAsync,
  start,
  stop,
  cancel,
  removeListeners,
};
