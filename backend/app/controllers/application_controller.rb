class ApplicationController < ActionController::API
  private

  def current_user(token = openid_token_payload)
    if sub = token&.fetch('sub')
      User.find_or_initialize_by(openid_sub: sub).tap {|user|
        user.update! openid_preferred_username: token.fetch('preferred_username')
      }
    else
      nil
    end
  rescue JWT::DecodeError => e
    Rails.logger.error e

    nil
  end

  def require_authentication
    return if token = openid_token_payload and current_user(token)

    render json: {
      error: 'missing token'
    }, status: :unauthorized
  rescue JWT::DecodeError => e
    Rails.logger.error e

    render json: {
      error: e.message
    }, status: :unauthorized
  end

  def openid_token_payload
    @openid_token_payload ||= (
      begin
        return nil unless header = request.headers['Authorization']
        return nil unless token  = /\ABearer (?<token>\S+)\z/.match(header)&.named_captures.fetch('token')

        config               = Rails.root.join('../config/openid-configuration.json').open(&JSON.method(:load))
        algorithms, jwks_uri = config.fetch_values('id_token_signing_alg_values_supported', 'jwks_uri')

        payload, _header = JWT.decode(token, nil, true, algorithms: algorithms, jwks: ->(opts) {
          Rails.cache.fetch(:openid_jwks, force: opts[:invalidate]) {
            HTTP.get(jwks_uri).then {|res|
              raise res.status unless res.status.success?

              res.parse
            }
          }
        })

        payload
      end
    )
  end
end
