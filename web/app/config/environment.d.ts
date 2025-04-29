/**
 * Type declarations for
 *    import config from 'my-app/config/environment'
 */
declare const config: {
  environment: string;
  modulePrefix: string;
  podModulePrefix: string;
  locationType: 'history' | 'hash' | 'none' | 'auto';
  rootURL: string;
  APP: Record<string, unknown>;
  railsEnv: string;
  apiURL: string;
  sentryDSN?: string;

  enums: {
    locales: { key: string; label: Record<string, string> }[];
    data_types: { key: string; label: string }[];
    sequencers: { key: string; label: string }[];
  };
};

export default config;
