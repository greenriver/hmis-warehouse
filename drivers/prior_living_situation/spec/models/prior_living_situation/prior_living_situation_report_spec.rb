###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec/models/filters/criteria/shared_filter_criteria_context')

RSpec.describe PriorLivingSituation::PriorLivingSituationReport, type: :model do
  include_context 'filter criteria setup'

  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      start: start_date,
      end: end_date,
      coc_codes: ['MA-500'],
      require_service_during_range: false,
      project_type_codes: HudHelper.util.homeless_project_type_codes,
    )
  end
  let(:report) { described_class.new(filter) }

  before do
    create(:hud_project_coc, project: project, CoCCode: 'MA-500', data_source: data_source)
    create(:hud_project_coc, project: project, CoCCode: 'MA-501', data_source: data_source)
    create_enrollment_for_client(
      create(:grda_warehouse_hud_client),
      enrollment_attributes: { EnrollmentCoC: 'MA-500', LivingSituation: 116 },
    )
  end

  it 'groups living situations only under the selected CoC for a project that is in several CoCs' do
    expect(report.data_for_living_situations[:by_coc].keys).to eq(['MA-500'])
  end
end
