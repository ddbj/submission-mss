import { tracked } from '@glimmer/tracking';

import ContactPerson from 'mssform/models/contact-person';
import type OtherPerson from 'mssform/models/other-person';
import type { SubmissionFile } from 'mssform/models/submission-file';

export default class Submission {
  @tracked id?: string;
  @tracked tpa: boolean | null = null;
  @tracked uploadVia?: string;
  @tracked extractionId?: string;
  @tracked files: SubmissionFile[] = [];
  @tracked entriesCount?: number;
  @tracked holdDate?: string;
  @tracked contactPerson = new ContactPerson();
  @tracked otherPeople: OtherPerson[] = [];
  @tracked sequencer?: string;
  @tracked dataType?: string;
  @tracked description?: string;
  @tracked emailLanguage?: string;

  // readonly attributes
  @tracked uploads: string[] = [];
  @tracked status?: string;
  @tracked accessions: string[] = [];
  @tracked createdAt?: string;
}
