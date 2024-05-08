module Authentication
  private

  def current_user
    return nil           if @current_user == :not_available
    return @current_user if @current_user

    if token = openid_token_payload
      @current_user = User.find_or_initialize_by(openid_sub: token.fetch(:sub)).tap {|user|
        user.update! id_token: token
      }
    else
      @current_user = :not_available
      nil
    end
  rescue JWT::DecodeError => e
    Rails.logger.error e

    @current_user = :not_available
    nil
  end

  def require_authentication
    return if current_user

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
    return nil unless header = request.headers['Authorization']
    return nil unless token  = /\ABearer (?<token>\S+)\z/.match(header)&.named_captures&.fetch('token')

    config = Rails.root.join('../config/openid-configuration.json').open {|f|
      JSON.load(f, nil, symbolize_names: true, create_additions: false)
    }

    algorithms, jwks_uri = config.fetch_values(:id_token_signing_alg_values_supported, :jwks_uri)

    jwks = ->(opts) {
      Rails.cache.fetch(:openid_jwks, force: opts[:invalidate]) {
        HTTP.get(jwks_uri).then {|res|
          raise res.status unless res.status.success?

          res.parse
        }
      }
    }

    payload, _header = JWT.decode(token, nil, true, algorithms:, jwks:, verify_aud: true, aud: ENV.fetch('OPENID_CLIENT_ID'))

    payload.symbolize_keys
  end
end
