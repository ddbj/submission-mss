import Model, { attr, belongsTo } from '@ember-data/model';

export default class Upload extends Model {
  @belongsTo('submission', { async: true, inverse: 'uploads' }) submission;

  @attr files;
  @attr dfastJobIds;
  @attr('date') createdAt;
}
