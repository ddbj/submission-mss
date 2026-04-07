require 'test_helper'

class SubmissionMailerTest < ActionMailer::TestCase
  def create_submission(email_language:)
    Submission.create!(
      mass_id:        'NSUB000042',
      user:           users(:alice),
      tpa:            false,
      entries_count:  1,
      sequencer:      'ngs',
      data_type:      'wgs',
      email_language:,

      contact_person: ContactPerson.new(
        email:       'alice+contact@example.com',
        full_name:   'Alice Liddell',
        affiliation: 'Wonderland Inc.'
      ),

      other_people: [
        OtherPerson.new(position: 0, email: 'bob@bar.example.com',   full_name: 'Bob'),
        OtherPerson.new(position: 1, email: 'carol@baz.example.com', full_name: 'Carol')
      ]
    )
  end

  test 'submitter_confirmation: email_language=ja' do
    submission = create_submission(email_language: 'ja')

    mail = SubmissionMailer.with(submission:).submitter_confirmation

    assert_equal ['"DDBJ Mass Submission System (MSS)" <mass@ddbj.nig.ac.jp>'], mail[:from].formatted
    assert_equal ['alice@example.com'], mail.to

    assert_equal [
      'Alice Liddell <alice+contact@example.com>',
      'Bob <bob@bar.example.com>',
      'Carol <carol@baz.example.com>'
    ], mail[:cc].formatted

    assert_equal '[DDBJ:NSUB000042] WGS: Whole Genome Shotgun', mail.subject

    body = mail.body.decoded

    assert_includes body, <<~BODY.chomp
      ご登録者 様

      大規模塩基配列データ登録システム Mass Submission System (MSS) をご利用下さいまして、ありがとうございます。

      私共ではお送りいただいた情報について、国際塩基配列データベース (DDBJ/ENA/GenBank) が定める規則に従い査定作業を行います。
    BODY

    assert_includes body, <<~BODY.chomp
      Submission file の再提出を求められた際は、次の URL から upload してください。
      http://mssform.example.com:4200/home/submission/NSUB000042/upload?locale=ja
    BODY
  end

  test 'submitter_confirmation: email_language=en' do
    submission = create_submission(email_language: 'en')

    mail = SubmissionMailer.with(submission:).submitter_confirmation

    body = mail.body.decoded

    assert_includes body, <<~BODY.chomp
      Dear Submitter,

      Thank you for using DDBJ Mass Submission System (MSS) for large-scale sequence data submission.

      We will check and annotate them on the basis of the manual and rules common to the DDBJ, EMBL-Bank, and GenBank.
    BODY

    assert_includes body, <<~BODY.chomp
      If you are asked for re-submitting the files, upload the submission file(s) from the URL below.
      http://mssform.example.com:4200/home/submission/NSUB000042/upload?locale=en
    BODY
  end

  test 'submitter_confirmation: allowed domains' do
    config = Rails.application.config_for(:app).tap {
      it.mail_allowed_domains = 'example.com,baz.example.com'
    }

    original_config_for = Rails.application.method(:config_for)

    Rails.application.define_singleton_method(:config_for) {|name, **opts|
      name == :app ? config : original_config_for.call(name, **opts)
    }

    submission = create_submission(email_language: 'ja')

    mail = SubmissionMailer.with(submission:).submitter_confirmation

    assert_equal ['"DDBJ Mass Submission System (MSS)" <mass@ddbj.nig.ac.jp>'], mail[:from].formatted
    assert_equal ['alice@example.com'], mail.to

    assert_equal [
      'Alice Liddell <alice+contact@example.com>',
      'Carol <carol@baz.example.com>'
    ], mail[:cc].formatted
  ensure
    Rails.application.define_singleton_method(:config_for, original_config_for)
  end

  test 'curator_notification' do
    submission = Submission.create!(
      mass_id:        'NSUB000042',
      user:           users(:alice),
      created_at:     '2020-01-01',
      description:    'some description',
      sequencer:      'ngs',
      hold_date:      '2020-02-01',
      tpa:            true,
      data_type:      'wgs',
      entries_count:  101,
      email_language: 'ja',

      contact_person: ContactPerson.new(
        email:       'alice+contact@example.com',
        full_name:   'Alice Liddell',
        affiliation: 'Wonderland Inc.'
      ),

      uploads: [
        Upload.new(created_at: '2020-01-02 12:34:56', via: WebuiUpload.new),
        Upload.new(created_at: '2020-01-03 12:34:56', via: WebuiUpload.new)
      ],

      other_people: [
        OtherPerson.new(position: 0, email: 'bob@bar.example.com', full_name: 'Bob'),
        OtherPerson.new(position: 1, email: 'carol@baz.example.com', full_name: 'Carol')
      ]
    )

    mail = SubmissionMailer.with(submission:).curator_notification

    assert_equal ['"DDBJ Mass Submission System (MSS)" <mass@ddbj.nig.ac.jp>'], mail[:from].formatted
    assert_equal ['"DDBJ Mass Submission System (MSS)" <mass@ddbj.nig.ac.jp>'], mail[:to].formatted
    assert_equal '[DDBJ:NSUB000042] WGS: Whole Genome Shotgun',                 mail.subject

    assert_includes mail.body.decoded, <<~BODY.chomp
      ## mass-id
      NSUB000042

      ## mass-id_created date
      2020-01-01

      ## description
      some description

      ## contact_email
      alice+contact@example.com

      ## contact_person_name
      Alice Liddell

      ## contact_institution
      Wonderland Inc.

      ## other_person
      Bob <bob@bar.example.com>; Carol <carol@baz.example.com>

      ## D-way_account
      alice

      ## D-way_account_email
      alice@example.com

      ## data_arrival_date
      20200102-123456: #{Rails.root.join('tmp/storage/submissions/NSUB000042/20200102-123456')}
      20200103-123456: #{Rails.root.join('tmp/storage/submissions/NSUB000042/20200103-123456')}

      ## sequencer
      NGS

      ## upload_via
      webui

      ## HUP
      2020-02-01

      ## TPA
      true

      ## datatype
      WGS

      ## total_entry
      101

      ## Language
      ja
    BODY
  end
end
