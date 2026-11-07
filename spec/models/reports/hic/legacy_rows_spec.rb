###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Legacy HIC report rows', type: :model do
  let!(:fy2017) { Reports::Hic::Fy2017::Base.create!(name: 'HIC - FY 2017', enabled: false) }
  let!(:fy2019) { Reports::Hic::Fy2019::Base.create!(name: 'HIC', enabled: false) }

  it 'still load as their STI classes' do
    reports = Report.where(id: [fy2017.id, fy2019.id]).index_by(&:id)

    expect(reports[fy2017.id]).to be_a(Reports::Hic::Fy2017::Base)
    expect(reports[fy2019.id]).to be_a(Reports::Hic::Fy2019::Base)
  end

  it 'link to the generic report results page' do
    expect(fy2019.results_path).to eq(Rails.application.routes.url_helpers.report_report_results_path(fy2019))
  end
end
