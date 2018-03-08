require 'rails_helper'

describe KbaSecurityForm do
  let(:user) { create(:user) }

  describe '#initialize' do
    it 'does not have a user with a nil token' do
      form = KbaSecurityForm.new(token: nil)
      expect(form.user).to be_nil
    end

    it 'does not have a user with a blank token' do
      form = KbaSecurityForm.new(token: '')
      expect(form.user).to be_nil
    end

    it 'does not have a user with a bad token' do
      form = KbaSecurityForm.new(token: 'ABC')
      expect(form.user).to be_nil
    end

    it 'does have a user with a good token' do
      ResetDevice.new(user).grant_request
      form = KbaSecurityForm.new(token: user.change_phone_request.granted_token)
      expect(form.user).to eq(user)
    end
  end

  describe '#submit' do
    it 'returns an error if an option is not selected' do
      form = KbaSecurityForm.new(token: nil)
      result = form.submit(answer: '-1')
      expect(result.errors[:answer]).to eq(t('kba_security.select_answer_error'))
    end

    it 'returns success if the answer is correct and the token is valid' do
      rd = ResetDevice.new(user)
      rd.grant_request
      token = user.change_phone_request.granted_token
      form = KbaSecurityForm.new(token: token)
      result = form.submit(answer: rd.correct_security_answer, token: token)
      expect(result.success?).to eq(true)
    end

    it 'fails if the token is not valid' do
      rd = ResetDevice.new(user)
      rd.grant_request
      token = user.change_phone_request.granted_token
      form = KbaSecurityForm.new(token: token)
      result = form.submit(answer: rd.correct_security_answer, token: 'ABC')
      expect(result.success?).to eq(false)
    end

    it 'fails if the answer is wrong' do
      rd = ResetDevice.new(user)
      rd.grant_request
      token = user.change_phone_request.granted_token
      form = KbaSecurityForm.new(token: token)
      result = form.submit(answer: '1', token: token)
      expect(result.success?).to eq(false)
    end
  end
end
