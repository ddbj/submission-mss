import Model, { attr } from '@ember-data/model';

export default class Person extends Model {
  @attr fullName;
  @attr email;
  @attr affiliation;
}
