import { findAll } from '@ember/test-helpers';

// Buttons are labelled by their translation, and several share their looks, so
// they are found by what they say.
export default function findButton(text: string) {
  const button = findAll('button').find((el) => el.textContent?.includes(text));

  if (!button) throw new Error(`Button not found: "${text}"`);

  return button;
}
