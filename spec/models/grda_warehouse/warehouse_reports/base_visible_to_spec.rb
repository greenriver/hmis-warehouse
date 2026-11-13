###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseReports::Base, type: :model do
  include_context 'report visibility users'

  let(:report_class) { GrdaWarehouse::WarehouseReports::ChronicReport }
  let(:report_definition_url) { 'warehouse_reports/chronic' }
  let!(:unowned_report) { report_class.create!(user_id: nil) }

  it 'limits a user who can view assigned reports to reports they ran' do
    expect(report_class.visible_to(own_reports_user)).to contain_exactly(own_report)
  end

  it 'gives a user who can view all reports every report, including ones with no recorded runner' do
    expect(report_class.visible_to(all_reports_user)).to contain_exactly(own_report, others_report, unowned_report)
  end

  it 'gives a user with neither permission nothing' do
    expect(report_class.visible_to(user_with_role(can_view_clients: true))).to be_empty
  end
end
