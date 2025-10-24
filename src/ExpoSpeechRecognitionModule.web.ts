export default {
  async isAvailableAsync() { return true; },
  async getPermissionsAsync() { return { microphone: 'unknown' }; },
  async requestPermissionsAsync() { return { microphone: 'requested' }; },
  async start() {},
  stop() {},
  cancel() {},
};
