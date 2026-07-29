require 'test_helper'

class DfastExtractionTest < ActiveSupport::TestCase
  def zip_with(*names)
    Zip::OutputStream.write_buffer {|io|
      names.each do |name|
        io.put_next_entry name
        io.write "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n"
      end
    }.string
  end

  def stub_fetch(body, &)
    response = Struct.new(:ok, :body).new(true, body)

    Fetch::API.stub(:fetch, ->(*) { response }, &)
  end

  test 'prepare_files copies each zip entry and tags it with the job ID' do
    job1 = '01234567-89ab-cdef-0000-000000000001'
    job2 = '01234567-89ab-cdef-0000-000000000002'

    extraction = DfastExtraction.create!(user: users(:alice), dfast_job_ids: [job1, job2])

    responses = {
      job1 => zip_with('a.ann', 'a.fasta'),
      job2 => zip_with('b.ann', 'b.fasta')
    }

    Fetch::API.stub :fetch, ->(url) { Struct.new(:ok, :body).new(true, responses.fetch(url[%r{download/([^/]+)/}, 1])) } do
      extraction.prepare_files
    end

    assert_equal %w[a.ann a.fasta b.ann b.fasta], extraction.files.order(:name).map(&:name)
    assert_equal [job1, job1, job2, job2],         extraction.files.order(:name).map(&:dfast_job_id)
  end

  test 'prepare_files rejects the same file name coming from two jobs' do
    job1 = '01234567-89ab-cdef-0000-000000000001'
    job2 = '01234567-89ab-cdef-0000-000000000002'

    extraction = DfastExtraction.create!(user: users(:alice), dfast_job_ids: [job1, job2])

    stub_fetch zip_with('SAMD01943820_unspecified.ann') do
      error = assert_raises Extraction::Error do
        extraction.prepare_files
      end

      assert_equal :duplicate_file_name,                              error.id
      assert_equal 'duplicate file name: SAMD01943820_unspecified.ann', error.data[:reason]
    end
  end

  test 'prepare_files rejects when a job download fails' do
    job_id = '01234567-89ab-cdef-0000-000000000001'

    extraction = DfastExtraction.create!(user: users(:alice), dfast_job_ids: [job_id])

    response = Struct.new(:ok, :status, :status_text).new(false, 404, 'Not Found')

    Fetch::API.stub :fetch, ->(*) { response } do
      error = assert_raises Extraction::Error do
        extraction.prepare_files
      end

      assert_equal :failed_to_fetch, error.id
      assert_equal job_id,           error.data[:job_id]
      assert_equal '404 Not Found',  error.data[:reason]
    end
  end

  test 'prepare_files rejects a malformed job ID before building the download URL' do
    # A job ID with an embedded space becomes an invalid download URL and used
    # to crash the job with URI::InvalidURIError (MSSFORM-5Z).
    extraction = DfastExtraction.create!(user: users(:alice), dfast_job_ids: ['838b545-ad30-4c3d-b238-2b42377a13e0 S'])

    error = assert_raises Extraction::Error do
      extraction.prepare_files
    end

    assert_equal :invalid_job_id, error.id
  end
end
