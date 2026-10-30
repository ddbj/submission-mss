# Tokens the way Keycloak issues them to another client of the same realm, signed
# with keys only the tests know, and the realm's JWKS endpoint answering with the
# public halves of them.
module BearerTokenHelper
  extend ActiveSupport::Concern

  ISSUER   = 'http://keycloak.example.com/realms/master'
  JWKS_URL = "#{ISSUER}/protocol/openid-connect/certs"

  # Generating an RSA key takes long enough to notice; one pair serves the whole run.
  KEYS = {
    primary: JWT::JWK.new(OpenSSL::PKey::RSA.generate(2048), kid: 'test-key-a'),
    other:   JWT::JWK.new(OpenSSL::PKey::RSA.generate(2048), kid: 'test-key-b')
  }.freeze

  included do
    # The JWKS a test stubs is the one the next verification sees.
    setup do
      BearerToken.reset_jwks_cache!
    end
  end

  def bearer_test_jwk(name = :primary)
    KEYS.fetch(name)
  end

  # Claims set to nil in `overrides` are left out of the token.
  def bearer_token_for(user_or_uid, jwk: bearer_test_jwk, **overrides)
    uid   = user_or_uid.respond_to?(:uid) ? user_or_uid.uid : user_or_uid.to_s
    email = user_or_uid.respond_to?(:email) ? user_or_uid.email : "#{uid}@example.com"

    claims = {
      iss:                ISSUER,
      aud:                ['mssform'],
      azp:                'ggs-test',
      exp:                5.minutes.from_now.to_i,
      iat:                Time.current.to_i,
      preferred_username: uid,
      email:
    }.merge(overrides).compact

    JWT.encode(claims, jwk.signing_key, 'RS256', kid: jwk.kid)
  end

  # Each argument is the set of keys one fetch answers with, in order; the last
  # one keeps answering.
  def stub_jwks!(*key_sets)
    key_sets = [[bearer_test_jwk]] if key_sets.empty?

    responses = key_sets.map {|jwks|
      {
        status:  200,
        headers: {'Content-Type' => 'application/json'},
        body:    JWT::JWK::Set.new(jwks).export.to_json
      }
    }

    stub_request(:get, JWKS_URL).to_return(*responses)
  end
end
