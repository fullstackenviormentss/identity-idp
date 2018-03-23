module Users
  class TotpSetupController < ApplicationController
    # Because we allow initial auth through an app,
    # so a user is not required to have a phone, we are
    # not using the normal confirm_two_factor_authenticated method
    # and instead are only checking that they are signed in
    before_action :confirm_sign_in

    def new
      return redirect_to account_url if current_user.totp_enabled?

      user_session[:new_totp_secret] = current_user.generate_totp_secret if new_totp_secret.nil?

      @code = new_totp_secret
      @qrcode = current_user.decorate.qrcode(new_totp_secret)
    end

    def confirm
      result = TotpSetupForm.new(current_user, new_totp_secret, params[:code].strip).submit

      analytics.track_event(Analytics::TOTP_SETUP, result.to_h)

      if result.success?
        process_valid_code
      else
        process_invalid_code
      end
    end

    def disable
      if current_user.totp_enabled?
        analytics.track_event(Analytics::TOTP_USER_DISABLED)
        create_user_event(:authenticator_disabled)
        UpdateUser.new(user: current_user, attributes: { otp_secret_key: nil }).call
        flash[:success] = t('notices.totp_disabled')
      end
      redirect_to account_url
    end

    private

    def confirm_sign_in
      redirect_to sign_up_start_url(request_id: id) unless user_signed_in?
    end

    def process_valid_code
      flash[:success] = t('notices.totp_configured')
      redirect_to account_url
      user_session.delete(:new_totp_secret)
    end

    def process_invalid_code
      flash[:error] = t('errors.invalid_totp')
      redirect_to authenticator_setup_url
    end

    def new_totp_secret
      user_session[:new_totp_secret]
    end
  end
end
