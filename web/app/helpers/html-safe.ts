import { htmlSafe as emberHtmlSafe } from '@ember/template';

export default function htmlSafe(str: Parameters<typeof emberHtmlSafe>[0]) {
  return emberHtmlSafe(str);
}
