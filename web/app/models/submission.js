import { tracked } from '@glimmer/tracking';

import ContactPerson from 'mssform/models/contact-person';

export default class Submission {
  @tracked tpa;
  @tracked uploadVia;
  @tracked extractionId;
  @tracked files = [];
  @tracked entriesCount;
  @tracked holdDate;
  @tracked contactPerson = new ContactPerson();
  @tracked otherPeople = [];
  @tracked sequencer;
  @tracked dataType;
  @tracked description;
  @tracked emailLanguage;

  // readonly attributes
  @tracked uploads = [];
  @tracked status;
  @tracked accessions = [];
  @tracked createdAt;
}
