###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseReports::TouchPoint, type: :model do
  describe '#clean_data' do
    let!(:role) { create(:role, can_view_clients: true, can_view_client_name: true) }
    let!(:access_group) { create(:access_group) }
    let!(:running_user) do
      user = create(:user)
      role.add(user)
      access_group.add(user)
      user
    end
    let!(:hmis_ds) { create(:hmis_primary_data_source) }
    let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
    let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
    let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
    let!(:unrestricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client') }
    let!(:organization) { create(:hud_organization, data_source: hmis_ds) }
    let!(:project) { create(:grda_warehouse_hud_project, organization: organization, data_source: hmis_ds) }
    let!(:unrestricted_enrollment) { create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(unrestricted_source_client.id), project: project, data_source: hmis_ds) }

    let!(:report) do
      create(:touch_point_report_instance,
             user: running_user,
             parameters: { 'start' => 1.year.ago.to_date, 'end' => Date.tomorrow, 'name' => 'Intake' })
    end

    let!(:hmis_assessment_row) do
      GrdaWarehouse::Hmis::Assessment.create!(
        data_source_id: hmis_ds.id,
        site_id: 1,
        assessment_id: 1,
        name: 'Intake',
        site_name: 'Main Site',
        confidential: false,
        active: true,
      )
    end
    let!(:restricted_form) do
      GrdaWarehouse::HmisForm.create!(
        client_id: restricted_source_client.id,
        data_source_id: hmis_ds.id,
        site_id: 1,
        assessment_id: 1,
        name: 'Intake',
        collected_at: Date.current,
        staff: 'Staff Member',
        answers: { sections: [] },
      )
    end
    let!(:open_form) do
      GrdaWarehouse::HmisForm.create!(
        client_id: unrestricted_source_client.id,
        data_source_id: hmis_ds.id,
        site_id: 1,
        assessment_id: 1,
        name: 'Intake',
        collected_at: Date.current,
        staff: 'Staff Member',
        answers: { sections: [] },
      )
    end
    let!(:unrestricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'Client') }

    # `GrdaWarehouse::Config.get` caches the settings row at the class level for 30 seconds,
    # independent of each example's DB transaction rollback — without this, an earlier example's
    # `include_pii_in_detail_downloads` change can leak into a later one regardless of run order.
    after { GrdaWarehouse::Config.invalidate_cache }

    before do
      access_group.add_viewable(project)
      GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
      GrdaWarehouse::WarehouseClient.create!(destination_id: unrestricted_destination_client.id, source_id: unrestricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: unrestricted_source_client.id.to_s)
      restricted_source_client.mark_as_restricted!(user: hmis_user)
    end

    it 'redacts the client name for a restricted client and leaves the unrestricted client intact' do
      rows = report.clean_data(report.computed_data)[:data]
      restricted_row = rows.find { |row| row[0] == restricted_destination_client.id }
      open_row = rows.find { |row| row[0] == unrestricted_destination_client.id }

      expect(restricted_row[1]).to eq('Name Redacted')
      expect(open_row[1]).to eq('Open Client')
    end

    it 'redacts the unrestricted client name when the PII-download toggle is off, even though the user has real PII-view permission' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
      GrdaWarehouse::Config.invalidate_cache

      rows = report.clean_data(report.computed_data)[:data]
      open_row = rows.find { |row| row[0] == unrestricted_destination_client.id }

      expect(open_row[1]).to eq('Name Redacted')
    end
  end
end
