class MassDirectoryExtractionsController < ApplicationController
  def show
    @extraction = current_user.mass_directory_extractions.find(params[:id])
  end

  def create
    @extraction = current_user.mass_directory_extractions.create!

    ExtractMetadataJob.perform_later @extraction

    render 'show', status: :created
  end
end
