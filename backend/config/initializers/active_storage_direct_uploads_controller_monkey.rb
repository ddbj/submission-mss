module ActiveStorageDirectUploadsControllerMonkey
  # Disable service switching to avoid dependency on the session.
  # https://github.com/rails/rails/issues/43971
  def verified_service_name
    Rails.application.config.active_storage.service
  end
end

Rails.application.config.to_prepare do
  ActiveStorage::DirectUploadsController.skip_forgery_protection only: %i(create)

  ActiveStorage::DirectUploadsController.prepend ActiveStorageDirectUploadsControllerMonkey
end
