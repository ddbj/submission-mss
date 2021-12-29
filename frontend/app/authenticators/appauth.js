import { inject as service } from '@ember/service';

import BaseAuthenticator from 'ember-simple-auth/authenticators/base';

const redirectUri = new URL('/auth/callback', location);

export default class AppAuthAuthenticator extends BaseAuthenticator {
  @service appauth;

  async restore(data) {
    return data;
  }

  async authenticate({redirectUri, complete}) {
    if (complete) {
      const {request, response, error} = await this.appauth.completeAuthorizationRequest();

      if (error) { throw error; }

      return this.appauth.makeTokenRequestFromAuthorizationCode({
        redirectUri:  new URL('/auth/callback', location),
        code:         response.code,
        codeVerifier: request.internal.code_verifier,
      });
    } else {
      this.appauth.makeAuthorizationRequest({redirectUri});
    }
  }

  async invalidate(data) {
    // TODO revoke token
  }
}
