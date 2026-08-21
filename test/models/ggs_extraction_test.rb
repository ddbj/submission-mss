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

  test 'prepare_files rejects the same file name coming from two jobs' do
    job_ids = ['01234567-89ab-cdef-0000-000000000001', '01234567-89ab-cdef-0000-000000000002']

    job_ids.each do |job_id|
      dir = output_dir(job_id)

      dir.join('foo.ann').write "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n"
      dir.join('foo.fa').write  ">CLN01\nACGT\n"
    end

    extraction = GgsExtraction.create!(user: users(:alice), ggs_job_ids: job_ids)

    # They sit under their own job here, but the submission they are copied to
    # holds them in one directory.
    error = assert_raises(Extraction::Error) { extraction.prepare_files }

    assert_equal :duplicate_file_name, error.id
    assert_equal job_ids.last, error.data[:job_id]
    assert_equal "duplicate file name: foo.ann (already imported from job #{job_ids.first})", error.data[:reason]

    # The name is turned down before the file it names is copied.
    assert_not extraction.working_dir.join(job_ids.last, 'foo.ann').exist?
  end

  test 'the database refuses the same file name whichever job brought it' do
    extraction = GgsExtraction.create!(user: users(:alice), ggs_job_ids: ['01234567-89ab-cdef-0000-000000000001'])

    extraction.files.create!(name: 'foo.fa', parsing: false, ggs_job_id: '01234567-89ab-cdef-0000-000000000001')

    # prepare_files turns this down first; the index is what stops a path that
    # ever forgets to.
    assert_raises ActiveRecord::RecordNotUnique do
      extraction.files.create!(name: 'foo.fa', parsing: false, ggs_job_id: '01234567-89ab-cdef-0000-000000000002')
    end

    assert_equal 1, extraction.files.count
  end

  test 'prepare_files prefers output/fixed/ over output/ for the same file name' do
    job_id = '01234567-89ab-cdef-0000-000000000001'
    dir    = output_dir(job_id)
    fixed  = dir.join('fixed').tap(&:mkpath)

    dir.join('foo.ann').write   "COMMON\tSUBMITTER\t\tcontact\tOutput\n"
    dir.join('foo.fa').write    ">output\nACGT\n"
    fixed.join('foo.ann').write "COMMON\tSUBMITTER\t\tcontact\tFixed\n"
    fixed.join('foo.fa').write  ">fixed\nACGT\n"

    extraction = GgsExtraction.create!(user: users(:alice), ggs_job_ids: [job_id])
    extraction.prepare_files

    files = extraction.files.order(:name)

    assert_equal %w[foo.ann foo.fa], files.map(&:name)
    assert_equal "COMMON\tSUBMITTER\t\tcontact\tFixed\n", files.first.fullpath.read
    assert_equal ">fixed\nACGT\n",                        files.last.fullpath.read
  end

  test 'prepare_files prefers output/fixed/ when only one of the two is compressed' do
    job_id = '01234567-89ab-cdef-0000-000000000001'
    dir    = output_dir(job_id)
    fixed  = dir.join('fixed').tap(&:mkpath)

    dir.join('foo.fa').write ">output\nACGT\n"

    Zlib::GzipWriter.open(fixed.join('foo.fa.gz')) do |gz|
      gz.write ">fixed\nACGT\n"
    end

    extraction = GgsExtraction.create!(user: users(:alice), ggs_job_ids: [job_id])
    extraction.prepare_files

    # The two are the same file under different names, so taking both would
    # have them collide the moment the compressed one is expanded.
    file = extraction.files.sole

    assert_equal 'foo.fa',         file.name
    assert_equal ">fixed\nACGT\n", file.fullpath.read
  end

  test 'prepare_files prefers output/fixed/ even when the output/ files are read-only' do
    job_id = '01234567-89ab-cdef-0000-000000000001'
    dir    = output_dir(job_id)
    fixed  = dir.join('fixed').tap(&:mkpath)

    dir.join('foo.ann').write   "COMMON\tSUBMITTER\t\tcontact\tOutput\n"
    dir.join('foo.fa').write    ">output\nACGT\n"
    fixed.join('foo.ann').write "COMMON\tSUBMITTER\t\tcontact\tFixed\n"
    fixed.join('foo.fa').write  ">fixed\nACGT\n"

    # GGS job output lives on a shared filesystem and may be read-only.
    [dir, fixed].each {|d| d.each_child { _1.chmod(0o444) if _1.file? } }

    extraction = GgsExtraction.create!(user: users(:alice), ggs_job_ids: [job_id])
    extraction.prepare_files

    files = extraction.files.order(:name)

    assert_equal %w[foo.ann foo.fa], files.map(&:name)
    assert_equal ">fixed\nACGT\n", files.last.fullpath.read
  end

  test 'prepare_files keeps output/ files that have no counterpart under output/fixed/' do
    job_id = '01234567-89ab-cdef-0000-000000000001'
    dir    = output_dir(job_id)
    fixed  = dir.join('fixed').tap(&:mkpath)

    dir.join('a.ann').write   "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n"
    dir.join('a.fa').write    ">output\nACGT\n"
    dir.join('b.ann').write   "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n"
    dir.join('b.fa').write    ">b\nACGT\n"
    fixed.join('a.fa').write  ">fixed\nACGT\n"

    extraction = GgsExtraction.create!(user: users(:alice), ggs_job_ids: [job_id])
    extraction.prepare_files

    files = extraction.files.order(:name)

    assert_equal %w[a.ann a.fa b.ann b.fa], files.map(&:name)
    assert_equal ">fixed\nACGT\n", files.find { _1.name == 'a.fa' }.fullpath.read
    assert_equal ">b\nACGT\n",     files.find { _1.name == 'b.fa' }.fullpath.read
  end

  test 'prepare_files ignores subdirectories other than fixed (e.g. reports)' do
    job_id  = '01234567-89ab-cdef-0000-000000000001'
    dir     = output_dir(job_id)
    reports = dir.join('reports').tap(&:mkpath)

    dir.join('foo.ann').write     "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n"
    dir.join('foo.fa').write      ">foo\nACGT\n"
    reports.join('report.fa').write ">report\nACGT\n"

    extraction = GgsExtraction.create!(user: users(:alice), ggs_job_ids: [job_id])
    extraction.prepare_files

    assert_equal %w[foo.ann foo.fa], extraction.files.order(:name).map(&:name)
  end

  test 'prepare_files accepts the same file set as the SFTP import (fasta, fsa, annt.tsv, gz)' do
    job_id = '01234567-89ab-cdef-0000-000000000001'
    dir    = output_dir(job_id)

    dir.join('a.fasta').write    ">CLN01\nACGT\n"
    dir.join('b.annt.tsv').write "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n"
    dir.join('c.fsa').write      ">CLN02\nACGT\n"

    Zlib::GzipWriter.open(dir.join('d.fa.gz')) do |gz|
      gz.write ">CLN03\nACGT\n"
    end

    extraction = GgsExtraction.create!(user: users(:alice), ggs_job_ids: [job_id])
    extraction.prepare_files

    assert_equal %w[a.fasta b.annt.tsv c.fsa d.fa], extraction.files.order(:name).map(&:name)
  end

  test 'prepare_files rejects files whose names collide after normalization' do
    job_id = '01234567-89ab-cdef-0000-000000000001'
    dir    = output_dir(job_id)

    dir.join('a b.fa').write ">CLN01\nACGT\n"
    dir.join('a_b.fa').write ">CLN02\nACGT\n"

    extraction = GgsExtraction.create!(user: users(:alice), ggs_job_ids: [job_id])

    error = assert_raises Extraction::Error do
      extraction.prepare_files
    end

    assert_equal :duplicate_file_name, error.id
  end

  test 'prepare_files keeps files from different jobs separate' do
    job1 = '01234567-89ab-cdef-0000-000000000001'
    job2 = '01234567-89ab-cdef-0000-000000000002'

    {job1 => 'foo', job2 => 'bar'}.each do |job_id, basename|
      dir = output_dir(job_id)

      dir.join("#{basename}.ann").write "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n"
      dir.join("#{basename}.fa").write  ">CLN01\nACGT\n"
    end

    extraction = GgsExtraction.create!(user: users(:alice), ggs_job_ids: [job1, job2])
    extraction.prepare_files

    assert_equal 4, extraction.files.count
    assert_equal [job1, job1, job2, job2], extraction.files.order(:ggs_job_id, :name).map(&:ggs_job_id)

    assert_equal [job1, job2], extraction.working_dir.children.map { _1.basename.to_s }.sort
    assert extraction.files.all? { _1.fullpath.exist? }
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

  test 'prepare_files rejects a malformed job ID' do
    extraction = GgsExtraction.create!(user: users(:alice), ggs_job_ids: ['not-a-uuid'])

    error = assert_raises Extraction::Error do
      extraction.prepare_files
    end

    assert_equal :invalid_job_id, error.id
  end

  test 'rejects blank job IDs without raising' do
    extraction = GgsExtraction.new(user: users(:alice), ggs_job_ids: nil)

    assert_not extraction.valid?
    assert_includes extraction.errors[:ggs_job_ids], "can't be blank"
  end
end
