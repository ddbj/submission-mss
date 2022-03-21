require 'rails_helper'

RSpec.describe SubmissionMailer do
  describe 'submitter_confirmation' do
    def create_submission(email_language:, uploaded:)
      create(:submission, **{
        id:             42,
        user:           build(:user, :alice),
        contact_person: build(:contact_person, :alice),
        data_type:      'wgs',
        email_language: ,

        other_people: [
          build(:other_person, :bob),
          build(:other_person, :carol)
        ],

        uploads: uploaded ? [build(:upload)] : []
      })
    end

    example 'email_language=ja, uploaded=true' do
      submission = create_submission(email_language: 'ja', uploaded: true)

      mail = SubmissionMailer.with(submission:).submitter_confirmation

      expect(mail).to deliver_from('Admin <mssform@example.com>')
      expect(mail).to deliver_to('alice+idp@example.com')
      expect(mail).to cc_to('alice+contact@foo.example.com', 'bob@bar.example.com', 'carol@baz.example.com')

      expect(mail).to have_subject('[DDBJ:NSUB000042] WGS: Whole Genome Shotgun')

      expect(mail).to have_body_text(<<~BODY)
        ご登録者 様

        大規模塩基配列データ登録システム Mass Submission System (MSS) をご利用下さいまして、ありがとうございます。

        私共ではお送りいただいた情報について、国際塩基配列データベース (DDBJ/ENA/GenBank) が定める規則に従い査定作業を行います。
      BODY

      expect(mail).to have_body_text(<<~BODY)
        Submission file の再提出を求められた際は、次の URL から upload してください。
        http://mssform.example.com/home/submission/NSUB000042/upload?locale=ja
      BODY
    end

    example 'email_language=en, uploaded=true' do
      submission = create_submission(email_language: 'en', uploaded: true)

      mail = SubmissionMailer.with(submission:).submitter_confirmation

      expect(mail).to have_body_text(<<~BODY)
        Dear Submitter,

        Thank you for using DDBJ Mass Submission System (MSS) for large-scale sequence data submission.

        We will check and annotate them on the basis of the manual and rules common to the DDBJ, EMBL-Bank, and GenBank.
      BODY

      expect(mail).to have_body_text(<<~BODY)
        If you are asked for re-submitting the files, upload the submission file(s) from the URL below.
        http://mssform.example.com/home/submission/NSUB000042/upload?locale=en
      BODY
    end

    example 'email_language=ja, uploaded=false' do
      submission = create_submission(email_language: 'ja', uploaded: false)

      mail = SubmissionMailer.with(submission:).submitter_confirmation

      expect(mail).to have_body_text(<<~BODY)
        大規模塩基配列データ登録システム Mass Submission System (MSS) をご利用下さいまして、ありがとうございます。

        登録には「アノテーションファイル」と「配列ファイル」が必要です。
      BODY

      expect(mail).to have_body_text(<<~BODY)
        Submission対象のデータタイプに関する説明です。
        https://www.ddbj.nig.ac.jp/ddbj/wgs.html
      BODY

      expect(mail).to have_body_text(<<~BODY)
        Submission file(s)完成後、以下の URL から upload してください。
        http://mssform.example.com/home/submission/NSUB000042/upload?locale=ja
      BODY
    end

    example 'email_language=en, uploaded=false' do
      submission = create_submission(email_language: 'en', uploaded: false)

      mail = SubmissionMailer.with(submission:).submitter_confirmation

      expect(mail).to have_body_text(<<~BODY)
        Thank you for using DDBJ Mass Submission System (MSS) for large-scale sequence data submission.

        Annotation and sequence files are needed for the registration.
      BODY

      expect(mail).to have_body_text(<<~BODY)
        Regarding the explanation of the datatype that you have chosen, visit the site below.
        https://www.ddbj.nig.ac.jp/ddbj/wgs-e.html
      BODY

      expect(mail).to have_body_text(<<~BODY)
        Upload the submission file(s) from the URL below, after you completely create them.
        http://mssform.example.com/home/submission/NSUB000042/upload?locale=en
      BODY
    end

    example 'allowed domains' do
      ClimateControl.modify MAIL_ALLOWED_DOMAINS: 'foo.example.com,baz.example.com' do
        submission = create_submission(email_language: 'ja', uploaded: true)

        mail = SubmissionMailer.with(submission:).submitter_confirmation

        expect(mail).to deliver_from('Admin <mssform@example.com>')
        expect(mail).to deliver_to('alice+idp@example.com')
        expect(mail).to cc_to('alice+contact@foo.example.com', 'carol@baz.example.com')
      end
    end
  end

  describe 'curator_notification' do
    around do |example|
      ClimateControl.modify(SUBMISSIONS_DIR: '/path/to/submissions', &example)
    end

    example do
      submission = create(:submission, **{
        id:             42,
        user:           build(:user, :alice),
        created_at:     '2020-01-01',
        description:    'some description',
        contact_person: build(:contact_person, :alice),
        sequencer:      'ngs',
        dfast:          true,
        hold_date:      '2020-02-01',
        tpa:            true,
        data_type:      'wgs',
        entries_count:  101,
        email_language: 'ja',

        uploads: [
          build(:upload, created_at: '2020-01-02 12:34:56'),
          build(:upload, created_at: '2020-01-03 12:34:56')
        ],

        other_people: [
          build(:other_person, :bob),
          build(:other_person, :carol)
        ]
      })

      mail = SubmissionMailer.with(submission:).curator_notification

      expect(mail).to deliver_from('Admin <mssform@example.com>')
      expect(mail).to deliver_to('Admin <mssform@example.com>')

      expect(mail).to have_subject('[DDBJ:NSUB000042] WGS: Whole Genome Shotgun')

      expect(mail).to have_body_text(<<~BODY)
        ## mass-id
        NSUB000042

        ## mass-id_created date
        2020-01-01

        ## description
        some description

        ## contact_email
        alice+contact@foo.example.com

        ## contact_person_name
        Alice Liddell

        ## contact_institution
        Wonderland Inc.

        ## other_person
        Bob <bob@bar.example.com>; Carol <carol@baz.example.com>

        ## D-way_account
        alice-liddell

        ## D-way_account_email
        alice+idp@example.com

        ## data_arrival_date
        20200102-123456: /path/to/submissions/NSUB000042/20200102-123456
        20200103-123456: /path/to/submissions/NSUB000042/20200103-123456

        ## sequencer
        NGS

        ## annotation_pipeline
        DFAST

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
end
