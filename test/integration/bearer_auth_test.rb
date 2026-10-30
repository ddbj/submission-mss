require 'test_helper'

# Another client of the realm calling on a submitter's behalf, with the access
# token Keycloak gave it in an Authorization header instead of our session
# cookie.
class BearerAuthTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    stub_jwks!
  end

  def bearer(user_or_uid, **overrides)
    {Authorization: "Bearer #{bearer_token_for(user_or_uid, **overrides)}"}
  end

  test 'bearer get me' do
    get '/api/me', headers: bearer(users(:alice))

    assert_conform_schema 200
    assert_equal 'alice', response.parsed_body['uid']
  end

  test 'bearer post ggs extraction without csrf' do
    post '/api/ggs_extractions', params: {
      ids: ['01234567-89ab-cdef-0000-000000000001']
    }, as: :json, headers: bearer(users(:alice))

    assert_conform_schema 201
    assert_equal users(:alice), GgsExtraction.find(response.parsed_body['id']).user
  end

  test 'bearer_extraction_requires_owner' do
    post '/api/ggs_extractions', params: {
      ids: ['01234567-89ab-cdef-0000-000000000001']
    }, as: :json, headers: bearer(users(:alice))

    assert_conform_schema 201
    assert GgsExtraction.find(response.parsed_body['id']).require_owner
  end

  test 'bearer lists own submissions only' do
    bob = User.create!(uid: 'bob', email: 'bob@example.com')
    bob.submissions.create!(mass_id: 'NSUB000002', tpa: false, entries_count: 1, sequencer: 'ngs', data_type: 'wgs', description: 'bob', email_language: 'en')

    WorkingList.instance.stub :collect_statuses_and_accessions, {} do
      get '/api/submissions', headers: bearer(users(:alice))
    end

    assert_conform_schema 200
    assert_equal %w[NSUB000001], response.parsed_body['submissions'].map { it['id'] }
  end

  test 'bearer upload to others submission is 404' do
    bob        = User.create!(uid: 'bob', email: 'bob@example.com')
    submission = bob.submissions.create!(mass_id: 'NSUB000002', tpa: false, entries_count: 1, sequencer: 'ngs', data_type: 'wgs', description: 'bob', email_language: 'en')
    extraction = bob.dfast_extractions.create!(dfast_job_ids: ['job-1'], state: 'fulfilled')

    extraction.files.create!(name: 'test.ann', dfast_job_id: 'job-1', parsing: false)

    post "/api/submissions/#{submission.mass_id}/uploads", params: {
      upload: {
        via:           'dfast',
        extraction_id: extraction.id
      }
    }, as: :json, headers: bearer(users(:alice))

    assert_conform_schema 404
    assert_no_enqueued_jobs
  end

  test 'bearer creates unknown user' do
    get '/api/me', headers: bearer('newcomer', email: 'n@example.com')

    assert_conform_schema 200
    assert_equal 'n@example.com', User.find_by!(uid: 'newcomer').email
  end

  test 'bearer new user without email is 401' do
    get '/api/me', headers: bearer('newcomer', email: nil)

    assert_conform_schema 401
    assert_nil User.find_by(uid: 'newcomer')
  end

  test 'bearer updates a changed email but keeps it when the claim is absent' do
    get '/api/me', headers: bearer(users(:alice), email: 'alice@new.example.com')

    assert_conform_schema 200
    assert_equal 'alice@new.example.com', users(:alice).reload.email

    get '/api/me', headers: bearer(users(:alice), email: nil)

    assert_conform_schema 200
    assert_equal 'alice@new.example.com', users(:alice).reload.email
  end

  test 'bearer invalid does not fall back to session' do
    sign_in users(:alice)

    get '/api/me', headers: {Authorization: 'Bearer not.a.token'}

    assert_conform_schema 401
  end

  test 'bearer expired does not fall back to session' do
    sign_in users(:alice)

    get '/api/me', headers: bearer(users(:alice), exp: 10.minutes.ago.to_i)

    assert_conform_schema 401
  end

  test 'bearer is verified once per request' do
    calls  = 0
    verify = BearerToken.method(:verify)

    BearerToken.stub :verify, ->(**kw) { calls += 1; verify.(**kw) } do
      post '/api/ggs_extractions', params: {
        ids: ['01234567-89ab-cdef-0000-000000000001']
      }, as: :json, headers: bearer(users(:alice))
    end

    assert_response :created
    assert_equal 1, calls
  end

  test 'bearer request sets no session cookie' do
    get '/api/me', headers: bearer(users(:alice))

    assert_response :ok
    assert_nil response.headers['Set-Cookie']
  end

  test 'bearer direct upload' do
    # The disk service in the tests has no routes to make an upload URL with;
    # the one we are given in production comes from SeaweedFS.
    ActiveStorage::Blob.service.stub :url_for_direct_upload, 'http://storage.example.com/upload' do
      post '/api/direct_uploads', as: :json, headers: bearer(users(:alice)), params: {
        blob: {
          filename:     'test.ann',
          byte_size:    1,
          checksum:     Digest::MD5.base64digest('x'),
          content_type: 'text/plain'
        }
      }
    end

    assert_response :ok
    assert_equal 'http://storage.example.com/upload', response.parsed_body.dig('direct_upload', 'url')
    assert_equal 1, ActiveStorage::Blob.count
    assert_nil response.headers['Set-Cookie']
  end

  test 'bearer direct upload with an invalid token' do
    post '/api/direct_uploads', as: :json, headers: {Authorization: 'Bearer not.a.token'}, params: {
      blob: {
        filename:     'test.ann',
        byte_size:    1,
        checksum:     Digest::MD5.base64digest('x'),
        content_type: 'text/plain'
      }
    }

    assert_response :unauthorized
    assert_equal 0, ActiveStorage::Blob.count
  end

  test 'session auth unchanged' do
    sign_in users(:alice)

    get '/api/me'

    assert_conform_schema 200
    assert_equal 'alice', response.parsed_body['uid']
  end

  test 'wrong scheme is ignored' do
    get '/api/me', headers: {Authorization: 'Basic xxx'}

    assert_conform_schema 401
  end

  test 'wrong scheme does not get past csrf' do
    sign_in users(:alice)

    default_headers.delete 'X-CSRF-Token'

    assert_no_difference -> { GgsExtraction.count } do
      post '/api/ggs_extractions', params: {
        ids: ['01234567-89ab-cdef-0000-000000000001']
      }, as: :json, headers: {Authorization: 'Basic xxx'}
    end

    assert_response :unprocessable_content
  end
end
