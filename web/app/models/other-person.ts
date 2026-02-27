import { tracked } from '@glimmer/tracking';

export default class OtherPerson {
  @tracked email?: string;
  @tracked fullName?: string;
}
