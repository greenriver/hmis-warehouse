###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec/models/filters/criteria/shared_filter_criteria_context')

RSpec.describe TxClientReports::ResearchExport, type: :model do
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
  let(:export) { described_class.new(user_id: user.id, options: JSON.parse(filter.for_params.to_json)) }

  before do
    create(:hud_project_coc, project: project, CoCCode: 'MA-500', data_source: data_source)
    create(:hud_project_coc, project: project, CoCCode: 'MA-501', data_source: data_source)
    create_enrollment_for_client(create(:grda_warehouse_hud_client), enrollment_attributes: { EnrollmentCoC: 'MA-500' })
  end

  it 'reports only the selected CoC for a project that is in several CoCs' do
    coc_index = export.enrollment_columns.index(GrdaWarehouse::Hud::ProjectCoc.arel_table[:CoCCode])

    expect(export.enrollment_rows.map { |row| row[coc_index] }).to eq(['MA-500'])
  end
end
