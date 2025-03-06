# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::NullPiiPolicy, type: :model do
  let(:policy) { described_class.instance }
  it 'denies all PII permissions' do
    expect(policy.can_view_name?).to be false
    expect(policy.can_view_photo?).to be false
    expect(policy.can_view_full_dob?).to be false
    expect(policy.can_view_full_ssn?).to be false
    expect(policy.can_view_hiv_status?).to be false
  end
end
