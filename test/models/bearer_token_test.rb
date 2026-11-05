require 'test_helper'

class BearerTokenTest < ActiveSupport::TestCase
  def verify(token)
    BearerToken.verify(token:)
  end

  def assert_invalid(token)
    assert_raises(BearerToken::Invalid) { verify token }
  end

  test 'verifies a valid token' do
    stub_jwks!

    claims = verify(bearer_token_for('alice'))

    assert_equal 'alice',             claims['preferred_username']
    assert_equal 'alice@example.com', claims['email']
  end

  test 'accepts an audience given as a string' do
    stub_jwks!

    assert_equal 'alice', verify(bearer_token_for('alice', aud: 'mssform'))['preferred_username']
  end

  test 'rejects a token from another issuer' do
    stub_jwks!

    assert_invalid bearer_token_for('alice', iss: 'http://keycloak.example.com/realms/other')
  end

  test 'rejects an expired token' do
    stub_jwks!

    assert_invalid bearer_token_for('alice', exp: 1.minute.ago.to_i)
  end

  test 'tolerates 30 seconds of clock skew on exp' do
    stub_jwks!

    assert_equal 'alice', verify(bearer_token_for('alice', exp: 10.seconds.ago.to_i))['preferred_username']
  end

  test 'rejects a token without exp' do
    stub_jwks!

    assert_invalid bearer_token_for('alice', exp: nil)
  end

  test 'rejects a token not yet valid' do
    stub_jwks!

    assert_invalid bearer_token_for('alice', nbf: 5.minutes.from_now.to_i)
  end

  test 'rejects a token not meant for us' do
    stub_jwks!

    assert_invalid bearer_token_for('alice', aud: ['account'])
    assert_invalid bearer_token_for('alice', aud: nil)
  end

  test 'rejects a token issued to a client we do not trust' do
    stub_jwks!

    assert_invalid bearer_token_for('alice', azp: 'dfast')
    assert_invalid bearer_token_for('alice', azp: nil)
  end

  test 'rejects every token, without asking the realm, when no client is trusted' do
    stub_jwks!

    keycloak = Rails.application.config_for(:keycloak).dup.tap { it.bearer_client_ids = [] }

    # A lambda: OrderedOptions answers to #call, so stub would call it instead.
    Rails.application.stub :config_for, ->(*) { keycloak } do
      error = assert_invalid(bearer_token_for('alice'))

      assert_match(/client/i, error.message)
    end

    assert_not_requested :get, BearerTokenHelper::JWKS_URL
  end

  test 'rejects an ID token' do
    stub_jwks!

    assert_invalid bearer_token_for('alice', typ: 'ID')
    assert_invalid bearer_token_for('alice', typ: nil)
  end

  test 'rejects a token without the mss-submission scope' do
    stub_jwks!

    assert_invalid bearer_token_for('alice', scope: nil)
    assert_invalid bearer_token_for('alice', scope: 'openid email profile')
    assert_invalid bearer_token_for('alice', scope: 'openid mss-submission-extra')
    assert_invalid bearer_token_for('alice', scope: ['mss-submission'])
  end

  test 'rejects a service account token' do
    stub_jwks!

    # Keycloak issues these with no user session behind them, hence no sid.
    assert_invalid bearer_token_for('service-account-ggs', sid: nil)
    assert_invalid bearer_token_for('alice', sid: '')
  end

  test 'rejects a token signed by a key the realm does not publish' do
    stub_jwks!

    # Valid in every other respect, and under the kid of a published key.
    assert_invalid bearer_token_for('alice', jwk: bearer_test_jwk(:impostor))
  end

  test 'keeps a long kid or alg out of the reason' do
    long_kid  = 'k' * 1000
    published = JWT::JWK.new(bearer_test_jwk.signing_key, kid: long_kid)
    impostor  = JWT::JWK.new(bearer_test_jwk(:impostor).signing_key, kid: long_kid)
    unknown   = JWT::JWK.new(bearer_test_jwk(:impostor).signing_key, kid: 'u' * 1000)

    stub_jwks! [published]

    # Otherwise valid tokens: one under a published kid but signed with another
    # key, one under a kid the realm does not publish.
    [impostor, unknown].each do |jwk|
      error = assert_invalid(bearer_token_for('alice', jwk:))

      assert_operator error.message.length, :<, 300
    end

    error = assert_invalid(JWT.encode({preferred_username: 'alice'}, 'secret', 'HS256', alg: 'a' * 1000))

    assert_operator error.message.length, :<, 300
  end

  test 'rejects an unsigned or HS256 token without asking the realm' do
    stub_jwks!

    claims = {
      iss:                BearerTokenHelper::ISSUER,
      aud:                ['mssform'],
      azp:                'ggs-test',
      typ:                'Bearer',
      scope:              'mss-submission',
      sid:                'a-user-session',
      exp:                5.minutes.from_now.to_i,
      preferred_username: 'alice'
    }

    unsigned = JWT.encode(claims, nil, 'none', kid: bearer_test_jwk.kid)

    # Signed with what an attacker could read off the JWKS: the public key.
    hs256 = JWT.encode(claims, bearer_test_jwk.verify_key.to_pem, 'HS256', kid: bearer_test_jwk.kid)

    assert_invalid unsigned
    assert_invalid hs256

    assert_not_requested :get, BearerTokenHelper::JWKS_URL
  end

  test 'rejects a tampered payload' do
    stub_jwks!

    header, _payload, signature = bearer_token_for('alice').split('.')
    _, payload, _               = bearer_token_for('mallory').split('.')

    assert_invalid [header, payload, signature].join('.')
  end

  test 'rejects a blank username' do
    stub_jwks!

    ['', '  ', nil].each do |username|
      assert_invalid bearer_token_for('alice', preferred_username: username)
    end
  end

  test 'rejects malformed tokens' do
    stub_jwks!

    ['', 'garbage', 'a.b.c', 'e30.e30.', "#{Base64.urlsafe_encode64('"str"')}.e30.x", nil].each do |token|
      assert_invalid token
    end
  end

  test 'the reason does not carry the token' do
    stub_jwks!

    token = bearer_token_for('alice', azp: 'dfast')
    error = assert_invalid(token)

    assert_not_includes error.message, token
    token.split('.').each {|part| assert_not_includes error.message, part }
  end

  test 'serves known keys from the cache' do
    stub_jwks!

    3.times { verify bearer_token_for('alice') }

    assert_requested :get, BearerTokenHelper::JWKS_URL, times: 1
  end

  test 'refetches the keys after an hour' do
    stub_jwks!

    verify bearer_token_for('alice')

    travel 61.minutes do
      verify bearer_token_for('alice')
    end

    assert_requested :get, BearerTokenHelper::JWKS_URL, times: 2
  end

  test 'refetches the keys for a kid it has not seen' do
    stub_jwks! [bearer_test_jwk], [bearer_test_jwk, bearer_test_jwk(:other)]

    verify bearer_token_for('alice')

    travel 61.seconds do
      assert_equal 'alice', verify(bearer_token_for('alice', jwk: bearer_test_jwk(:other)))['preferred_username']
    end

    assert_requested :get, BearerTokenHelper::JWKS_URL, times: 2
  end

  test 'asks the realm once with nothing cached, even for a kid it does not publish' do
    stub_jwks!

    assert_invalid bearer_token_for('alice', jwk: bearer_test_jwk(:other))

    assert_requested :get, BearerTokenHelper::JWKS_URL, times: 1
  end

  test 'does not refetch within 60 seconds' do
    stub_jwks!

    unknown = bearer_token_for('alice', jwk: bearer_test_jwk(:other))

    3.times { assert_invalid unknown }

    assert_requested :get, BearerTokenHelper::JWKS_URL, times: 1

    travel 61.seconds do
      assert_invalid bearer_token_for('alice', jwk: bearer_test_jwk(:other))
    end

    assert_requested :get, BearerTokenHelper::JWKS_URL, times: 2
  end

  test 'keeps the cached keys when the realm cannot be reached to refresh them' do
    stub_request(:get, BearerTokenHelper::JWKS_URL).to_return(
      status:  200,
      headers: {'Content-Type' => 'application/json'},
      body:    JWT::JWK::Set.new([bearer_test_jwk]).export.to_json
    ).then.to_timeout

    verify bearer_token_for('alice')

    travel 61.minutes do
      assert_equal 'alice', verify(bearer_token_for('alice'))['preferred_username']
    end

    assert_requested :get, BearerTokenHelper::JWKS_URL, times: 2
  end

  test 'an unreachable realm with nothing cached is invalid' do
    stub_request(:get, BearerTokenHelper::JWKS_URL).to_timeout

    assert_invalid bearer_token_for('alice')
  end

  test 'a realm answering with an error is invalid' do
    stub_request(:get, BearerTokenHelper::JWKS_URL).to_return(status: 500, body: 'oops')

    assert_invalid bearer_token_for('alice')
  end

  test 'a failed fetch is not retried within 60 seconds' do
    stub_request(:get, BearerTokenHelper::JWKS_URL).to_timeout.then.to_return(
      status:  200,
      headers: {'Content-Type' => 'application/json'},
      body:    JWT::JWK::Set.new([bearer_test_jwk]).export.to_json
    )

    2.times { assert_invalid bearer_token_for('alice') }

    assert_requested :get, BearerTokenHelper::JWKS_URL, times: 1

    travel 61.seconds do
      assert_equal 'alice', verify(bearer_token_for('alice'))['preferred_username']
    end

    assert_requested :get, BearerTokenHelper::JWKS_URL, times: 2
  end
end
