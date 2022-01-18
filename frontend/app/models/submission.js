import Model, { attr, belongsTo, hasMany } from '@ember-data/model';

export default class Submission extends Model {
  @belongsTo('contact-person', {async: false}) contactPerson;
  @hasMany('other-person',     {async: false}) otherPeople;

  @attr('boolean') tpa;
  @attr('boolean') dfast;
  @attr            files;
  @attr('number')  entriesCount;
  @attr('string')  holdDate;
  @attr('string')  sequencer;
  @attr('string')  dataType;
  @attr('string')  description;
  @attr('string')  emailLanguage;
}
