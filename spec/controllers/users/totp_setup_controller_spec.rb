require 'rails_helper'

describe Users::TotpSetupController, devise: true do
  describe 'before_actions' do
    it 'confirms sign-in' do
      expect(subject).to have_actions(
        :before,
        :confirm_sign_in
      )
    end
  end

  describe '#new' do
    context 'user has not yet enabled authenticator app' do
      before do
        stub_sign_in
        get :new
      end

      it 'returns a 200 status code' do
        expect(response.status).to eq(200)
      end

      it 'sets new_totp_secret in user_session' do
        expect(subject.user_session[:new_totp_secret]).not_to be_nil
      end

      it 'can be used to generate a qrcode with UserDecorator#qrcode' do
        expect(
          subject.current_user.decorate.qrcode(subject.user_session[:new_totp_secret])
        ).not_to be_nil
      end
    end

    context 'user has already enabled authenticator app' do
      it 'redirects to profile page' do
        stub_sign_in

        allow(subject.current_user).to receive(:totp_enabled?).and_return(true)

        get :new

        expect(response).to redirect_to account_path
      end
    end
  end

  describe '#confirm' do
    context 'when user presents invalid code' do
      before do
        stub_sign_in
        stub_analytics
        allow(@analytics).to receive(:track_event)

        get :new
        patch :confirm, params: { code: 123 }
      end

      it 'redirects with an error message' do
        expect(response).to redirect_to(authenticator_setup_path)
        expect(flash[:error]).to eq t('errors.invalid_totp')
        expect(subject.current_user.totp_enabled?).to be(false)

        result = {
          success: false,
          errors: {},
        }
        expect(@analytics).to have_received(:track_event).with(Analytics::TOTP_SETUP, result)
      end
    end

    context 'when user presents correct code' do
      before do
        stub_sign_in
        stub_analytics
        allow(@analytics).to receive(:track_event)

        code = '123455'
        totp_secret = 'abdef'
        subject.user_session[:new_totp_secret] = totp_secret
        form = instance_double(TotpSetupForm)

        allow(TotpSetupForm).to receive(:new).
          with(subject.current_user, totp_secret, code).and_return(form)
        response = FormResponse.new(success: true, errors: {})
        allow(form).to receive(:submit).and_return(response)

        get :new
        patch :confirm, params: { code: code }
      end

      it 'redirects to account_path with a success message' do
        expect(response).to redirect_to(account_path)
        expect(flash[:success]).to eq t('notices.totp_configured')
        expect(subject.user_session[:new_totp_secret]).to be_nil

        result = {
          success: true,
          errors: {},
        }
        expect(@analytics).to have_received(:track_event).with(Analytics::TOTP_SETUP, result)
      end
    end
  end

  describe '#disable' do
    context 'when a user has configured TOTP' do
      it 'disables TOTP' do
        user = create(:user, :signed_up, otp_secret_key: 'foo')
        sign_in user

        stub_analytics
        allow(@analytics).to receive(:track_event)
        allow(subject).to receive(:create_user_event)

        delete :disable

        expect(user.reload.otp_secret_key).to be_nil
        expect(user.reload.totp_enabled?).to be(false)
        expect(response).to redirect_to(account_path)
        expect(flash[:success]).to eq t('notices.totp_disabled')
        expect(@analytics).to have_received(:track_event).with(Analytics::TOTP_USER_DISABLED)
        expect(subject).to have_received(:create_user_event).with(:authenticator_disabled)
      end
    end
  end
end
