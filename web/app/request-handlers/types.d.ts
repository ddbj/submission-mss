import '@warp-drive/core/types/request';

declare module '@warp-drive/core/types/request' {
  interface RequestInfo {
    data?: Record<string, unknown>;
  }
}
