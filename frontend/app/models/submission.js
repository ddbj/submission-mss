import Model, { attr, belongsTo } from '@ember-data/model';

export default class Submission extends Model {
  @belongsTo('person', {async: false}) contactPerson;
  @belongsTo('person', {async: false}) anotherPerson;

  @attr('boolean') tpa;
  @attr('boolean') dfast;
  @attr            files;
  @attr('number')  entriesCount;
  @attr('date')    holdDate;
  @attr('string')  sequencer;
  @attr('string')  dataType;
  @attr('string')  shortTitle;
  @attr('string')  description;
  @attr('string')  emailLanguage;

  get dataTypes() {
    return this.dfast ? ['wgs', 'complete_genome', 'mag', 'wgs_version_up']
                      : ['wgs', 'complete_genome', 'mag', 'sag', 'wgs_version_up', 'tls', 'htg', 'tsa', 'htc', 'est', 'dna', 'rna', 'other'];
  }
}
