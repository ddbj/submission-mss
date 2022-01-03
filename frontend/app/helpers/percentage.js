import { helper } from '@ember/component/helper';

export default helper(function percentage([x, y]) {
  return Math.floor(x / y * 100);
});
