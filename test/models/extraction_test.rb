require 'test_helper'

# Behaviour every extraction shares, exercised through one of them.
class ExtractionTest < ActiveSupport::TestCase
  setup do
    @extraction = DfastExtraction.create!(user: users(:alice), dfast_job_ids: ['job-1'])

    @extraction.working_dir.mkpath
    @extraction.working_dir.join('test.ann').write "COMMON\tSUBMITTER\t\tcontact\tAlice Liddell\n"
    @extraction.files.create!(name: 'test.ann', dfast_job_id: 'job-1', parsing: false)
  end

  test 'discarding the files leaves the extraction' do
    @extraction.discard_files

    assert_not @extraction.working_dir.exist?
    assert_empty @extraction.files.reload
    assert_predicate @extraction.reload, :persisted?
  end

  test 'destroying the extraction takes the files with it' do
    @extraction.destroy!

    # Nothing else knows where they are, so nothing else could come back for
    # them: they would sit under the extracts directory unowned.
    assert_not @extraction.working_dir.exist?
  end

  test 'a directory that could not be removed is not passed over in silence' do
    # rmtree is rm_rf, which reports nothing at all. Without a look afterwards
    # the records would go and leave a directory nothing knows the whereabouts
    # of, and nothing would come back for it.
    FileUtils.stub :rm_rf, nil do
      assert_raises(RuntimeError) { @extraction.discard_files }
    end

    assert_equal 1, @extraction.files.reload.count, 'and the records still say where it is'
  end

  test 'destroying an extraction that gathered nothing' do
    other = DfastExtraction.create!(user: users(:alice), dfast_job_ids: ['job-2'])

    assert_nothing_raised { other.destroy! }
  end
end
