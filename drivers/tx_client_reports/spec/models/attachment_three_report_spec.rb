###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TxClientReports::AttachmentThreeReport, type: :model do
  describe '#rows' do
    let!(:running_user) { create(:acl_user) }
    let!(:role) { create(:role, can_view_project_related_filters: true, can_view_assigned_reports: true, can_view_projects: true) }
    let!(:hmis_ds) { create(:hmis_primary_data_source) }
    let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
    let!(:data_source) { create(:destination_data_source) }
    let!(:organization) { create(:hud_organization, data_source: data_source) }
    let!(:project) { create(:hud_project, organization: organization, data_source: data_source) }

    let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
    let!(:restricted_destination_client) { create(:hud_client, FirstName: 'Restricted', LastName: 'Client', data_source: data_source) }
    let!(:unrestricted_destination_client) { create(:hud_client, FirstName: 'Open', LastName: 'Client', data_source: data_source) }

    # `rows` walks `enrollment.household_enrollments` (`ServiceHistoryEnrollment has_many :household_enrollments,
    # primary_key: [:data_source_id, :project_id, :household_id], foreign_key: [:data_source_id, :ProjectID, :HouseholdID]`)
    # — a real `GrdaWarehouse::Hud::Enrollment` plus a matching `ServiceHistoryEnrollment` sharing the same
    # HouseholdID is required for that association to resolve without raising (an empty match is fine — it
    # doesn't need a second household member). Mirrors the real working pattern in
    # `drivers/hud_spm_report/spec/models/fy2026/spm_enrollment_builder_spec.rb`
    # (`create(:she_entry, data_source:, enrollment:, client:)`), not a fabricated combined factory.
    let!(:restricted_enrollment) do
      create(:hud_enrollment, data_source: data_source, client: restricted_destination_client, ProjectID: project.ProjectID, HouseholdID: 'rhh1', EntryDate: 1.month.ago.to_date)
    end
    let!(:restricted_she) { create(:she_entry, data_source: data_source, enrollment: restricted_enrollment, client: restricted_destination_client, project: project, first_date_in_program: 1.month.ago.to_date) }
    let!(:open_enrollment) do
      create(:hud_enrollment, data_source: data_source, client: unrestricted_destination_client, ProjectID: project.ProjectID, HouseholdID: 'ohh1', EntryDate: 1.month.ago.to_date)
    end
    let!(:open_she) { create(:she_entry, data_source: data_source, enrollment: open_enrollment, client: unrestricted_destination_client, project: project, first_date_in_program: 1.month.ago.to_date) }

    let(:filter) do
      ::Filters::FilterBase.new(
        user_id: running_user.id,
        project_ids: [project.id],
        start: 2.months.ago.to_date,
        end: Date.current,
        require_service_during_range: false,
      )
    end

    before do
      setup_access_control(running_user, role, Collection.system_collection(:data_sources))
      GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
      restricted_source_client.mark_as_restricted!(user: hmis_user)
    end

    it 'redacts the restricted client and leaves the unrestricted client intact' do
      report = described_class.new(filter)
      restricted_row = report.rows.find { |r| r[:client_id] == restricted_destination_client.id }
      open_row = report.rows.find { |r| r[:client_id] == unrestricted_destination_client.id }

      expect(restricted_row[:client_name]).to eq('Name Redacted')
      expect(open_row[:client_name]).to eq('Open Client')
    end
  end
end
