// ember-intl no longer escapes the values it interpolates into a message that
// is rendered as HTML, so every value handed to one goes through here first.
export default function escapeHtml(str: string | null | undefined) {
  return str?.replace(/[&<>"'`=]/g, (char) => `&#${char.charCodeAt(0)};`);
}
