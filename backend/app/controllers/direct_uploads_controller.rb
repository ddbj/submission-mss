class DirectUploadsController < ActiveStorage::DirectUploadsController
  skip_forgery_protection only: :create
end
