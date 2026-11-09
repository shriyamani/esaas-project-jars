class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env["omniauth.auth"])
    if @user.persisted?
      set_flash_message(:notice, :success, kind: "Google")
      sign_in_and_redirect @user, event: :authentication
    else
      redirect_to new_user_session_path, alert: @user.errors.full_messages.to_sentence
    end
  end

  def failure
    redirect_to new_user_session_path, alert: "Google sign-in failed. Please try again."
  end
end