require 'rails_helper'

RSpec.describe 'submissions', type: :request do
  include RSpec::DefaultHttpHeader

  describe 'GET /api/submissions/:id' do
    let(:user) { create(:user, :alice) }

    let(:default_headers) {
      {
        Authorization: 'Bearer TOKEN'
      }
    }

    before do
      expect(JWT).to receive(:decode) {
        [user.id_token, nil]
      }
    end

    example 'normal case' do
      create :submission, id: 42, user: user

      get '/api/submissions/NSUB000042'

      expect(response).to have_http_status(:no_content)
    end

    example 'not found' do
      get '/api/submissions/NSUB000042'

      expect(response).to have_http_status(:not_found)
    end

    example 'upload disabled' do
      submission = create(:submission, id: 42, user: user)
      File.write submission.root_dir.tap(&:mkpath).join('disable-upload'), ''

      get '/api/submissions/NSUB000042'

      expect(response).to have_http_status(:forbidden)
    end
  end
end
