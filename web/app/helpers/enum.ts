import ENV from 'mssform/config/environment';

export default function _enum(key: 'locales' | 'data_types' | 'sequencers') {
  return ENV.enums[key];
}
