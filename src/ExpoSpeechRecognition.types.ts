export type StartOptions = {
  language?: string;
  interimResults?: boolean;
  continuous?: boolean;
  maxSeconds?: number;
};

export type ResultPayload = {
  text: string;
  isFinal: boolean;
};

export type ErrorPayload = {
  error: string;
};

export type VolumePayload = {
  rmsDb: number;
};
