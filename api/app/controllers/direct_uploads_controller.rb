class DirectUploadsController < ActiveStorage::DirectUploadsController
  include Authentication

  skip_forgery_protection only: :create

  before_action :require_authentication
end
