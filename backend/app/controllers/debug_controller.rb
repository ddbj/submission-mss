class DebugController < ActionController::API
  def error
    raise 'This is a debug error.'
  end
end
