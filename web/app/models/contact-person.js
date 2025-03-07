import { tracked } from '@glimmer/tracking';

export default class ContactPerson {
  @tracked email;
  @tracked fullName;
  @tracked affiliation;
}
