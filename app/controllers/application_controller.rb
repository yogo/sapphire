class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user!
  before_filter :choose_layout
  layout :choose_layout

  def choose_layout
    if %w{sessions registrations passwords}.include?(controller_name)
      return 'box'
    end
    return 'application'
  end
end
