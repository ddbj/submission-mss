module SignInHelper
  # Signs in the way a submitter does, through the provider callback, so that
  # what the tests carry from there on is the session cookie the application
  # actually issues.
  def sign_in(user)
    visit_provider_callback user

    # Where the frontend reads the token it has to send back on every write.
    # Reading it the same way puts the tests through the protection rather than
    # around it.
    get '/api/me'

    default_headers['X-CSRF-Token'] = response.parsed_body['csrf_token']
  end

  def visit_provider_callback(user)
    OmniAuth.config.mock_auth[:keycloak] = OmniAuth::AuthHash.new(
      provider: 'keycloak',
      uid:      user.uid,

      info: {
        email: user.email
      },

      extra: {
        raw_info: {
          preferred_username: user.uid
        }
      }
    )

    get '/auth/keycloak/callback'
  end
end
