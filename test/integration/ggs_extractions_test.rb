require 'test_helper'

class GgsExtractionsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    sign_in users(:alice)
  end

  test 'create' do
    post '/api/ggs_extractions', params: {
      ids: ['01234567-89ab-cdef-0000-000000000001']
    }, as: :json

    assert_conform_schema 201
  end

  # The job's .ggs-owner says who ran it, however the importer signed in.
  test 'importing a job someone else ran is turned down' do
    job_id = '01234567-89ab-cdef-0000-000000000001'
    config = Rails.application.config_for(:app)

    Pathname.new(config.ggs_jobs_dir_template!.gsub('{job_id}', job_id)).tap(&:mkpath).join('foo.fa').write ">CLN01\nACGT\n"
    Pathname.new(config.ggs_owner_template!.gsub('{job_id}', job_id)).write 'bob'

    perform_enqueued_jobs do
      post '/api/ggs_extractions', params: {ids: [job_id]}, as: :json
    end

    assert_conform_schema 201

    get "/api/ggs_extractions/#{response.parsed_body['id']}"

    assert_conform_schema 200
    assert_equal 'rejected',                     response.parsed_body['state']
    assert_equal({'id' => 'not_owner', 'job_id' => job_id}, response.parsed_body['error'])
  end

  test 'show' do
    get "/api/ggs_extractions/#{ggs_extractions(:alice_ggs_extraction).id}"

    assert_conform_schema 200
  end
end
