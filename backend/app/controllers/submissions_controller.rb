class SubmissionsController < ApplicationController
  def index
    @submissions         = current_user.submissions
    @working_list_states = WorkingList.instance.collect_statuses_and_accessions(current_user.submissions.map(&:mass_id))
  end

  def show
    mass_id = params.require(:mass_id)

    @submission = current_user.submissions.where(mass_id:).take!

    head :forbidden if @submission.upload_disabled?
  end

  def create
    ActiveRecord::Base.transaction isolation: :serializable do
      upload_via, contact_person, other_people = submission_params.values_at(:upload_via, :contact_person, :other_people)

      @submission = current_user.submissions.create!(submission_params.except(:upload_via, :contact_person, :other_people, :extraction_id, :files)) {|submission|
        submission.set_mass_id Submission.last_mass_id_seq.succ
        submission.build_contact_person contact_person

        other_people.each_with_index do |person, i|
          submission.other_people.build **person, position: i
        end
      }

      upload = @submission.uploads.create!(
        via: Upload.find_via(upload_via).from_params(**submission_params.to_h.symbolize_keys)
      )

      ProcessSubmissionJob.perform_later upload
    end
  end

  def last_submitted
    @submission = current_user.submissions.order(:id).last!
  end

  private

  def submission_params
    params.require(:submission).permit(
      :tpa,
      :upload_via,
      :extraction_id,
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
