import { tracked } from '@glimmer/tracking';

import ContactPerson from 'mssform/models/contact-person';

import type OtherPerson from 'mssform/models/other-person';

interface Upload {
  id: string;
  createdAt: string;
  files: string[];
  dfastJobIds: string[] | null;
}

export default class Submission {
  @tracked id?: string;
  @tracked tpa?: boolean;
  @tracked uploadVia?: 'webui' | 'dfast' | 'mass_directory';
  @tracked extractionId?: string;
  @tracked files: string[] = [];
  @tracked entriesCount?: number;
  @tracked holdDate?: string;
  @tracked contactPerson = new ContactPerson();
  @tracked otherPeople: OtherPerson[] = [];
  @tracked sequencer?: 'ngs' | 'sanger';
  @tracked dataType?: 'wgs' | 'gnm' | 'mag' | 'sag' | 'tls' | 'htg' | 'tsa' | 'htc' | 'est' | 'misc' | 'ask';
  @tracked description?: string;
  @tracked emailLanguage?: 'ja' | 'en';

  // readonly attributes
  @tracked uploads: Upload[] = [];
  @tracked status?: string;
  @tracked accessions: string[] = [];
  @tracked createdAt?: string;
}
