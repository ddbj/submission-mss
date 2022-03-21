Rails.application.routes.draw do
  scope :api do
    resources :submissions, only: %i(show create), param: :mass_id do
      collection do
        get :last_submitted
      end

      scope module: :submissions do
        resources :uploads, only: :create
      end
    end

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
