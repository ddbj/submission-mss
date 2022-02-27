import Model, { attr } from '@ember-data/model';

export default class ContactPerson extends Model {
  @attr email;
  @attr fullName;
  @attr affiliation;
}
