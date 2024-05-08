import Service from '@ember/service';
import { getOwner } from '@ember/application';
import { service } from '@ember/service';

import {
  AuthorizationRequest,
  AuthorizationServiceConfiguration,
  BaseTokenRequestHandler,
  FetchRequestor,
  GRANT_TYPE_AUTHORIZATION_CODE,
  GRANT_TYPE_REFRESH_TOKEN,
  RedirectRequestHandler,
  RevokeTokenRequest,
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

  get redirectUri() {
    return new URL(this.config.redirectPath, location);
  }

  makeAuthorizationRequest(returnTo) {
    const handler = new RedirectRequestHandler();

    const req = new AuthorizationRequest({
      client_id:     this.config.clientId,
      redirect_uri:  this.redirectUri,
      scope:         'openid offline_access',
      response_type: AuthorizationRequest.RESPONSE_TYPE_CODE,

      extras: {
        response_mode: 'fragment',
        prompt:        'login',
        return_to:     returnTo
      },
    });

    handler.performAuthorizationRequest(this.authorizationServiceConfiguration, req);
  }

  async makeTokenRequestFromAuthorizationRequest() {
    const handler = new RedirectRequestHandler();
    const {request, response, error} = await handler.completeAuthorizationRequest();

    if (error) { throw error; }

    return {
      response: await this.makeTokenRequestFromAuthorizationCode(response.code, request.internal.code_verifier),
      returnTo: request.extras.return_to
    };
  }

  async makeTokenRequestFromAuthorizationCode(code, verifier) {
    const handler = new BaseTokenRequestHandler(new FetchRequestor());

    const req = new TokenRequest({
      client_id:    this.config.clientId,
      redirect_uri: this.redirectUri,
      grant_type:   GRANT_TYPE_AUTHORIZATION_CODE,
      code,

      extras: {
        code_verifier: verifier,
      },
    });

    return await handler.performTokenRequest(this.authorizationServiceConfiguration, req);
  }

  async makeTokenRequestFromRefreshToken(refreshToken) {
    const handler = new BaseTokenRequestHandler(new FetchRequestor());

    const req = new TokenRequest({
      client_id:     this.config.clientId,
      redirect_uri:  this.redirectUri,
      grant_type:    GRANT_TYPE_REFRESH_TOKEN,
      refresh_token: refreshToken,
    });

    return await handler.performTokenRequest(this.authorizationServiceConfiguration, req);
  }

  async makeRevokeTokenRequest(token, tokenTypeHint) {
    const handler = new BaseTokenRequestHandler(new FetchRequestor());

    const req = new RevokeTokenRequest({
      client_id:       this.config.clientId,
      token,
      token_type_hint: tokenTypeHint,
    });

    return await handler.performRevokeTokenRequest(this.authorizationServiceConfiguration, req);
  }
}
