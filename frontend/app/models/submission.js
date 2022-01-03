import { isPresent } from '@ember/utils';
import { tracked } from '@glimmer/tracking';
import { underscore } from '@ember/string';

export default class Submission {
  @tracked tpa;
  @tracked sequencer;
  @tracked dfast;
  @tracked dataType;
  @tracked dataTypeOtherText;
  @tracked accessionNumber;
  @tracked entriesCount;
  @tracked holdDate;
  @tracked contactPerson = new Person();
  @tracked anotherPerson = new Person();
  @tracked shortTitle;
  @tracked description;
  @tracked emailLanguage;

  get dataTypes() {
    return this.dfast ? ['wgs', 'complete_genome', 'mag', 'wgs_version_up']
                      : ['wgs', 'complete_genome', 'mag', 'sag', 'wgs_version_up', 'tls', 'htg', 'tsa', 'htc', 'est', 'dna', 'rna', 'other'];
  }

  get dataTypeIsFulfilled() {
    switch (this.dataType) {
      case 'other':
        return isPresent(this.dataTypeOtherText);
      case 'wgs_version_up':
        return isPresent(this.accessionNumber);
      default:
        return this.dataTypes.includes(this.dataType);
    }
  }

  toPayload() {
    return toPayload(this, [
      'tpa',
      'sequencer',
      'dfast',
      'dataType',
      'dataTypeOtherText',
      'accessionNumber',
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
