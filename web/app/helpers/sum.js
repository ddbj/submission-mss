import { helper } from '@ember/component/helper';

export default helper(function sum([nums]) {
  return nums.reduce((acc, n) => acc + n, 0);
});
