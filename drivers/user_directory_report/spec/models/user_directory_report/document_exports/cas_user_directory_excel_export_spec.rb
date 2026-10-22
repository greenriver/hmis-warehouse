###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserDirectoryReport::DocumentExports::CasUserDirectoryExcelExport, type: :model do
  let(:reader) { create(:acl_user) }
  let(:collection) { create(:collection) }
  let(:export) { described_class.new(user_id: reader.id) }

  describe '#authorized?' do
    let(:definition) do
      GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
      GrdaWarehouse::WarehouseReports::ReportDefinition.find_by!(url: 'user_directory_report/warehouse_reports/users/warehouse')
    end
    let(:other_definition) do
      GrdaWarehouse::WarehouseReports::ReportDefinition.where.not(id: definition.id).order(:url).first!
    end

    it 'is true when the reader has been assigned the user directory report' do
      collection.set_viewables(reports: [definition.id])
      setup_access_control(reader, create(:role, can_view_assigned_reports: true), collection)

      expect(export.authorized?).to eq(true)
    end

    it 'is false when the reader can view reports but not the user directory report' do
      collection.set_viewables(reports: [other_definition.id])
      setup_access_control(reader, create(:role, can_view_assigned_reports: true), collection)

      expect(export.authorized?).to eq(false)
    end

    it 'is false for a reader with no report permission' do
      collection.set_viewables(reports: [definition.id])
      setup_access_control(reader, create(:role, can_view_clients: true), collection)

      expect(export.authorized?).to eq(false)
    end
  end
end
