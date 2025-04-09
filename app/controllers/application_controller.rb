class ApplicationController < ActionController::API
  include Authentication

  before_action :authenticate!
end
