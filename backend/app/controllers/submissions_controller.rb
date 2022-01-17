class SubmissionsController < ApplicationController
  before_action :require_authentication

  def create
    @submission = current_user.submissions.create!(submission_params)

    CompleteSubmissionJob.perform_later @submission
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
      :short_title,
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
