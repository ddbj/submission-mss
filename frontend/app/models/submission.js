import { tracked } from '@glimmer/tracking';
import { underscore } from '@ember/string';

export default class Submission {
  @tracked tpa;
  @tracked sequencer;
  @tracked dfast;
  @tracked dataType;
  @tracked dataTypeOtherText;
  @tracked accessionNumber;
  @tracked files = [];
  @tracked entriesCount;
  @tracked holdDate;
  @tracked contactPerson = new Person();
  @tracked anotherPerson = new Person();
  @tracked shortTitle;
  @tracked description;
  @tracked emailLanguage;

  toPayload() {
    return toPayload(this, [
      'tpa',
      'sequencer',
      'dfast',
      'dataType',
      'dataTypeOtherText',
      'accessionNumber',
      'files',
      'entriesCount',
      'holdDate',
      'contactPerson',
      'anotherPerson',
      'shortTitle',
      'description',
      'emailLanguage'
    ]);
  }
}

class Person {
  @tracked fullName;
  @tracked email;
  @tracked affiliation;

  toPayload() {
    return toPayload(this, [
      'fullName',
      'email',
      'affiliation'
    ]);
  }
}

function toPayload(obj, keys) {
  const entries = keys.map((k) => {
    const v = obj[k];

    return [
      underscore(k),
      v?.toPayload ? v.toPayload(v) : v
    ];
  });

  return Object.fromEntries(entries);
}
