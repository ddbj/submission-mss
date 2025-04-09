class DirectUploadsController < ActiveStorage::DirectUploadsController
  include Authentication

  skip_forgery_protection only: :create

  before_action :authenticate!
end
