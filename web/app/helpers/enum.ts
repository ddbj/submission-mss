import { helper } from '@ember/component/helper';

import ENV from 'mssform/config/environment';

export default helper(function _enum([key]: [string]) {
  return (ENV['enums'] as Record<string, unknown>)[key];
});
