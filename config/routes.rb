Rails.application.routes.draw do
  root to: redirect('/web')

  get 'auth/:provider/callback', to: 'sessions#create'
  get 'auth/failure',            to: 'sessions#failure'

  scope :api, defaults: {format: :json} do
    resource :me, only: %i[show]

    resources :submissions, only: %i[index show create], param: :mass_id do
      collection do
        get :last_submitted
      end

      scope module: :submissions do
        resources :uploads, only: :create
      end
    end

    resources :dfast_extractions,          only: %i[show create]
    resources :mass_directory_extractions, only: %i[show create]

    resources :direct_uploads, only: :create
  end

  direct :submission_upload do |submission|
    web_url = Rails.application.config_for(:app).web_url!

    "#{web_url}/home/submission/#{submission.mass_id}/upload?locale=#{submission.email_language}"
  end

  get '*paths', to: 'frontends#show', constraints: ->(req) {
    !req.xhr? && req.format.html?
  }

  get 'up' => 'rails/health#show', as: :rails_health_check
end
