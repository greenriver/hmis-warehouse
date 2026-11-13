###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec/models/filters/criteria/shared_filter_criteria_context')

RSpec.describe DisabilitySummary::DisabilitySummaryReport, type: :model do
  include_context 'filter criteria setup'

  let(:coc_codes) { [] }
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      start: start_date,
      end: end_date,
      coc_codes: coc_codes,
      require_service_during_range: false,
      project_type_codes: HudHelper.util.homeless_project_type_codes,
    )
  end
  let(:report) { described_class.new(filter) }

  before do
    create(:hud_project_coc, project: project, CoCCode: 'MA-500', data_source: data_source)
    create(:hud_project_coc, project: project, CoCCode: 'MA-501', data_source: data_source)
    client = create(:grda_warehouse_hud_client)
    enrollment = create_enrollment_for_client(client, enrollment_attributes: { EnrollmentCoC: 'MA-500' }).enrollment
    create(
      :hud_disability,
      data_source_id: data_source.id,
      EnrollmentID: enrollment.EnrollmentID,
      PersonalID: enrollment.PersonalID,
      DisabilityType: 5,
      DisabilityResponse: 1,
      InformationDate: start_date,
    )
  end

  it 'groups disabilities under every CoC of the project when no CoC is selected' do
    expect(report.data_for_disabilities[:by_coc].keys).to contain_exactly('MA-500', 'MA-501')
  end

  context 'with a CoC selected' do
    let(:coc_codes) { ['MA-500'] }

    it 'groups disabilities only under the selected CoC for a project that is in several CoCs' do
      expect(report.data_for_disabilities[:by_coc].keys).to eq(['MA-500'])
    end
  end
end
