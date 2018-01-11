require 'rails_helper'

feature 'User edit' do
  let(:user) { create(:user, :signed_up) }

  context 'editing email' do
    before do
      sign_in_and_2fa_user(user)
      visit manage_email_path
    end

    scenario 'user sees error message if form is submitted without email', :js, idv_job: true do
      fill_in 'Email', with: ''
      click_button 'Update'

      expect(page).to have_content t('valid_email.validations.email.invalid')
    end
  end

  context 'editing 2FA phone number' do
    before do
      sign_in_and_2fa_user(user)
      visit manage_phone_path
    end

    scenario 'user sees error message if form is submitted without phone number', js: true do
      fill_in 'Phone', with: ''
      click_button t('forms.buttons.submit.confirm_change')

      expect(page).to have_content t('errors.messages.improbable_phone')
    end

    scenario 'updates international code as user types', :js do
      fill_in 'Phone', with: '+81 54 354 3643'

      expect(page.find('#user_phone_form_international_code').value).to eq 'JP'

      fill_in 'Phone', with: '5376'
      select 'Morocco +212', from: 'International code'

      expect(find('#user_phone_form_phone').value).to eq '+212 5376'

      fill_in 'Phone', with: '54354'
      select 'Japan +81', from: 'International code'

      expect(find('#user_phone_form_phone').value).to include '+81'
    end

    scenario 'confirms with selected OTP delivery method and updates user delivery preference' do
      allow(SmsOtpSenderJob).to receive(:perform_later)
      allow(VoiceOtpSenderJob).to receive(:perform_now)

      fill_in 'Phone', with: '555-555-5000'
      choose 'Phone call'

      click_button t('forms.buttons.submit.confirm_change')

      user.reload

      expect(current_path).to eq(login_otp_path(otp_delivery_preference: :voice))
      expect(SmsOtpSenderJob).to_not have_received(:perform_later)
      expect(VoiceOtpSenderJob).to have_received(:perform_now)
      expect(user.otp_delivery_preference).to eq('voice')
    end
  end

  context "user A accesses create password page with user B's email change token" do
    it "redirects to user A's account page", email: true do
      sign_in_and_2fa_user(user)
      visit manage_email_path
      fill_in 'Email', with: 'user_b_new_email@test.com'
      click_button 'Update'
      confirmation_link = parse_email_for_link(last_email, /confirmation_token/)
      token = confirmation_link.split('confirmation_token=').last
      visit destroy_user_session_path
      user_a = create(:user, :signed_up)
      sign_in_and_2fa_user(user_a)
      visit sign_up_enter_password_path(confirmation_token: token)

      expect(page).to have_current_path(account_path)
      expect(page).to_not have_content user.email
    end
  end

  context 'editing password' do
    before do
      sign_in_and_2fa_user(user)
      visit manage_password_path
    end

    scenario 'user sees error message if form is submitted with invalid password' do
      fill_in 'New password', with: 'foo'
      click_button 'Update'

      expect(page).
        to have_content t('errors.messages.too_short.other', count: Devise.password_length.first)
    end
  end
end
