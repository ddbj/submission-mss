require "rails_helper"

RSpec.describe "submissions", type: :request do
  include RSpec::DefaultHttpHeader

  describe "GET /api/submissions/:mass_id" do
    let(:user)  { create(:user, :alice) }
    let(:token) { JWT.encode({ user_id: user.id }, Rails.application.secret_key_base, "HS512") }

    let(:default_headers) {
      {
        Authorization: "Bearer #{token}",
        Accept:        "application/json"
      }
    }

    example "normal case" do
      create :submission, mass_id: "NSUB000042", user: user

      get "/api/submissions/NSUB000042"

      expect(response).to have_http_status(:ok)
    end

    example "not found" do
      get "/api/submissions/NSUB000042"

      expect(response).to have_http_status(:not_found)
    end

    example "upload disabled" do
      submission = create(:submission, mass_id: "NSUB000042", user: user)
      File.write submission.root_dir.tap(&:mkpath).join("disable-upload"), ""

      get "/api/submissions/NSUB000042"

      expect(response).to have_http_status(:forbidden)
    end
  end
end
