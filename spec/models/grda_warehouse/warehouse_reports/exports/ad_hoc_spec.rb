###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseReports::Exports::AdHoc, type: :model do
  shared_context 'ad hoc report setup' do
    let!(:running_user) { create(:acl_user) }
    let!(:role) { create(:role, can_view_project_related_filters: true, can_view_assigned_reports: true, can_view_projects: true, can_view_client_name: true) }
    let!(:collection) { create(:collection) }

    let!(:hmis_ds) { create(:hmis_primary_data_source) }
    let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
    # `Project.viewable_by` excludes confidential projects via `non_confidential`, which inner-joins
    # the organization -- a project without an organization row is never viewable.
    let!(:organization) { create(:hud_organization, data_source: hmis_ds) }
    let!(:project) { create(:hud_project, organization: organization, data_source: hmis_ds, ProjectType: 1) } # ES

    let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
    let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client', DOB: 20.years.ago.to_date) }
    let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'Client') }
    let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client', DOB: 20.years.ago.to_date) }

    # `client_scope` requires an open, head-of-household, homeless (ES/SO/SH/TH) enrollment for
    # each client -- `clients_with_ongoing_enrollments`, `heads_of_household`, and
    # `filter_for_sub_population` (default sub-population `:clients` still merges `.homeless`).
    def build_open_enrollment(client, in_project = project)
      create(:she_entry, client: client, data_source: hmis_ds, project: in_project, project_type: 1, head_of_household: true, first_date_in_program: 1.month.ago.to_date, last_date_in_program: nil)
    end
    let!(:restricted_she) { build_open_enrollment(restricted_destination_client) }
    let!(:open_she) { build_open_enrollment(open_destination_client) }

    let(:ad_hoc_options) do
      {
        user_id: running_user.id,
        start: 1.year.ago.to_date,
        end: Date.current,
        project_ids: [project.id],
      }
    end
    let(:ad_hoc) { described_class.create!(user_id: running_user.id, options: ad_hoc_options) }

    before do
      # Some ACL/report-scoping lookups (e.g. `Project.viewable_by`) are cached in `Rails.cache`,
      # which lives outside each example's DB transaction rollback -- a value cached while another
      # spec file's now-rolled-back fixtures were live can otherwise leak in here (or vice versa;
      # see `youth/export_spec.rb`).
      Rails.cache.clear
      Collection.maintain_system_groups
      collection.set_viewables({ projects: [project.id] })
      setup_access_control(running_user, role, collection)
      GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
      GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
      restricted_source_client.mark_as_restricted!(user: hmis_user)
    end

    after { GrdaWarehouse::Config.invalidate_cache }
  end

  describe '#rows_for_export' do
    include_context 'ad hoc report setup'

    it 'redacts the restricted client and shows the real name for the unrestricted client when the download toggle is on' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

      rows = ad_hoc.rows_for_export
      restricted_row = row_by_header(ad_hoc.headers_for_report, rows, key: restricted_destination_client.id)
      open_row = row_by_header(ad_hoc.headers_for_report, rows, key: open_destination_client.id)

      expect(restricted_row.values_at('First Name', 'Last Name')).to eq(['Name Redacted', 'Name Redacted'])
      expect(open_row.values_at('First Name', 'Last Name')).to eq(['Open', 'Client'])
    end

    # `headers_for_report` has no `include_pii_in_detail_downloads` gate at all -- name columns
    # are always present -- so `reporting_policy_for_project`'s own toggle check is what redacts
    # every client's name when the toggle is off, not row/column omission.
    it 'redacts every client name when the download toggle is off' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
      GrdaWarehouse::Config.invalidate_cache

      rows = ad_hoc.rows_for_export
      restricted_row = row_by_header(ad_hoc.headers_for_report, rows, key: restricted_destination_client.id)
      open_row = row_by_header(ad_hoc.headers_for_report, rows, key: open_destination_client.id)

      expect(restricted_row.values_at('First Name', 'Last Name')).to eq(['Name Redacted', 'Name Redacted'])
      expect(open_row.values_at('First Name', 'Last Name')).to eq(['Name Redacted', 'Name Redacted'])
    end
  end

  # Projects the running user reaches in different ways, each with one client enrolled, plus one
  # client enrolled in both `project` and `nameless_project`.
  shared_context 'projects with mixed access' do
    let!(:nameless_role) { create(:role, can_view_project_related_filters: true, can_view_assigned_reports: true, can_view_projects: true, can_view_client_name: false) }
    let!(:nameless_collection) { create(:collection) }
    # Viewable, but through a role without `can_view_client_name`.
    let!(:nameless_project) { create(:hud_project, organization: organization, data_source: hmis_ds, ProjectType: 1) }
    # Same data source and organization, but outside the running user's collections.
    let!(:other_project) { create(:hud_project, organization: organization, data_source: hmis_ds, ProjectType: 1) }
    # In the running user's collection, but the user can't report on confidential projects.
    let!(:confidential_project) { create(:hud_project, organization: organization, data_source: hmis_ds, ProjectType: 1, confidential: true) }

    let!(:multi_project_client) { create(:grda_warehouse_hud_client, FirstName: 'Multi', LastName: 'Project', DOB: 20.years.ago.to_date) }
    let!(:nameless_client) { create(:grda_warehouse_hud_client, FirstName: 'Nameless', LastName: 'Person', DOB: 20.years.ago.to_date) }
    let!(:other_project_client) { create(:grda_warehouse_hud_client, FirstName: 'Elsewhere', LastName: 'Person', DOB: 20.years.ago.to_date) }
    let!(:confidential_client) { create(:grda_warehouse_hud_client, FirstName: 'Confidential', LastName: 'Person', DOB: 20.years.ago.to_date) }

    let!(:multi_she) { build_open_enrollment(multi_project_client) }
    let!(:multi_nameless_she) { build_open_enrollment(multi_project_client, nameless_project) }
    let!(:nameless_she) { build_open_enrollment(nameless_client, nameless_project) }
    let!(:other_project_she) { build_open_enrollment(other_project_client, other_project) }
    let!(:confidential_she) { build_open_enrollment(confidential_client, confidential_project) }

    let(:selection) { { project_ids: [project.id] } }
    let(:ad_hoc_options) { { user_id: running_user.id, start: 1.year.ago.to_date, end: Date.current, **selection } }

    def client_ids(report)
      report.client_scope.distinct.pluck(:id)
    end

    before do
      collection.set_viewables({ projects: [project.id, confidential_project.id] })
      nameless_collection.set_viewables({ projects: [nameless_project.id] })
      setup_access_control(running_user, nameless_role, nameless_collection)
    end
  end

  describe '#client_scope' do
    include_context 'ad hoc report setup'
    include_context 'projects with mixed access'

    context 'when nothing is selected' do
      let(:selection) { {} }

      it 'includes clients enrolled in every project the user can view' do
        expect(client_ids(ad_hoc)).to contain_exactly(restricted_destination_client.id, open_destination_client.id, multi_project_client.id, nameless_client.id)
      end

      context 'with a viewable non-residential project' do
        # The project picker only offers residential projects, so "nothing selected" covers the same set
        let!(:services_only_project) { create(:hud_project, organization: organization, data_source: hmis_ds, ProjectType: 6) } # SSO
        let!(:services_only_client) { create(:grda_warehouse_hud_client, FirstName: 'Services', LastName: 'Only', DOB: 20.years.ago.to_date) }
        let!(:services_only_she) { build_open_enrollment(services_only_client, services_only_project) }

        before { collection.set_viewables({ projects: [project.id, confidential_project.id, services_only_project.id] }) }

        it 'excludes clients enrolled only in that project' do
          expect(client_ids(ad_hoc)).not_to include(services_only_client.id)
        end
      end
    end

    context 'when only a data source is selected' do
      let(:selection) { { data_source_ids: [hmis_ds.id] } }

      it 'includes only clients enrolled in projects the user can view' do
        expect(client_ids(ad_hoc)).to contain_exactly(restricted_destination_client.id, open_destination_client.id, multi_project_client.id, nameless_client.id)
      end
    end

    context 'when only an organization is selected' do
      let(:selection) { { organization_ids: [organization.id] } }

      it 'includes only clients enrolled in projects the user can view' do
        expect(client_ids(ad_hoc)).to contain_exactly(restricted_destination_client.id, open_destination_client.id, multi_project_client.id, nameless_client.id)
      end
    end

    context 'when a project outside the user\'s access is selected' do
      let(:selection) { { project_ids: [project.id, other_project.id] } }

      it 'excludes clients enrolled only in that project' do
        expect(client_ids(ad_hoc)).to contain_exactly(restricted_destination_client.id, open_destination_client.id, multi_project_client.id)
      end
    end

    context 'when a confidential project is selected' do
      let(:selection) { { project_ids: [project.id, confidential_project.id] } }

      it 'excludes clients enrolled only in that project' do
        expect(client_ids(ad_hoc)).to contain_exactly(restricted_destination_client.id, open_destination_client.id, multi_project_client.id)
      end
    end
  end

  describe '#run_and_save!' do
    include_context 'ad hoc report setup'
    include_context 'projects with mixed access'

    shared_examples 'an empty report' do
      it 'completes with no rows' do
        ad_hoc.run_and_save!

        expect(ad_hoc.reload.client_count).to eq(0)
        expect(ad_hoc.rows).to eq([])
        expect(ad_hoc.headers).to eq(ad_hoc.headers_for_report)
      end
    end

    context 'when only unauthorized projects are selected' do
      let(:selection) { { project_ids: [other_project.id, confidential_project.id] } }

      it_behaves_like 'an empty report'
    end
  end

  describe 'name visibility across projects' do
    include_context 'ad hoc report setup'
    include_context 'projects with mixed access'

    before { GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true) }

    def names_for(client)
      row_by_header(ad_hoc.headers_for_report, ad_hoc.rows_for_export, key: client.id).values_at('First Name', 'Last Name')
    end

    context 'with both the name-granting and the nameless project selected' do
      let(:selection) { { project_ids: [project.id, nameless_project.id] } }

      it 'redacts a client whose only in-range project does not allow names' do
        expect(names_for(nameless_client)).to eq(['Name Redacted', 'Name Redacted'])
      end

      it 'shows a client\'s name when any of their in-range projects allows it' do
        expect(names_for(multi_project_client)).to eq(['Multi', 'Project'])
      end
    end

    context 'with only the nameless project selected' do
      let(:selection) { { project_ids: [nameless_project.id] } }

      it 'redacts a client whose name is only allowed through an unselected project' do
        expect(names_for(multi_project_client)).to eq(['Name Redacted', 'Name Redacted'])
      end
    end
  end

  describe GrdaWarehouse::WarehouseReports::Exports::AdHocAnon do
    include_context 'ad hoc report setup'
    include_context 'projects with mixed access'

    let(:ad_hoc_anon) { described_class.create!(user_id: running_user.id, options: ad_hoc_options) }

    # De-identified output: selected projects are not narrowed to the user's viewable projects.
    context 'when a project outside the user\'s access is selected' do
      let(:selection) { { project_ids: [project.id, other_project.id] } }

      it 'includes clients from every selected project' do
        expect(client_ids(ad_hoc_anon)).to contain_exactly(restricted_destination_client.id, open_destination_client.id, multi_project_client.id, other_project_client.id)
      end

      it 'emits no names' do
        GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

        expect(ad_hoc_anon.headers_for_report).not_to include('First Name', 'Last Name', 'Client ID')
        expect(ad_hoc_anon.rows_for_export.flatten).not_to include('Open', 'Multi', 'Elsewhere')
      end
    end

    context 'when nothing is selected' do
      let(:selection) { {} }

      it 'includes clients from every project the user can view' do
        expect(client_ids(ad_hoc_anon)).to contain_exactly(restricted_destination_client.id, open_destination_client.id, multi_project_client.id, nameless_client.id)
      end
    end
  end
end
