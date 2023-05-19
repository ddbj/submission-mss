import Model, { attr, belongsTo, hasMany } from '@ember-data/model';

export default class Upload extends Model {
  @belongsTo submission;

  @attr         files;
  @attr         dfastJobIds;
  @attr('date') createdAt;
}
