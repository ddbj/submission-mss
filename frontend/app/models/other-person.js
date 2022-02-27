import Model, { attr, belongsTo } from '@ember-data/model';

export default class OtherPerson extends Model {
  @attr email;
  @attr fullName;
}
