import { helper } from '@ember/component/helper';

export default helper(function mapGet([map, key]) {
  return map.get(key);
});
