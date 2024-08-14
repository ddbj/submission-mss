Rails.application.routes.draw do
  root to: redirect("/web")

  scope :api do
    resources :submissions, only: %i(index show create), param: :mass_id do
      collection do
        get :last_submitted
      end

      scope module: :submissions do
        resources :uploads, only: :create
      end
    end

    resources :dfast_extractions,          only: %i(show create)
    resources :mass_directory_extractions, only: %i(show create)

    resources :direct_uploads, only: :create
  end

  namespace 'debug' do
    get :error
  end

  get '*paths', to: 'frontends#show', constraints: -> (req) {
    !req.xhr? && req.format.html?
  }

  direct :submission_upload do |submission|
    "#{ENV.fetch('MSSFORM_URL')}/home/submission/#{submission.mass_id}/upload?locale=#{submission.email_language}"
  end
end
