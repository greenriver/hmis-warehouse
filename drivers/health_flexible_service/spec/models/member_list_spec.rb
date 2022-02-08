###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HealthFlexibleService::MemberList, type: :model do
  let!(:aco) { create :accountable_care_organization }
  let!(:vpr_1) { create :vpr, :out_of_range_1, :pre_tenancy_1 }
  let!(:vpr_2) { create :vpr, :in_range_1, :pre_tenancy_1 }
  let!(:vpr_3) { create :vpr, :in_range_1, :nutrition_1, :in_range_2, :pre_tenancy_2 }
  let!(:vpr_4) { create :vpr, :in_range_1, :pre_tenancy_1, :in_range_2, :pre_tenancy_2 }

  before(:each) do
    vpr_1.patient.patient_referral.update(accountable_care_organization_id: aco.id)
    vpr_2.patient.patient_referral.update(accountable_care_organization_id: aco.id)
    vpr_3.patient.patient_referral.update(accountable_care_organization_id: aco.id)
    vpr_4.patient.patient_referral.update(accountable_care_organization_id: aco.id)
  end

  it 'excludes out of range services' do
    member_list = HealthFlexibleService::MemberList.new(aco.id, 0, Date.current)
    expect(member_list.vpr_scope('Pre-Tenancy Supports: Individual Supports').count).to eq(3)
  end

  it 'populates the columns' do
    member_list = HealthFlexibleService::MemberList.new(aco.id, 0, Date.current)
    vpr = member_list.vpr_scope('Pre-Tenancy Supports: Individual Supports').last
    cols = member_list.columns(vpr, 'Pre-Tenancy Supports: Individual Supports')

    expect(cols.size).to eq(15)
    expect(cols[7]).to include(',')
  end
end
