###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec/models/filters/criteria/shared_filter_criteria_context')

RSpec.describe ZipCodeReport::Report, type: :model do
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
  let(:client) { create(:grda_warehouse_hud_client) }

  before do
    create(:hud_project_coc, project: project, CoCCode: 'MA-500', Zip: '02101', data_source: data_source)
    create(:hud_project_coc, project: project, CoCCode: 'MA-501', Zip: '02999', data_source: data_source)
    create_enrollment_for_client(client, head_of_household: true, enrollment_attributes: { EnrollmentCoC: 'MA-500' })
  end

  it 'counts the client under the zip of every CoC the project is in when no CoC is selected' do
    expect(report.zip_codes.map(&:Zip)).to contain_exactly('02101', '02999')
    expect(report.clients_count('02101')).to eq(1)
    expect(report.clients_count('02999')).to eq(1)
  end

  context 'with a CoC selected' do
    let(:coc_codes) { ['MA-500'] }

    it 'counts the client only under the zip of the selected CoC' do
      expect(report.zip_codes.map(&:Zip)).to eq(['02101'])
      expect(report.zip_code_data.keys).to eq(['02101'])
      expect(report.households_count('02101')).to eq(1)
    end
  end
end
