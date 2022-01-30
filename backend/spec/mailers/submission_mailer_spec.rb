require 'rails_helper'

using Module.new {
  refine ActionMailer::MessageDelivery do
    def newline_normalized_body
      body.decoded.gsub("\r\n", "\n")
    end
  end
}

RSpec.describe SubmissionMailer do
  describe 'confirmation' do
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

      mail = SubmissionMailer.with(submission:).confirmation

      expect(mail.from).to contain_exactly('mass@ddbj.nig.ac.jp')
      expect(mail.to).to   contain_exactly('alice@example.com')
      expect(mail.cc).to   contain_exactly('mass@ddbj.nig.ac.jp', 'bob@example.com', 'carol@example.com')

      expect(mail.subject).to eq('[DDBJ:NSUB000042] draft genome (WGS)')

      expect(mail.newline_normalized_body).to include(<<~BODY)
        Wonderland Inc.
        Alice Liddell 様

        大規模塩基配列データ登録システム Mass Submission System (MSS) をご利用下さいまして、ありがとうございます。

        私共ではお送りいただいた情報について、国際塩基配列データベース (DDBJ/ENA/GenBank) が定める規則に従い査定作業を行います。
      BODY
    end

    example 'email_language=en, uploaded=true' do
      submission = create_submission(email_language: 'en', uploaded: true)

      mail = SubmissionMailer.with(submission:).confirmation

      expect(mail.newline_normalized_body).to include(<<~BODY)
        Wonderland Inc.
        Dear Dr. Alice Liddell,

        Thank you for using DDBJ Mass Submission System (MSS) for large-scale sequence data submission.

        We will check and annotate them on the basis of the manual and rules common to the DDBJ, EMBL-Bank, and GenBank.
      BODY
    end

    example 'email_language=ja, uploaded=false' do
      submission = create_submission(email_language: 'ja', uploaded: false)

      mail = SubmissionMailer.with(submission:).confirmation

      expect(mail.newline_normalized_body).to include(<<~BODY)
        大規模塩基配列データ登録システム Mass Submission System (MSS) をご利用下さいまして、ありがとうございます。

        登録には「アノテーションファイル」と「配列ファイル」が必要です。
      BODY

      expect(mail.newline_normalized_body).to include(<<~BODY)
        Submission対象のデータタイプに関する説明です。
        https://www.ddbj.nig.ac.jp/ddbj/wgs.html
      BODY
    end

    example 'email_language=en, uploaded=false' do
      submission = create_submission(email_language: 'en', uploaded: false)

      mail = SubmissionMailer.with(submission:).confirmation

      expect(mail.newline_normalized_body).to include(<<~BODY)
        Thank you for using DDBJ Mass Submission System (MSS) for large-scale sequence data submission.

        Annotation and sequence files are needed for the registration.
      BODY

      expect(mail.newline_normalized_body).to include(<<~BODY)
        Regarding the explanation of the datatype that you have chosen, visit the site below.
        https://www.ddbj.nig.ac.jp/ddbj/wgs-e.html
      BODY
    end
  end
end
