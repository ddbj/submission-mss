import { EmbeddedRecordsMixin } from '@ember-data/serializer/rest';

import ApplicationSerializer from 'mssform-web/serializers/application';

export default class SubmissionSerializer extends ApplicationSerializer.extend(EmbeddedRecordsMixin) {
  attrs = {
    contactPerson: {embedded: 'always'},
    anotherPerson: {embedded: 'always'}
  }
}
