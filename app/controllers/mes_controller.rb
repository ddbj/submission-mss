class MesController < ApplicationController
  allow_bearer only: :show

  def show
    @user = current_user
  end
end
