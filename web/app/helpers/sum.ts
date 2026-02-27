import { helper } from '@ember/component/helper';

export default helper(function sum([nums]: [number[]]) {
  return nums.reduce((acc, n) => acc + n, 0);
});
