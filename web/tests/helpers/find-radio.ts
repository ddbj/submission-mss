import { findAll } from '@ember/test-helpers';

// Radios are labelled by their translation and carry generated ids, so they are
// found by the text next to them.
export default function findRadio(labelText: string) {
  const labels = findAll('.form-check-label') as HTMLLabelElement[];
  const label = labels.find((el) => el.textContent?.trim().startsWith(labelText));

  if (!label) throw new Error(`Radio label not found: "${labelText}"`);

  const input = label.control as HTMLInputElement | null;

  if (!input) throw new Error(`Radio input not found for label: "${labelText}"`);

  return input;
}
