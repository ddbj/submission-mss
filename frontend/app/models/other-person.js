import Model, { attr } from '@ember-data/model';

export default class OtherPerson extends Model {
  @attr email;
  @attr fullName;
}
