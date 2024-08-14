class DfastExtractionsController < ApplicationController
  def show
    @extraction = current_user.dfast_extractions.find(params[:id])
  end

  def create
    @extraction = current_user.dfast_extractions.create!(dfast_job_ids: params[:ids])

    ExtractMetadataJob.perform_later @extraction

    render "show", status: :created
  end
end
