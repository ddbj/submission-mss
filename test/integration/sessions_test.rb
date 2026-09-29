require 'test_helper'

class SessionsTest < ActionDispatch::IntegrationTest
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

  test 'a login the provider turned down' do
    get '/auth/failure'

    assert_equal Rails.application.config_for(:app).web_url!, response.headers['Location']

    get '/api/me'

    assert_conform_schema 401
  end

  private

  ISSUER = 'http://keycloak.example.com/realms/master'

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

  def without_omniauth_test_mode
    OmniAuth.config.test_mode = false

    yield
  ensure
    OmniAuth.config.test_mode = true
  end
end
