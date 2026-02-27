import { helper } from '@ember/component/helper';

export default helper(function mapGet([map, key]: [Map<unknown, unknown>, unknown]) {
  return map.get(key);
});
