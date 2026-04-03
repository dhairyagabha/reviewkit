class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_reviewer

  helper_method :current_user

  private

  def current_user
    Current.reviewer
  end

  def set_current_reviewer
    Current.reviewer = Reviewer.order(:id).first
  end
end
