import Model, { attr, belongsTo } from '@ember-data/model';

export default class Submission extends Model {
  @belongsTo('person', {async: false}) contactPerson;
  @belongsTo('person', {async: false}) anotherPerson;

  @attr('boolean') tpa;
  @attr('boolean') dfast;
  @attr            files;
  @attr('number')  entriesCount;
  @attr('string')  holdDate;
  @attr('string')  sequencer;
  @attr('string')  dataType;
  @attr('string')  shortTitle;
  @attr('string')  description;
  @attr('string')  emailLanguage;
}
