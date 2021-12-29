import Service from '@ember/service';
import { getOwner } from '@ember/application';
import { inject as service } from '@ember/service';

import {
  AuthorizationRequest,
  AuthorizationServiceConfiguration,
  BaseTokenRequestHandler,
  FetchRequestor,
  GRANT_TYPE_AUTHORIZATION_CODE,
  GRANT_TYPE_REFRESH_TOKEN,
  RedirectRequestHandler,
  TokenRequest,
} from '@openid/appauth';

export default class AppAuthService extends Service {
  @service session;

  get config() {
    return getOwner(this).resolveRegistration('config:environment').appauth;
  }

  get authorizationServiceConfiguration() {
    return new AuthorizationServiceConfiguration(this.config.authorizationServiceConfiguration);
  }

  makeAuthorizationRequest({ redirectUri }) {
    const handler = new RedirectRequestHandler();

    const req = new AuthorizationRequest({
      client_id: this.config.clientId,
      redirect_uri: redirectUri,
      scope: 'openid',
      response_type: AuthorizationRequest.RESPONSE_TYPE_CODE,

      extras: {
        response_mode: 'fragment',
      },
    });

    handler.performAuthorizationRequest(this.authorizationServiceConfiguration, req);
  }

  completeAuthorizationRequest() {
    const handler = new RedirectRequestHandler();

    return handler.completeAuthorizationRequest();
  }

  makeTokenRequestFromAuthorizationCode({ redirectUri, code, codeVerifier }) {
    const handler = new BaseTokenRequestHandler(new FetchRequestor());

    const req = new TokenRequest({
      client_id: this.config.clientId,
      redirect_uri: redirectUri,
      grant_type: GRANT_TYPE_AUTHORIZATION_CODE,
      code,

      extras: {
        code_verifier: codeVerifier,
      },
    });

    return handler.performTokenRequest(this.authorizationServiceConfiguration, req);
  }

  makeTokenRequestFromRefreshToken({ redirectUri, refreshToken }) {
    const handler = new BaseTokenRequestHandler(new FetchRequestor());

    const req = new TokenRequest({
      client_id: this.config.clientId,
      redirect_uri: redirectUri,
      grant_type: GRANT_TYPE_REFRESH_TOKEN,
      refresh_token: refreshToken,
    });

    return handler.performTokenRequest(this.authorizationServiceConfiguration, req);
  }
}
