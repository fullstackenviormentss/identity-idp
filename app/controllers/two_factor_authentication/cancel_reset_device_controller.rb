module TwoFactorAuthentication
  class CancelResetDeviceController < ApplicationController
    def cancel
      if params[:only]
        cancel_request
      else
        cancel_and_report_fraud
      end
      sign_out
      flash[:success] = t('devise.two_factor_authentication.reset_device.successful_cancel')
      redirect_to root_url
    end

    private

    def cancel_request
      return unless ResetDevice.cancel_request(params[:token])
      analytics.track_event(Analytics::RESET_DEVICE_CANCELLED)
    end

    def cancel_and_report_fraud
      return unless ResetDevice.report_fraud(params[:token])
      analytics.track_event(Analytics::RESET_DEVICE_REPORTED_FRAUD)
    end
  end
end
