class GgsExtractionsController < ApplicationController
  def show
    @extraction = current_user.ggs_extractions.find(params[:id])
  end

  def create
    @extraction = current_user.ggs_extractions.create!(ggs_job_ids: params[:ids])

    ExtractMetadataJob.perform_later @extraction

    render 'show', status: :created
  end
end
