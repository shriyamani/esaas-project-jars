class Users::SessionsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    flash.now[:alert] ||= I18n.t("devise.failure.unauthenticated")
  end
end
