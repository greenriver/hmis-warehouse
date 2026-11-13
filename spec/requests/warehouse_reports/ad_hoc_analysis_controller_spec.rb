###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::AdHocAnalysisController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/ad_hoc_analysis', name: 'Ad-Hoc Analysis Export') }

  let(:filter_params) { { start: 1.year.ago.to_date, end: Date.current } }

  before do
    collection.set_viewables({ reports: [report.id] })
    setup_access_control(user, role, collection)
    sign_in user
    # create redirects to AdHoc#url, which is built from FQDN.
    host! ENV.fetch('FQDN')
  end

  def stored_sub_population
    GrdaWarehouse::WarehouseReports::Exports::AdHoc.where(user_id: user.id).sole.options['sub_population']
  end

  describe 'POST create' do
    it 'stores an allow-listed sub-population as submitted' do
      post warehouse_reports_ad_hoc_analysis_index_path, params: { filter: filter_params.merge(sub_population: 'veterans') }

      expect(stored_sub_population).to eq('veterans')
    end

    it 'raises and stores no export for an unregistered sub-population' do
      expect { post warehouse_reports_ad_hoc_analysis_index_path, params: { filter: filter_params.merge(sub_population: 'not_a_real_population') } }.
        to raise_error(AvailableSubPopulations::UnknownSubPopulation)
      expect(GrdaWarehouse::WarehouseReports::Exports::AdHoc.where(user_id: user.id)).to be_empty
    end
  end
end
