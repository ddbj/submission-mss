import { tracked } from '@glimmer/tracking';

export default class ContactPerson {
  @tracked email?: string;
  @tracked fullName?: string;
  @tracked affiliation?: string;
}
