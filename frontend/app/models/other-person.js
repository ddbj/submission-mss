import Model, { attr, belongsTo } from '@ember-data/model';

export default class OtherPerson extends Model {
  @belongsTo('submission', {async: false}) submission;

  @attr email;
  @attr fullName;
}
