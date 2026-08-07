###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# CE-specific helpers for asserting on the state of a CE referral
module CeWorkflowSpecHelper
  # Assert a CE referral ended in the rejected terminal state.
  def expect_rejected(referral, result: nil)
    referral.reload
    expect(referral.status).to eq('rejected')
    expect(referral.ce_event&.referral_result).to eq(result)
  end

  # Assert a CE referral ended in the accepted terminal state, with a persisted enrollment and a CE
  # event recording the "successful referral" result (1).
  def expect_accepted(referral)
    referral.reload
    expect(referral.status).to eq('accepted')
    expect(referral.target_enrollment).to be_present
    expect(referral.ce_event&.referral_result).to eq(1)
  end
end

RSpec.configure do |config|
  config.include CeWorkflowSpecHelper
end
