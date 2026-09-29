require 'test_helper'

class SessionsTest < ActionDispatch::IntegrationTest
  ISSUER = URI.join(Rails.application.config_for(:keycloak).url!, '/realms/master').to_s

  test 'signing in leaves the credential in the cookie and nowhere else' do
    visit_provider_callback users(:alice)

    # It used to travel in the query string, where the browser keeps it in
    # history and everything in front of us writes it down. Now the redirect
    # carries nothing at all.
    assert_equal Rails.application.config_for(:app).web_url!, response.headers['Location']

    cookie = response.headers['Set-Cookie']

    assert_match(/\A_mssform=/, cookie)
    assert_match(/httponly/,    cookie)
    assert_match(/samesite=lax/, cookie)
    assert_match(/expires=/,    cookie, 'the session says how long it is good for')

    get '/api/me'

    assert_conform_schema 200
    assert_equal users(:alice).uid, response.parsed_body['uid']
  end

  # Everywhere else the sign-in is mocked up to the callback. Here it goes to
  # the identity provider for real, up to reading how to reach it -- which a
  # JSON gem that Faraday called the wrong way once broke, unnoticed until
  # nobody could sign in.
  test 'signing in starts at the identity provider' do
    stub_discovery

    without_omniauth_test_mode do
      post '/auth/keycloak'
    end

    assert_response :redirect
    assert_match %r{\A#{Regexp.escape(ISSUER)}/protocol/openid-connect/auth\?}, response.headers['Location']
  end

  # And here all the way: the code exchanged for tokens, the ID token checked
  # against the provider's keys, the user read from userinfo. Nothing else in
  # the tests goes past the callback's mock.
  test 'signing in through the identity provider' do
    key = JSON::JWK.new(OpenSSL::PKey::RSA.generate(2048), kid: 'provider')

    stub_discovery
    stub_provider_keys key

    without_omniauth_test_mode do
      state, nonce = start_signing_in

      stub_tokens id_token(key, nonce:)
      stub_userinfo users(:alice)

      get '/auth/keycloak/callback', params: {code: 'the-code', state:}
    end

    assert_equal Rails.application.config_for(:app).web_url!, response.headers['Location']
    assert_requested :post, "#{ISSUER}/protocol/openid-connect/token", body: hash_including(code: 'the-code')

    get '/api/me'

    assert_conform_schema 200
    assert_equal users(:alice).uid, response.parsed_body['uid']
  end

  test 'an ID token the provider did not sign is not taken' do
    key = JSON::JWK.new(OpenSSL::PKey::RSA.generate(2048), kid: 'provider')

    stub_discovery
    stub_provider_keys key

    assert_error_reported JSON::JWS::VerificationFailed do
      without_omniauth_test_mode do
        state, nonce = start_signing_in

        # Signed with another key under the provider's key ID.
        stub_tokens id_token(JSON::JWK.new(OpenSSL::PKey::RSA.generate(2048), kid: 'provider'), nonce:)
        stub_userinfo users(:alice)

        get '/auth/keycloak/callback', params: {code: 'the-code', state:}
      end
    end

    get '/api/me'

    assert_conform_schema 401
  end

  test 'a sign-in that fails on our side is reported, and goes back quietly' do
    stub_request(:get, "#{ISSUER}/.well-known/openid-configuration").to_return(status: 503)

    assert_error_reported OpenIDConnect::Discovery::DiscoveryFailed do
      without_omniauth_test_mode do
        post '/auth/keycloak'
      end
    end

    # Not by way of a URL carrying what went wrong, which can be longer than
    # the proxy in front of us will pass on.
    assert_equal Rails.application.config_for(:app).web_url!, response.headers['Location']
  end

  test 'a sign-in that does not survive the round trip is reported' do
    # Back at the callback with no state to match: the session set on the way
    # out did not come back with the submitter.
    assert_error_reported OmniAuth::Strategies::OpenIDConnect::CallbackError do
      without_omniauth_test_mode do
        get '/auth/keycloak/callback', params: {code: 'whatever', state: 'whatever'}
      end
    end

    assert_equal Rails.application.config_for(:app).web_url!, response.headers['Location']
  end

  test 'a sign-in the submitter turns down is not reported' do
    assert_no_error_reported do
      without_omniauth_test_mode do
        get '/auth/keycloak/callback', params: {error: 'access_denied'}
      end
    end

    assert_equal Rails.application.config_for(:app).web_url!, response.headers['Location']

    get '/api/me'

    assert_conform_schema 401
  end

  test 'signing out' do
    sign_in users(:alice)

    delete '/api/session'

    assert_conform_schema 204

    get '/api/me'

    assert_conform_schema 401
  end

  test 'a request nobody is signed in for' do
    get '/api/me'

    assert_conform_schema 401
  end

  test 'a write that does not carry the token back' do
    sign_in users(:alice)

    default_headers.delete 'X-CSRF-Token'

    # The cookie rides along on its own, so this is what stands between a
    # sibling site under ddbj.nig.ac.jp and a submission made in Alice's name.
    delete '/api/session'

    assert_conform_schema 422
  end

  test 'a session that has run out' do
    sign_in users(:alice)

    travel 13.hours do
      get '/api/me'

      assert_conform_schema 401
    end
  end

  test 'a write from a session that has gone' do
    sign_in users(:alice)

    # What a form left open across an expiry sends: a token that was good, and
    # nothing to check it against.
    reset!

    delete '/api/session', headers: {'X-CSRF-Token' => 'a token from a session that has since gone'}

    # Nobody, rather than something we could not process: only one of those
    # tells the submitter to sign in again.
    assert_conform_schema 401
  end

  test 'signing in leaves nothing of an earlier session to spend' do
    sign_in users(:alice)

    # The unmasked token, not the one /me hands out: that is masked afresh on
    # every read, and would differ within one session too.
    was = session[:_csrf_token]

    sign_in users(:alice)

    assert_not_equal was, session[:_csrf_token], 'whatever the visitor arrived holding is not carried over'
  end

  private

  def stub_discovery
    stub_request(:get, "#{ISSUER}/.well-known/openid-configuration").to_return(
      headers: {'Content-Type' => 'application/json'},

      body: {
        issuer:                                ISSUER,
        authorization_endpoint:                "#{ISSUER}/protocol/openid-connect/auth",
        token_endpoint:                        "#{ISSUER}/protocol/openid-connect/token",
        userinfo_endpoint:                     "#{ISSUER}/protocol/openid-connect/userinfo",
        jwks_uri:                              "#{ISSUER}/protocol/openid-connect/certs",
        response_types_supported:              %w[code],
        subject_types_supported:               %w[public],
        id_token_signing_alg_values_supported: %w[RS256]
      }.to_json
    )
  end

  def stub_provider_keys(key)
    stub_request(:get, "#{ISSUER}/protocol/openid-connect/certs").to_return(
      headers: {'Content-Type' => 'application/json'},
      body:    JSON::JWK::Set.new(key.to_key.public_key.to_jwk(kid: key[:kid])).to_json
    )
  end

  # The state and nonce the provider is sent to bring back.
  def start_signing_in
    post '/auth/keycloak'

    params = Rack::Utils.parse_query(URI.parse(response.headers['Location']).query)

    params.values_at('state', 'nonce')
  end

  def id_token(key, nonce:)
    JSON::JWT.new(
      iss:   ISSUER,
      sub:   'the-subject',
      aud:   Rails.application.config_for(:keycloak).client_id,
      iat:   Time.current.to_i,
      exp:   1.hour.from_now.to_i,
      nonce:
    ).sign(key, :RS256).to_s
  end

  def stub_tokens(id_token)
    stub_request(:post, "#{ISSUER}/protocol/openid-connect/token").to_return(
      headers: {'Content-Type' => 'application/json'},

      body: {
        access_token: 'the-access-token',
        token_type:   'Bearer',
        expires_in:   300,
        id_token:
      }.to_json
    )
  end

  def stub_userinfo(user)
    stub_request(:get, "#{ISSUER}/protocol/openid-connect/userinfo").to_return(
      headers: {'Content-Type' => 'application/json'},

      body: {
        sub:                'the-subject',
        preferred_username: user.uid,
        email:              user.email
      }.to_json
    )
  end

  def without_omniauth_test_mode
    OmniAuth.config.test_mode = false

    yield
  ensure
    OmniAuth.config.test_mode = true
  end
end
