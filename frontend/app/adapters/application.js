import ActiveModelAdapter from 'active-model-adapter';
import { service } from '@ember/service';

export default class ApplicationAdapter extends ActiveModelAdapter {
  @service session;

  namespace = '/api';

  get headers() {
    if (!this.session.isAuthenticated) { throw new Error('unauthenticated'); }

    return {
      Authorization: `Bearer ${this.session.data.authenticated.id_token}`
    };
  }
}
