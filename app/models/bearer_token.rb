require 'net/http'

# An access token Keycloak issued to another client of the realm we sign users
# in with, carried in an Authorization header by that client on behalf of the
# user. Verified against the realm's published keys; the claims come back only
# for a token that is signed, current, meant for us, issued to a client we
# trust with the scope that lets it call us, and tied to a user's session.
class BearerToken
  # The message says why, for the log. It never carries the token, and is not
  # for the response.
  class Invalid < StandardError; end

  ALGORITHM         = 'RS256'
  LEEWAY            = 30.seconds
  JWKS_TTL          = 1.hour
  JWKS_MIN_INTERVAL = 60.seconds
  JWKS_TIMEOUT      = 5.seconds
  JWKS_CACHE_KEY    = 'bearer_token/jwks'
  JWKS_FETCHED_KEY  = 'bearer_token/jwks_fetched_recently'

  class << self
    def verify(token:)
      keycloak   = Rails.application.config_for(:keycloak)
      client_ids = Array(keycloak.bearer_client_ids)

      # Off unless some client is trusted; then not even the realm is asked.
      raise Invalid, 'no client is trusted with Bearer tokens' if client_ids.empty?
      raise Invalid, 'not a token' unless token.is_a?(String) && token.present?

      claims = decode(token, keycloak)

      # Keycloak marks its access tokens so; an ID token is meant for the
      # client that signed the user in, not for calling us.
      raise Invalid, "unexpected typ #{claims['typ'].to_s.truncate(64).inspect}" unless claims['typ'] == 'Bearer'
      raise Invalid, "untrusted azp #{claims['azp'].to_s.truncate(64).inspect}" unless client_ids.include?(claims['azp'])
      raise Invalid, "scope #{keycloak.bearer_scope!} not granted" unless scopes(claims).include?(keycloak.bearer_scope!)

      # A service account's token stands for no user, and comes from no
      # user's session.
      raise Invalid, 'no sid' unless present_string?(claims['sid'])
      raise Invalid, 'blank preferred_username' unless present_string?(claims['preferred_username'])

      claims
    end

    private

    def decode(token, keycloak)
      payload, = JWT.decode(token, nil, true, {
        algorithms:      [ALGORITHM],
        jwks:            method(:jwks),
        iss:             keycloak.issuer!,
        verify_iss:      true,
        aud:             keycloak.client_id!,
        verify_aud:      true,
        required_claims: %w[exp],
        leeway:          LEEWAY.to_i
      })

      payload
    rescue JWT::DecodeError, ArgumentError => e
      # The kid, for one, comes from the token and can be as long as it likes.
      raise Invalid, "#{e.class}: #{e.message.truncate(200)}"
    end

    def scopes(claims)
      claims['scope'].is_a?(String) ? claims['scope'].split : []
    end

    def present_string?(value)
      value.is_a?(String) && value.present?
    end

    # The realm's keys, for JWT's key finder, which asks once with the token's
    # kid and, if no key carries it, once more with kid_not_found: true.
    #
    # They are kept in Rails.cache, shared by every process. Whatever the reason
    # to ask the realm -- nothing cached, keys an hour old, a kid we have not
    # seen -- it is asked at most once a minute, by whichever request claims
    # that minute first; everyone else goes on with what is cached rather than
    # wait. Keys that could not be refreshed are kept: the realm being down is
    # no reason to stop trusting what it published.
    def jwks(options)
      cached = Rails.cache.read(JWKS_CACHE_KEY)

      return cached[:jwks] if cached && !options[:kid_not_found] && cached[:fetched_at] > JWKS_TTL.ago
      return cached ? cached[:jwks] : {keys: []} unless claim_fetch

      jwks = fetch_jwks

      Rails.cache.write JWKS_CACHE_KEY, {jwks:, fetched_at: Time.current}

      jwks
    rescue Invalid => e
      raise unless cached

      Rails.logger.warn "#{e.message}; keeping the keys fetched at #{cached[:fetched_at]}"

      cached[:jwks]
    end

    def claim_fetch
      Rails.cache.write(JWKS_FETCHED_KEY, true, expires_in: JWKS_MIN_INTERVAL, unless_exist: true)
    end

    def fetch_jwks
      uri = URI("#{Rails.application.config_for(:keycloak).issuer!}/protocol/openid-connect/certs")

      res = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl:       uri.scheme == 'https',
        open_timeout:  JWKS_TIMEOUT.to_i,
        read_timeout:  JWKS_TIMEOUT.to_i,
        write_timeout: JWKS_TIMEOUT.to_i
      ) {|http|
        http.get(uri.request_uri)
      }

      raise Invalid, "JWKS answered #{res.code}" unless res.is_a?(Net::HTTPSuccess)

      keys = JSON.parse(res.body).fetch('keys').select {|key|
        key.is_a?(Hash) && key['kty'] == 'RSA' && key.fetch('use', 'sig') == 'sig'
      }

      {keys:}
    rescue Invalid
      raise
    rescue StandardError => e
      raise Invalid, "JWKS unavailable (#{e.class})"
    end
  end
end
