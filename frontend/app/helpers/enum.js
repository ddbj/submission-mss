import { helper } from '@ember/component/helper';

import ENV from 'mssform-web/config/environment';

export default helper(function _enum([key]) {
  return ENV.APP.enums[key];
});
