import { helper } from '@ember/component/helper';

export default helper(function percentage([x, y]: [number, number]) {
  return Math.floor((x / y) * 100);
});
