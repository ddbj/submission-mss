import { EmbeddedRecordsMixin } from '@ember-data/serializer/rest';

import ApplicationSerializer from 'mssform/serializers/application';

export default class SubmissionSerializer extends ApplicationSerializer.extend(EmbeddedRecordsMixin) {
  attrs = {
    contactPerson: {embedded: 'always'},
    otherPeople:   {embedded: 'always'},

    status:      {serialize: false},
    accession:   {serialize: false},
    createdAt:   {serialize: false},
    fileNames:   {serialize: false},
    dfastJobIds: {serialize: false},
  }
}
