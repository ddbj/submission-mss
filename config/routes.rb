Rails.application.routes.draw do
  scope ActiveStorage.routes_prefix do
    post :direct_uploads, to: 'active_storage/direct_uploads#create', as: :rails_direct_uploads
  end

  get '*paths', to: 'frontends#show', constraints: -> (req) {
    !req.xhr? && req.format.html?
  }
end
