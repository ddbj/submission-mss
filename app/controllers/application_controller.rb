class ApplicationController < ActionController::API
  # The session travels in a cookie now, which the browser attaches to whatever
  # asks. Lax keeps that to our own site, but a sibling under ddbj.nig.ac.jp is
  # our own site as far as the cookie is concerned, so a write has to carry a
  # token only our frontend can have read.
  include ActionController::RequestForgeryProtection

  include Authentication

  protect_from_forgery with: :exception

  # The token is the whole of the protection: the frontend and the API are
  # separate origins outside production, so where a write says it came from
  # tells us nothing we could act on.
  self.forgery_protection_origin_check = false

  before_action :authenticate!

  rescue_from Upload::Malformed do
    head :unprocessable_content
  end
end
