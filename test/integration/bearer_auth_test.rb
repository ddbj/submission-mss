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

  def bobs_submission
    bob = User.create!(uid: 'bob', email: 'bob@example.com')

    bob.submissions.create!(
      mass_id:        'NSUB000002',
      tpa:            false,
      entries_count:  1,
      sequencer:      'ngs',
      data_type:      'wgs',
      description:    'bob',
      email_language: 'en'
    )
  end

  def submission_params(extraction)
    {
      submission: {
        tpa:            false,
        upload_via:     'dfast',
        extraction_id:  extraction.id,
        entries_count:  1,
        hold_date:      nil,
        sequencer:      'ngs',
        data_type:      'wgs',
        description:    'test',
        email_language: 'en',

        contact_person: {
          email:       'alice@example.com',
          full_name:   'Alice Liddell',
          affiliation: 'Wonderland Inc.'
        },

        other_people: []
      }
    }
  end

  test 'a token says who it is for' do
    get '/api/me', headers: bearer(users(:alice))

    assert_conform_schema 200
    assert_equal 'alice', response.parsed_body['uid']
  end

  test 'a token stands in for the CSRF token on a GGS import' do
    post '/api/ggs_extractions', params: {
      ids: ['01234567-89ab-cdef-0000-000000000001']
    }, as: :json, headers: bearer(users(:alice))

    assert_conform_schema 201

    extraction = GgsExtraction.find(response.parsed_body['id'])

    assert_equal users(:alice), extraction.user

    get "/api/ggs_extractions/#{extraction.id}", headers: bearer(users(:alice))

    assert_conform_schema 200
  end

  test 'a token makes a submission' do
    extraction = users(:alice).dfast_extractions.create!(dfast_job_ids: ['job-1'], state: 'fulfilled')

    extraction.files.create!(name: 'test.ann', dfast_job_id: 'job-1', parsing: false)

    assert_difference -> { users(:alice).submissions.count } do
      post '/api/submissions', params: submission_params(extraction), as: :json, headers: bearer(users(:alice))
    end

    assert_conform_schema 200

    get "/api/submissions/#{response.parsed_body.dig('submission', 'id')}", headers: bearer(users(:alice))

    assert_conform_schema 200
  end

  test 'a token does not see someone else\'s submission' do
    get "/api/submissions/#{bobs_submission.mass_id}", headers: bearer(users(:alice))

    assert_conform_schema 404
  end

  test 'a token does not upload to someone else\'s submission' do
    submission = bobs_submission
    extraction = submission.user.dfast_extractions.create!(dfast_job_ids: ['job-1'], state: 'fulfilled')

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

  test 'a token makes a direct upload' do
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

  test 'an invalid token makes no direct upload' do
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

  test 'actions not opened to tokens turn a valid one away' do
    WorkingList.instance.stub :collect_statuses_and_accessions, {} do
      get '/api/submissions', headers: bearer(users(:alice))
    end

    assert_conform_schema 401

    get '/api/submissions/last_submitted', headers: bearer(users(:alice))

    assert_conform_schema 401

    assert_no_difference -> { DfastExtraction.count + MassDirectoryExtraction.count } do
      post '/api/dfast_extractions', params: {ids: ['01234567-89ab-cdef-0000-000000000001']}, as: :json, headers: bearer(users(:alice))

      assert_conform_schema 401

      post '/api/mass_directory_extractions', as: :json, headers: bearer(users(:alice))

      assert_conform_schema 401
    end

    get "/api/dfast_extractions/#{dfast_extractions(:alice_dfast_extraction).id}", headers: bearer(users(:alice))

    assert_conform_schema 401

    delete '/api/session', headers: bearer(users(:alice))

    assert_conform_schema 401
  end

  test 'actions not opened to tokens do not fall back to the session' do
    sign_in users(:alice)

    assert_no_difference -> { MassDirectoryExtraction.count } do
      post '/api/mass_directory_extractions', as: :json, headers: bearer(users(:alice))
    end

    assert_conform_schema 401
  end

  test 'a token without the mss-submission scope is turned away' do
    get '/api/me', headers: bearer(users(:alice), scope: 'openid email profile')

    assert_conform_schema 401
  end

  test 'a service account token is turned away' do
    get '/api/me', headers: bearer('service-account-ggs', sid: nil)

    assert_conform_schema 401
    assert_nil User.find_by(uid: 'service-account-ggs')
  end

  test 'a valid token wins over the session cookie that comes with it' do
    sign_in users(:alice)

    get '/api/me', headers: bearer('bob', email: 'bob@example.com')

    assert_conform_schema 200
    assert_equal 'bob', response.parsed_body['uid']
    assert_nil response.headers['Set-Cookie'], 'the session is neither read nor renewed'
  end

  test 'a token for someone new makes them a user' do
    get '/api/me', headers: bearer('newcomer', email: 'n@example.com')

    assert_conform_schema 200
    assert_equal 'n@example.com', User.find_by!(uid: 'newcomer').email
  end

  test 'a token for someone new without an address is turned away' do
    get '/api/me', headers: bearer('newcomer', email: nil)

    assert_conform_schema 401
    assert_nil User.find_by(uid: 'newcomer')
  end

  test 'a Bearer token does not change the address of a user we already know' do
    get '/api/me', headers: bearer(users(:alice), email: 'alice@elsewhere.example.com')

    assert_conform_schema 200
    assert_equal 'alice@example.com', users(:alice).reload.email
  end

  test 'an invalid token does not fall back to the session' do
    sign_in users(:alice)

    get '/api/me', headers: {Authorization: 'Bearer not.a.token'}

    assert_conform_schema 401
  end

  test 'an expired token does not fall back to the session' do
    sign_in users(:alice)

    get '/api/me', headers: bearer(users(:alice), exp: 10.minutes.ago.to_i)

    assert_conform_schema 401
  end

  test 'a token is verified once per request' do
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

  test 'a request with a token sets no session cookie' do
    get '/api/me', headers: bearer(users(:alice))

    assert_response :ok
    assert_nil response.headers['Set-Cookie']
  end

  test 'a signed-in request is as it was' do
    sign_in users(:alice)

    get '/api/me'

    assert_conform_schema 200
    assert_equal 'alice', response.parsed_body['uid']
  end

  test 'another Authorization scheme is left to the session' do
    get '/api/me', headers: {Authorization: 'Basic xxx'}

    assert_conform_schema 401

    sign_in users(:alice)

    get '/api/me', headers: {Authorization: 'Basic xxx'}

    assert_conform_schema 200
  end

  test 'another Authorization scheme does not get past the CSRF check' do
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
