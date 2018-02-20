require 'rails_helper'

describe 'user edits their account', email: true do
  include Features::MailerHelper
  include Features::ActiveJobHelper

  let(:user) { create(:user, :signed_up, phone: '+1 (202) 555-1213') }

  def user_session
    session['warden.user.user.session']
  end

  def sign_in_as_a_valid_user
    post new_user_session_path, params: { user: { email: user.email, password: user.password } }
    get otp_send_path, params: { otp_delivery_selection_form: { otp_delivery_preference: 'sms' } }
    follow_redirect!
    post login_two_factor_path, params: {
      otp_delivery_preference: 'sms', code: user.reload.direct_otp
    }
  end

  context 'user changes email address' do
    before do
      sign_in_as_a_valid_user
      put manage_email_path, params: { update_user_email_form: { email: 'new_email@example.com' } }
    end

    it 'displays a notice informing the user their email has been confirmed when user confirms' do
      get parse_email_for_link(last_email, /confirmation_token/)

      expect(flash[:success]).to eq t('devise.confirmations.confirmed')
      expect(response).to render_template('user_mailer/email_changed')
    end

    it 'calls EmailNotifier when user confirms their new email', email: true do
      notifier = instance_double(EmailNotifier)

      expect(EmailNotifier).to receive(:new).with(user).and_return(notifier)
      expect(notifier).to receive(:send_email_changed_email)

      get parse_email_for_link(last_email, /confirmation_token/)
    end

    it 'confirms email when user clicks link in email while signed out' do
      delete destroy_user_session_path
      get parse_email_for_link(last_email, /confirmation_token/)

      expect(flash[:success]).to eq t('devise.confirmations.confirmed')
    end
  end

  context 'user submits email address with invalid encoding' do
    it 'returns a 400 error and logs the user uuid' do
      sign_in_as_a_valid_user
      params = { update_user_email_form: { email: "test\xFFbar\xF8@test.com" } }
      headers = { CONTENT_TYPE: 'application/x-www-form-urlencoded;foo' }

      expect(Rails.logger).to receive(:info) do |arguments|
        attributes = JSON.parse(arguments)
        keys = %w[event user_uuid ip user_agent timestamp host visitor_id content_type]
        expect(attributes['user_uuid']).to eq user.uuid
        expect(attributes['event']).to eq 'Invalid UTF-8 encoding'
        expect(attributes['content_type']).to eq 'application/x-www-form-urlencoded;foo'
        expect(attributes.keys).to match_array keys
      end

      put manage_email_path, params: params, headers: headers

      expect(response.status).to eq 400
    end
  end
end
