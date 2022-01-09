import { EmbeddedRecordsMixin } from '@ember-data/serializer/rest';

import ActiveModelSerializer from 'active-model-adapter/active-model-serializer';

export default class ApplicationSerializer extends ActiveModelSerializer.extend(EmbeddedRecordsMixin) {
  attrs = {
    contactPerson: {embedded: 'always'},
    anotherPerson: {embedded: 'always'}
  }
}
