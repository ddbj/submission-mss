require 'test_helper'

class UploadTest < ActiveSupport::TestCase
  setup do
    @submission = submissions(:alice_submission)
  end

  def upload_at(time)
    @submission.uploads.create!(via: WebuiUpload.new, created_at: time)
  end

  test 'build_via turns down a way of uploading we do not have' do
    ['sftp', '', nil].each do |via|
      assert_raises Upload::Malformed do
        Upload.build_via(via:, user: users(:alice))
      end
    end
  end

  test 'the directory is named after the moment the files arrived' do
    assert_equal '20220304-010203', upload_at('2022-03-04 01:02:03').files_dir_name
  end

  test 'a second upload in the same second is told apart by a suffix' do
    first  = upload_at('2022-03-04 01:02:03')
    second = upload_at('2022-03-04 01:02:03')
    third  = upload_at('2022-03-04 01:02:03')

    # The moment stays legible -- it is what the curator sheet gives as the
    # arrival date -- and no upload is handed a directory another already has.
    assert_equal %w[20220304-010203 20220304-010203-1 20220304-010203-2],
                 [first, second, third].map(&:files_dir_name)

    assert_equal 3, [first, second, third].map(&:files_dir).uniq.size
  end

  test 'the same second under another submission is not a clash' do
    other = Submission.create!(
      mass_id:        'NSUB000042',
      user:           users(:alice),
      tpa:            false,
      entries_count:  1,
      sequencer:      'ngs',
      data_type:      'wgs',
      email_language: 'en',

      contact_person: ContactPerson.new(
        email:       'alice+contact@example.com',
        full_name:   'Alice Liddell',
        affiliation: 'Wonderland Inc.'
      )
    )

    upload_at '2022-03-04 01:02:03'

    assert_equal '20220304-010203', other.uploads.create!(via: WebuiUpload.new, created_at: '2022-03-04 01:02:03').files_dir_name
  end

  test 'the name cannot be changed once it has been handed out' do
    upload = upload_at('2022-03-04 01:02:03')

    # It is in the curator sheet, in the upload log, and in the mail that sends
    # them to it. Moving it afterwards would move nothing but the record of it.
    assert_raises ActiveRecord::ReadonlyAttributeError do
      upload.update! files_dir_name: 'somewhere-else'
    end

    assert_equal '20220304-010203', upload.reload.files_dir_name
  end

  test 'the submission is held while the name is settled' do
    statements = []

    subscriber = ->(*, payload) { statements << payload[:sql] }

    ActiveSupport::Notifications.subscribed subscriber, 'sql.active_record' do
      upload_at '2022-03-04 01:02:03'
    end

    # Two uploads arriving at once would otherwise both find the same name
    # free, and the second would be turned away by the index rather than given
    # a directory of its own. Not reachable from a test that runs in one
    # transaction, so what is asked for is that it is asked for.
    assert statements.any? { _1.match?(/FROM "submissions".+FOR UPDATE/m) }, 'the submission is not locked'
  end

  test 'the database refuses two uploads of one submission the same directory' do
    upload_at '2022-03-04 01:02:03'

    assert_raises ActiveRecord::RecordNotUnique do
      Upload.insert!({
        submission_id:  @submission.id,
        via_type:       'WebuiUpload',
        via_id:         WebuiUpload.create!.id,
        files_dir_name: '20220304-010203',
        created_at:     Time.current,
        updated_at:     Time.current
      })
    end
  end
end
