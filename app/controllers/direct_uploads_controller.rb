class DirectUploadsController < ActiveStorage::DirectUploadsController
  include Authentication

  before_action :authenticate!
end
