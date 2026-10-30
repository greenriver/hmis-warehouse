###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec/models/filters/criteria/shared_filter_criteria_context')

RSpec.describe PublicReports::HomelessPopulation, type: :model do
  include_context 'filter criteria setup'

  let(:report) do
    described_class.new(
      user: user,
      filter: {
        'filters' => {
          'start' => start_date.iso8601,
          'end' => end_date.iso8601,
          'coc_codes' => ['MA-500'],
          'require_service_during_range' => false,
        },
      },
    )
  end
  let(:unselected_project) { create_project }

  before do
    ['MA-500', 'MA-501', 'MA-502'].each { |cocnum| GrdaWarehouse::Shape::Coc.create!(cocnum: cocnum, st: 'MA') }
    create(:hud_project_coc, project: project, CoCCode: 'MA-500', data_source: data_source)
    create(:hud_project_coc, project: project, CoCCode: 'MA-501', data_source: data_source)
    create(:hud_project_coc, project: unselected_project, CoCCode: 'MA-502', data_source: data_source)
    create_enrollment_for_client(create(:grda_warehouse_hud_client), enrollment_attributes: { EnrollmentCoC: 'MA-500' })
    create_enrollment_for_client(
      create(:grda_warehouse_hud_client),
      project_id: unselected_project.ProjectID,
      enrollment_attributes: { EnrollmentCoC: 'MA-502' },
    )
  end

  it 'limits census CoCs to the selected CoCs for a project that is in several CoCs' do
    expect(report.send(:coc_codes)).to eq(['MA-500'])
  end
end
