import { helper } from '@ember/component/helper';

import ENV from 'mssform/config/environment';

export default helper(function _enum([key]) {
  return ENV.APP.enums[key];
});
