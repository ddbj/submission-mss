require 'test_helper'

class BearerTokenTest < ActiveSupport::TestCase
  test 'verifies a valid token' do
    stub_jwks!

    claims = BearerToken.verify(token: bearer_token_for('alice'))

    assert_equal 'alice',             claims['preferred_username']
    assert_equal 'alice@example.com', claims['email']
  end

  test 'accepts a user record' do
    stub_jwks!

    assert_equal 'alice', BearerToken.verify(token: bearer_token_for(users(:alice)))['preferred_username']
  end

  test 'accepts an audience given as a string' do
    stub_jwks!

    assert_equal 'alice', BearerToken.verify(token: bearer_token_for('alice', aud: 'mssform'))['preferred_username']
  end

  test 'rejects wrong issuer' do
    stub_jwks!

    assert_raises BearerToken::Invalid do
      BearerToken.verify token: bearer_token_for('alice', iss: 'http://keycloak.example.com/realms/other')
    end
  end

  test 'rejects expired' do
    stub_jwks!

    assert_raises BearerToken::Invalid do
      BearerToken.verify token: bearer_token_for('alice', exp: 1.minute.ago.to_i)
    end
  end

  test 'tolerates 30 seconds of clock skew on exp' do
    stub_jwks!

    assert_equal 'alice', BearerToken.verify(token: bearer_token_for('alice', exp: 10.seconds.ago.to_i))['preferred_username']
  end

  test 'rejects a token without exp' do
    stub_jwks!

    assert_raises BearerToken::Invalid do
      BearerToken.verify token: bearer_token_for('alice', exp: nil)
    end
  end

  test 'rejects a token not yet valid' do
    stub_jwks!

    assert_raises BearerToken::Invalid do
      BearerToken.verify token: bearer_token_for('alice', nbf: 5.minutes.from_now.to_i)
    end
  end

  test 'rejects missing audience' do
    stub_jwks!

    assert_raises BearerToken::Invalid do
      BearerToken.verify token: bearer_token_for('alice', aud: ['account'])
    end

    assert_raises BearerToken::Invalid do
      BearerToken.verify token: bearer_token_for('alice', aud: nil)
    end
  end

  test 'rejects other client' do
    stub_jwks!

    assert_raises BearerToken::Invalid do
      BearerToken.verify token: bearer_token_for('alice', azp: 'dfast')
    end

    assert_raises BearerToken::Invalid do
      BearerToken.verify token: bearer_token_for('alice', azp: nil)
    end
  end

  test 'rejects every client when none is configured' do
    stub_jwks!

    keycloak = Rails.application.config_for(:keycloak).merge(bearer_client_ids: [])

    Rails.application.stub :config_for, keycloak do
      assert_raises BearerToken::Invalid do
        BearerToken.verify token: bearer_token_for('alice')
      end
    end
  end

  test 'rejects unsigned or hs256' do
    stub_jwks!

    claims = {
      iss:                BearerTokenHelper::ISSUER,
      aud:                ['mssform'],
      azp:                'ggs-test',
      exp:                5.minutes.from_now.to_i,
      preferred_username: 'alice'
    }

    unsigned = JWT.encode(claims, nil, 'none', kid: bearer_test_jwk.kid)

    # Signed with what an attacker could read off the JWKS: the public key.
    hs256 = JWT.encode(claims, bearer_test_jwk.verify_key.to_pem, 'HS256', kid: bearer_test_jwk.kid)

    [unsigned, hs256].each do |token|
      assert_raises BearerToken::Invalid do
        BearerToken.verify token:
      end
    end

    # Turned down on the header alone, before the JWKS is asked.
    assert_not_requested :get, BearerTokenHelper::JWKS_URL
  end

  test 'rejects tampered payload' do
    stub_jwks!

    header, _payload, signature = bearer_token_for('alice').split('.')
    _, payload, _               = bearer_token_for('mallory').split('.')

    assert_raises BearerToken::Invalid do
      BearerToken.verify token: [header, payload, signature].join('.')
    end
  end

  test 'rejects a token signed by a key the realm does not publish' do
    stub_jwks!

    forged = JWT.encode({preferred_username: 'alice'}, OpenSSL::PKey::RSA.generate(2048), 'RS256', kid: bearer_test_jwk.kid)

    assert_raises BearerToken::Invalid do
      BearerToken.verify token: forged
    end
  end

  test 'rejects blank username' do
    stub_jwks!

    ['', '  ', nil].each do |username|
      assert_raises BearerToken::Invalid do
        BearerToken.verify token: bearer_token_for('alice', preferred_username: username)
      end
    end
  end

  test 'rejects malformed tokens' do
    stub_jwks!

    ['', 'garbage', 'a.b.c', nil].each do |token|
      assert_raises BearerToken::Invalid do
        BearerToken.verify token:
      end
    end
  end

  test 'the reason does not carry the token' do
    stub_jwks!

    token = bearer_token_for('alice', azp: 'dfast')
    error = assert_raises(BearerToken::Invalid) { BearerToken.verify token: }

    assert_not_includes error.message, token
    token.split('.').each {|part| assert_not_includes error.message, part }
  end

  test 'refetches jwks once for unknown kid' do
    stub_jwks! [bearer_test_jwk], [bearer_test_jwk, bearer_test_jwk(:other)]

    claims = BearerToken.verify(token: bearer_token_for('alice', jwk: bearer_test_jwk(:other)))

    assert_equal 'alice', claims['preferred_username']
    assert_requested :get, BearerTokenHelper::JWKS_URL, times: 2
  end

  test 'serves known keys from the cache' do
    stub_jwks!

    3.times { BearerToken.verify token: bearer_token_for('alice') }

    assert_requested :get, BearerTokenHelper::JWKS_URL, times: 1
  end

  test 'refetches jwks after an hour' do
    stub_jwks!

    BearerToken.verify token: bearer_token_for('alice')

    travel 61.minutes do
      BearerToken.verify token: bearer_token_for('alice')
    end

    assert_requested :get, BearerTokenHelper::JWKS_URL, times: 2
  end

  test 'does not refetch within 60 seconds' do
    stub_jwks!

    unknown = bearer_token_for('alice', jwk: bearer_test_jwk(:other))

    2.times do
      assert_raises BearerToken::Invalid do
        BearerToken.verify token: unknown
      end
    end

    assert_requested :get, BearerTokenHelper::JWKS_URL, times: 2

    travel 61.seconds do
      assert_raises BearerToken::Invalid do
        BearerToken.verify token: bearer_token_for('alice', jwk: bearer_test_jwk(:other))
      end
    end

    assert_requested :get, BearerTokenHelper::JWKS_URL, times: 3
  end

  test 'jwks unreachable is invalid' do
    stub_request(:get, BearerTokenHelper::JWKS_URL).to_timeout

    assert_raises BearerToken::Invalid do
      BearerToken.verify token: bearer_token_for('alice')
    end
  end

  test 'jwks answering with an error is invalid' do
    stub_request(:get, BearerTokenHelper::JWKS_URL).to_return(status: 500, body: 'oops')

    assert_raises BearerToken::Invalid do
      BearerToken.verify token: bearer_token_for('alice')
    end
  end

  test 'every environment configures the audience and a list of clients' do
    %w[development test production staging].each do |env|
      keycloak = Rails.application.config_for(:keycloak, env:)

      assert_equal 'mssform', keycloak[:bearer_audience], env
      assert_kind_of Array, keycloak[:bearer_client_ids], env
    end
  end
end
