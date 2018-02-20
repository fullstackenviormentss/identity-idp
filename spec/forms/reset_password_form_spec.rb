require 'rails_helper'

describe ResetPasswordForm, type: :model do
  subject { ResetPasswordForm.new(build_stubbed(:user, uuid: '123')) }

  it_behaves_like 'password validation'

  describe '#submit' do
    context 'when the password is valid but the token has expired' do
      it 'returns a hash with errors' do
        user = build_stubbed(:user, uuid: '123')
        allow(user).to receive(:reset_password_period_valid?).and_return(false)

        form = ResetPasswordForm.new(user)

        password = 'valid password'

        errors = { reset_password_token: ['token_expired'] }

        extra = {
          user_id: '123',
          active_profile: false,
          confirmed: true,
        }

        result = instance_double(FormResponse)

        expect(FormResponse).to receive(:new).
          with(success: false, errors: errors, extra: extra).and_return(result)
        expect(form.submit(password: password)).to eq result
      end
    end

    context 'when the password is invalid and token is valid' do
      it 'returns a hash with errors' do
        user = build_stubbed(:user, uuid: '123')
        allow(user).to receive(:reset_password_period_valid?).and_return(true)

        form = ResetPasswordForm.new(user)

        password = 'invalid'

        errors = { password: ['is too short (minimum is 8 characters)'] }

        extra = {
          user_id: '123',
          active_profile: false,
          confirmed: true,
        }

        result = instance_double(FormResponse)

        expect(FormResponse).to receive(:new).
          with(success: false, errors: errors, extra: extra).and_return(result)
        expect(form.submit(password: password)).to eq result
      end
    end

    context 'when both the password and token are valid' do
      it 'sets the user password to the submitted password' do
        user = build_stubbed(:user, uuid: '123')
        allow(user).to receive(:reset_password_period_valid?).and_return(true)

        form = ResetPasswordForm.new(user)

        password = 'valid password'

        extra = {
          user_id: '123',
          active_profile: false,
          confirmed: true,
        }

        result = instance_double(FormResponse)

        expect(FormResponse).to receive(:new).
          with(success: true, errors: {}, extra: extra).and_return(result)
        expect(form.submit(password: password)).to eq result
      end
    end

    context 'when both the password and token are invalid' do
      it 'returns a hash with errors' do
        user = build_stubbed(:user, uuid: '123')
        allow(user).to receive(:reset_password_period_valid).and_return(false)

        form = ResetPasswordForm.new(user)

        password = 'short'

        errors = {
          password: ['is too short (minimum is 8 characters)'],
          reset_password_token: ['token_expired'],
        }

        extra = {
          user_id: '123',
          active_profile: false,
          confirmed: true,
        }

        result = instance_double(FormResponse)

        expect(FormResponse).to receive(:new).
          with(success: false, errors: errors, extra: extra).and_return(result)
        expect(form.submit(password: password)).to eq result
      end
    end

    it_behaves_like 'strong password', 'ResetPasswordForm'
  end
end
