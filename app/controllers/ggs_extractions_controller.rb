class GgsExtractionsController < ApplicationController
  def show
    @extraction = current_user.ggs_extractions.find(params[:id])
  end

  def create
    @extraction = current_user.ggs_extractions.create!(ggs_job_ids: params[:ids], require_owner: bearer_authenticated?)

    ExtractMetadataJob.perform_later @extraction

    render 'show', status: :created
  end
end
