# https://stackoverflow.com/questions/43911928/how-to-render-file-in-rails-5-api
class FrontendsController < ActionController::Base
  def show
    render file: Rails.root.join('public/index.html')
  end
end
