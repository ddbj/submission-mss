import Model, { attr, belongsTo, hasMany } from '@ember-data/model';

export default class Submission extends Model {
  @belongsTo('contact-person', {async: false, inverse: null}) contactPerson;

  @hasMany('other-person', {async: false, inverse: null}) otherPeople;

  @attr('boolean') tpa;
  @attr('string')  uploadVia;
  @attr('number')  extractionId;
  @attr            files;
  @attr('number')  entriesCount;
  @attr('string')  holdDate;
  @attr('string')  sequencer;
  @attr('string')  dataType;
  @attr('string')  description;
  @attr('string')  emailLanguage;

  // readonly attributes
  @hasMany('uploads', {async: false}) uploads;

  @attr('string') status;
  @attr           accessions;
  @attr('date')   createdAt;
}
