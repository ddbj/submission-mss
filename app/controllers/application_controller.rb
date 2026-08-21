class ApplicationController < ActionController::API
  include Authentication

  before_action :authenticate!

  rescue_from Upload::Malformed do
    head :unprocessable_content
  end
end
