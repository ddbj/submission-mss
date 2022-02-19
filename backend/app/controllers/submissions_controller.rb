class SubmissionsController < ApplicationController
  def create
    @submission = current_user.submissions.create!(submission_params.except(:files, :contact_person, :other_people)) {|submission|
      files, contact_person, other_people = submission_params.values_at(:files, :contact_person, :other_people)

      submission.uploads.build files: files if files.presence

      submission.build_contact_person contact_person

      other_people.each_with_index do |person, i|
        submission.other_people.build **person, position: i
      end
    }

    ProcessSubmissionJob.perform_later @submission
  end

  private

  def submission_params
    params.require(:submission).permit(
      :tpa,
      :dfast,
      :entries_count,
      :hold_date,
      :sequencer,
      :data_type,
      :description,
      :email_language,

      files: [],

      contact_person: [
        :email,
        :full_name,
        :affiliation
      ],

      other_people: [
        :email,
        :full_name
      ]
    )
  end
end
