import { htmlSafe as emberHtmlSafe } from '@ember/template';

export default function htmlSafe(str) {
  return emberHtmlSafe(str);
}
