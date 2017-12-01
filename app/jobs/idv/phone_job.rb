module Idv
  class PhoneJob < ProoferJob
    def verify_identity_with_vendor
      confirmation = agent.submit_phone(vendor_params, vendor_session_id)
      result = extract_result(confirmation)
      store_result(result)
    end
  end
end