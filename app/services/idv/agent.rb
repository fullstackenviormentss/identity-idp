module Idv
  class Agent
    delegate :vendor, :start, :submit_phone, :submit_state_id, to: :agent

    def initialize(vendor:, applicant:)
      self.agent = Proofer::Agent.new(applicant: applicant, vendor: vendor, kbv: false)
    end

    private

    attr_accessor :agent
  end
end
