class ApplicationController < ActionController::API
  private

  def current_user(token = openid_token_payload)
    if sub = token&.fetch('sub')
      User.find_or_create_by!(openid_sub: sub)
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
    render json: {
      error: e.message
    }, status: :unauthorized
  end

  def openid_token_payload
    @openid_token_payload ||= (
      begin
        return nil unless header = request.headers['Authorization']
        return nil unless token  = /\ABearer (?<token>\S+)\z/.match(header)&.named_captures.fetch('token')

        payload, _header = JWT.decode(token, nil, true, algorithm: ENV.fetch('OIDC_SIG_ALGORITHM'), jwks: ->(opts) {
          Rails.cache.fetch(:openid_jwks, force: opts[:invalidate]) {
            HTTP.get("#{ENV.fetch('OIDC_HOST')}#{ENV.fetch('OIDC_JWKS_ENDPOINT')}").parse
          }
        })

        payload
      end
    )
  end
end

$stdout.sync = true
