class DirectUploadsController < ActiveStorage::DirectUploadsController
  include Authentication

  before_action :authenticate!

  allow_bearer only: :create
end
