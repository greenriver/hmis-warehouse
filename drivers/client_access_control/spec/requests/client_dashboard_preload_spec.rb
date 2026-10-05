###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'
require 'nokogiri'

# Each example links more source clients than PreloadMissTracker::THRESHOLD. Loops over another
# identity's clients (the household example) raise PreloadMissError without a preload; loops over the
# destination's own sources do not, because DestinationClientPolicy preloads the whole identity on its
# first permission check. The rollup examples are smoke coverage for rendering with many sources.
RSpec.describe 'Client dashboard preloads', type: :request do
  include_context 'visibility test context'

  before do
    GrdaWarehouse::Config.delete_all
    GrdaWarehouse::Config.invalidate_cache
    Collection.maintain_system_groups
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  let!(:config) { create :config_b }
  let!(:user) { create :acl_user }
  let(:full_dashboard) { create :role, can_view_clients: true, can_view_client_name: true, can_view_full_client_dashboard: true, can_view_projects: true }
  let(:destination) { window_destination_client }

  # Each source is enrolled in the window project so every source-visibility scope keeps it
  let!(:sources) do
    Array.new(preload_miss_client_count) do |i|
      source = create(:grda_warehouse_hud_client, data_source_id: window_visible_data_source.id, FirstName: "Dashboard#{i}", LastName: 'Coverage')
      enrollment = create(:grda_warehouse_hud_enrollment, data_source_id: window_visible_data_source.id, PersonalID: source.PersonalID, ProjectID: window_project.ProjectID, EntryDate: 1.month.ago.to_date)
      create(
        :grda_warehouse_service_history,
        :service_history_entry,
        project_id: window_project.ProjectID,
        client_id: source.id,
        enrollment_group_id: enrollment.EnrollmentID,
        first_date_in_program: enrollment.EntryDate,
        data_source_id: window_visible_data_source.id,
      )
      GrdaWarehouse::WarehouseClient.create!(destination_id: destination.id, source_id: source.id, data_source_id: window_visible_data_source.id, id_in_source: source.PersonalID)
      source
    end
  end

  before do
    setup_access_control(user, full_dashboard, Collection.system_collection(:data_sources))
    sign_in user
  end

  describe 'GET /clients/:id' do
    it 'renders the dashboard tab and lists every source client for the rollup script' do
      get client_path(destination)

      expect(response).to have_http_status(:ok)
      doc = Nokogiri::HTML(response.body)
      expect(doc.css("a[href='#{client_path(destination)}']").map(&:text).map(&:squish)).to include('Dashboard')
      sources.each { |source| expect(response.body).to include(source.uuid) }
    end

    context 'with a supplemental data set on the source data source' do
      let(:supplemental_role) { create :role, can_view_supplemental_client_data: true, can_view_client_enrollments_with_roi: true }
      let!(:data_set) { create :hmis_supplemental_data_set, data_source: window_visible_data_source, name: 'Coverage Data Set' }
      let(:collection) { create :collection }

      before do
        collection.set_viewables({ supplemental_data_sets: [data_set.id], projects: [window_project.id] })
        setup_access_control(user, supplemental_role, collection)
        destination.update_columns(housing_release_status: GrdaWarehouse::Hud::Client.full_release_string, consented_coc_codes: [])
        GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.rebuild_clients([destination.id])
      end

      it 'renders the data set tab after checking supplemental access for every source client' do
        get client_path(destination)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Coverage Data Set')
      end
    end
  end

  describe 'GET /clients/:id/rollup/:partial' do
    # Entries in ClientShowPages#rollup's allow-list that need no installation-specific config.
    # entry_assessments and exit_assessments are listed there but have no partial.
    rollups = [
      'assessments', 'verifications', 'assessments_without_data', 'case_manager', 'contact_information',
      'demographics', 'disabilities', 'disability_types', 'income_benefits',
      'ongoing_residential_enrollments', 'other_enrollments', 'residential_enrollments', 'services', 'services_full',
      'services_all', 'custom_services', 'special_populations', 'zip_details', 'client_notes', 'chronic_notes', 'cohorts',
      'ce_assessments', 'enrollment_cocs', 'current_living_situations', 'ce_events', 'employment_education',
      'hmis_clients', 'gender', 'fy_24_enrollment_details'
    ]

    rollups.each do |partial|
      it "renders #{partial} with every source client linked" do
        get rollup_client_path(destination, partial: partial), xhr: true

        expect(response).to have_http_status(:ok)
      end
    end

    # Service history rows carry destination client ids; the residential scope and the household
    # lookup both read them from the destination
    it 'names every household member in residential enrollments' do
      household_id = 'HH-COVERAGE'
      organization = create(:grda_warehouse_hud_organization, data_source_id: window_visible_data_source.id)
      project = create(:grda_warehouse_hud_project, data_source_id: window_visible_data_source.id, OrganizationID: organization.OrganizationID, ProjectType: 1)
      enroll = lambda do |source, dest|
        enrollment = create(:grda_warehouse_hud_enrollment, data_source_id: window_visible_data_source.id, PersonalID: source.PersonalID, ProjectID: project.ProjectID, EntryDate: 1.month.ago.to_date, HouseholdID: household_id)
        create(
          :grda_warehouse_service_history,
          :service_history_entry,
          client_id: dest.id,
          data_source_id: window_visible_data_source.id,
          project_id: project.ProjectID,
          organization_id: organization.OrganizationID,
          enrollment_group_id: enrollment.EnrollmentID,
          first_date_in_program: enrollment.EntryDate,
          household_id: household_id,
          project_type: 1,
        )
      end
      enroll.call(sources.first, destination)
      members = Array.new(preload_miss_client_count) do |i|
        member = create(:grda_warehouse_hud_client, data_source_id: window_visible_data_source.id, FirstName: "Member#{i}", LastName: 'Coverage')
        member_destination = create(:grda_warehouse_hud_client, data_source_id: warehouse_data_source.id, FirstName: "Member#{i}", LastName: 'Coverage')
        GrdaWarehouse::WarehouseClient.create!(destination_id: member_destination.id, source_id: member.id, data_source_id: window_visible_data_source.id, id_in_source: member.PersonalID)
        enroll.call(member, member_destination)
        member
      end

      get rollup_client_path(destination, partial: :residential_enrollments), xhr: true

      expect(response).to have_http_status(:ok)
      members.each { |member| expect(response.body).to include(member.FirstName) }
    end
  end
end
