require 'test_helper'

class GgsExtractionTest < ActiveSupport::TestCase
  setup do
    base = Rails.application.config_for(:app).ggs_jobs_dir_template!.split('{job_id}').first

    FileUtils.rm_rf base
  end

  def output_dir(job_id)
    Rails.application.config_for(:app).ggs_jobs_dir_template!.gsub('{job_id}', job_id).then {|path|
      Pathname.new(path).tap(&:mkpath)
    }
  end

  test 'prepare_files copies .ann/.fa pairs and tags them with the job ID' do
    job_id = '01234567-89ab-cdef-0000-000000000001'
    dir    = output_dir(job_id)

    dir.join('foo.ann').write "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n"
    dir.join('foo.fa').write  ">CLN01\nACGT\n"
    dir.join('readme.txt').write 'ignored'

    extraction = GgsExtraction.create!(user: users(:alice), ggs_job_ids: [job_id])
    extraction.prepare_files

    files = extraction.files.order(:name)

    assert_equal %w[foo.ann foo.fa], files.map(&:name)
    assert_equal [job_id, job_id],   files.map(&:ggs_job_id)
    assert files.all? { _1.fullpath.exist? }
  end

  test 'prepare_files keeps files from different jobs separate' do
    job1 = '01234567-89ab-cdef-0000-000000000001'
    job2 = '01234567-89ab-cdef-0000-000000000002'

    [job1, job2].each do |job_id|
      dir = output_dir(job_id)

      dir.join('genome.ann').write "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n"
      dir.join('genome.fa').write  ">CLN01\nACGT\n"
    end

    extraction = GgsExtraction.create!(user: users(:alice), ggs_job_ids: [job1, job2])
    extraction.prepare_files

    assert_equal 4, extraction.files.count
    assert_equal [job1, job1, job2, job2], extraction.files.order(:ggs_job_id, :name).map(&:ggs_job_id)
  end

  test 'prepare_files raises when the job output directory is missing' do
    extraction = GgsExtraction.create!(user: users(:alice), ggs_job_ids: ['01234567-89ab-cdef-0000-000000000099'])

    error = assert_raises Extraction::Error do
      extraction.prepare_files
    end

    assert_equal :directory_not_found, error.id
  end

  test 'prepare_files processes a duplicated job ID only once' do
    job_id = '01234567-89ab-cdef-0000-000000000001'
    dir    = output_dir(job_id)

    dir.join('foo.ann').write "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n"
    dir.join('foo.fa').write  ">CLN01\nACGT\n"

    extraction = GgsExtraction.create!(user: users(:alice), ggs_job_ids: [job_id, job_id])
    extraction.prepare_files

    assert_equal %w[foo.ann foo.fa], extraction.files.order(:name).map(&:name)
  end

  test 'rejects non-UUID job IDs' do
    extraction = GgsExtraction.new(user: users(:alice), ggs_job_ids: ['not-a-uuid'])

    assert_not extraction.valid?
    assert_includes extraction.errors[:ggs_job_ids], 'is invalid'
  end

  test 'rejects blank job IDs without raising' do
    extraction = GgsExtraction.new(user: users(:alice), ggs_job_ids: nil)

    assert_not extraction.valid?
    assert_includes extraction.errors[:ggs_job_ids], "can't be blank"
  end
end
