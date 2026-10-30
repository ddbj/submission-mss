require 'net/http'

# An access token Keycloak issued to another client of the realm we sign users
# in with, carried in an Authorization header by that client on behalf of the
# user. Verified against the realm's published keys; the claims come back only
# for a token that is signed, current, meant for us and issued to a client we
# trust.
class BearerToken
  # The message says why, for the log. It never carries the token, and is not
  # for the response.
  class Invalid < StandardError; end

  ALGORITHM          = 'RS256'
  LEEWAY             = 30.seconds
  JWKS_TTL           = 1.hour
  JWKS_REFETCH_AFTER = 60.seconds
  JWKS_TIMEOUT       = 5 # seconds

  @jwks_mutex = Mutex.new

  class << self
    def verify(token:)
      raise Invalid, 'not a token' unless token.is_a?(String) && token.present?

      header = decode_header(token)

      raise Invalid, "unexpected alg #{header['alg'].inspect}" unless header['alg'] == ALGORITHM

      kid = header['kid']

      raise Invalid, 'no kid' unless kid.is_a?(String) && kid.present?

      keycloak = Rails.application.config_for(:keycloak)
      claims   = decode(token, key_for(kid), keycloak)

      raise Invalid, "untrusted azp #{claims['azp'].inspect}" unless Array(keycloak.bearer_client_ids).include?(claims['azp'])
      raise Invalid, 'blank preferred_username' unless claims['preferred_username'].is_a?(String) && claims['preferred_username'].present?

      claims
    end

    def reset_jwks_cache!
      @jwks_mutex.synchronize do
        @jwks              = nil
        @jwks_fetched_at   = nil
        @jwks_refetched_at = nil
      end
    end

    private

    def decode_header(token)
      JWT::EncodedToken.new(token).header.then {
        raise Invalid, 'malformed header' unless it.is_a?(Hash)

        it
      }
    rescue JWT::DecodeError, JSON::ParserError, ArgumentError => e
      raise Invalid, "malformed token (#{e.class})"
    end

    def decode(token, key, keycloak)
      payload, = JWT.decode(token, key, true, {
        algorithms:      [ALGORITHM],
        iss:             issuer,
        verify_iss:      true,
        aud:             keycloak.bearer_audience,
        verify_aud:      true,
        required_claims: %w[exp],
        leeway:          LEEWAY.to_i
      })

      payload
    rescue JWT::DecodeError => e
      raise Invalid, "#{e.class}: #{e.message}"
    end

    def key_for(kid)
      @jwks_mutex.synchronize do
        now = Time.current

        @jwks = nil if @jwks_fetched_at && now - @jwks_fetched_at >= JWKS_TTL
        @jwks ||= fetch_jwks(now)

        jwk = find_key(kid)

        # The realm may have rotated its keys since we last looked; look once
        # more, but not on every token naming a key it does not publish.
        if !jwk && (@jwks_refetched_at.nil? || now - @jwks_refetched_at >= JWKS_REFETCH_AFTER)
          @jwks_refetched_at = now
          @jwks              = fetch_jwks(now)
          jwk                = find_key(kid)
        end

        raise Invalid, "unknown kid #{kid.inspect}" unless jwk

        jwk.verify_key
      end
    end

    def find_key(kid)
      @jwks.find { it[:kid] == kid }
    end

    def fetch_jwks(now)
      uri = URI("#{issuer}/protocol/openid-connect/certs")

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: JWKS_TIMEOUT, read_timeout: JWKS_TIMEOUT, write_timeout: JWKS_TIMEOUT) {|http|
        http.get(uri.request_uri)
      }

      raise Invalid, "JWKS answered #{res.code}" unless res.is_a?(Net::HTTPSuccess)

      keys = JSON.parse(res.body).fetch('keys').select {|key|
        key.is_a?(Hash) && key['kty'] == 'RSA' && key.fetch('use', 'sig') == 'sig'
      }

      JWT::JWK::Set.new(keys: keys).tap {
        @jwks_fetched_at = now
      }
    rescue Invalid
      raise
    rescue StandardError => e
      raise Invalid, "JWKS unavailable (#{e.class})"
    end

    def issuer
      URI.join(Rails.application.config_for(:keycloak).url!, '/realms/master').to_s
    end
  end
end
