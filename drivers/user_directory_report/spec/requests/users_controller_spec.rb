###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# User Directory Report: name, email, phone and agency for every user in the directory,
# in HTML and as an xlsx download, for both the warehouse and (where configured) CAS.
#
RSpec.describe UserDirectoryReport::WarehouseReports::UsersController, type: :request do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:collection) { create(:collection) }

  # Seed the real report definitions rather than fabricating one: the url is what
  # WarehouseReportAuthorization matches on, and find_by! makes a rename of the seeded
  # definition fail here instead of silently passing against a stale hardcoded url.
  # rails_helper only seeds definitions for runs that include HUD report driver examples.
  before { GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions }

  let(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.
      find_by!(url: 'user_directory_report/warehouse_reports/users/warehouse')
  end

  # A user who should appear in the directory once access is allowed, and whose absence
  # from an unauthorized response is what we assert on.
  let!(:listed_user) { create(:acl_user, first_name: 'Directory', last_name: 'Listing') }

  def sign_in_with(role, grant_report: false)
    collection.set_viewables(reports: [report_definition.id]) if grant_report
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  describe 'GET /user_directory_report/warehouse_reports/users/warehouse' do
    it 'denies a user who has not been granted this report' do
      sign_in_with(create(:role, can_view_assigned_reports: true))

      get warehouse_user_directory_report_warehouse_reports_users_path

      aggregate_failures do
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end

    it 'denies a user with no report permission at all' do
      sign_in_with(create(:role, can_view_clients: true), grant_report: true)

      get warehouse_user_directory_report_warehouse_reports_users_path

      expect(response).to have_http_status(:redirect)
    end

    it 'denies the xlsx export for a user who has not been granted this report' do
      # The export is a separate format on the same action; a gate that only covered the
      # html path would still leak the whole directory as a spreadsheet.
      sign_in_with(create(:role, can_view_assigned_reports: true))

      get warehouse_user_directory_report_warehouse_reports_users_path(format: :xlsx)

      aggregate_failures do
        expect(response).to have_http_status(:redirect)
        # The action sets an attachment disposition when it builds the spreadsheet, so
        # its absence distinguishes "refused" from "redirected after generating a file".
        expect(response.headers['Content-Disposition']).to be_blank
      end
    end

    it 'allows a user granted the report, and lists directory users' do
      sign_in_with(create(:role, can_view_assigned_reports: true), grant_report: true)

      get warehouse_user_directory_report_warehouse_reports_users_path

      aggregate_failures do
        expect(response).to have_http_status(:success)
        expect(assigns(:users)).to include(listed_user)
      end
    end

    it 'omits inactive users' do
      flag_off = create(:acl_user, active: false)
      sign_in_with(create(:role, can_view_assigned_reports: true), grant_report: true)

      get warehouse_user_directory_report_warehouse_reports_users_path

      aggregate_failures do
        expect(assigns(:users)).to include(listed_user)
        expect(assigns(:users)).not_to include(flag_off)
      end
    end

    # Under Devise the `active` flag is only one of the three things that make a user
    # inactive, so an account whose flag is still set but whose activity has aged out has
    # to be omitted too. The jwt arm's scopes read the flag alone and have no
    # `expire_after`, hence the tag.
    it 'omits a user whose activity has aged out', :devise_only do
      aged_out = create(:acl_user, active: true, last_activity_at: (User.expire_after + 1.day).ago)
      sign_in_with(create(:role, can_view_assigned_reports: true), grant_report: true)

      get warehouse_user_directory_report_warehouse_reports_users_path

      aggregate_failures do
        expect(assigns(:users)).to include(listed_user)
        expect(assigns(:users)).not_to include(aged_out)
      end
    end
  end

  describe 'GET /user_directory_report/warehouse_reports/users/inactive' do
    it 'denies a user who has not been granted this report' do
      # The inactive listing shares the warehouse action's report definition, so the
      # override of related_report has to cover it too.
      sign_in_with(create(:role, can_view_assigned_reports: true))

      get inactive_user_directory_report_warehouse_reports_users_path

      aggregate_failures do
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end

    it 'lists the inactive directory users, and only those' do
      flag_off = create(:acl_user, active: false)
      excluded = create(:acl_user, active: false, exclude_from_directory: true)
      sign_in_with(create(:role, can_view_assigned_reports: true), grant_report: true)

      get inactive_user_directory_report_warehouse_reports_users_path

      aggregate_failures do
        expect(response).to have_http_status(:success)
        expect(assigns(:users)).to include(flag_off)
        expect(assigns(:users)).not_to include(listed_user, excluded)
      end
    end

    # See the warehouse action's aged-out example for why this arm is tagged.
    it 'lists a user whose activity has aged out', :devise_only do
      aged_out = create(:acl_user, active: true, last_activity_at: (User.expire_after + 1.day).ago)
      sign_in_with(create(:role, can_view_assigned_reports: true), grant_report: true)

      get inactive_user_directory_report_warehouse_reports_users_path

      aggregate_failures do
        expect(response).to have_http_status(:success)
        expect(assigns(:users)).to include(aged_out)
        expect(assigns(:users)).not_to include(listed_user)
      end
    end
  end

  describe 'GET /user_directory_report/warehouse_reports/users/cas' do
    it 'denies a user who has not been granted this report' do
      # The cas action shares the warehouse action's report definition, so the override
      # of related_report has to cover it too.
      sign_in_with(create(:role, can_view_assigned_reports: true))

      get cas_user_directory_report_warehouse_reports_users_path

      aggregate_failures do
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end

    # No allow-path example for #cas: the action raises before it renders whenever CAS is
    # not configured, which includes the test environment. `cas_available?` is false, so
    # @users is set to a plain Array and handed to pagy, which needs a relation --
    # NoMethodError: undefined method 'offset' for an instance of Array. That is a
    # pre-existing bug in the action (it predates the authorization gate added here) and
    # is tracked separately; the deny example above is what pins the gate itself.
  end
  describe 'the HMIS access column' do
    # The rendered check. Matched on the full attribute rather than the class name alone,
    # which also appears in the icon sprite's <symbol id="icon-checkmark"> on every page.
    check_markup = %(<i class='icon-checkmark o-color--positive'>)

    let(:granted_role) { create(:role, can_view_assigned_reports: true) }

    # Wires up the user_group -> access_control -> collection -> data source chain that
    # Hmis::User.accessible_hmis_data_source_ids_by_user_id walks.
    def grant_hmis_access(target_user, data_source)
      hmis_collection = create(:hmis_access_group, with_entities: [data_source])
      hmis_user_group = create(:hmis_user_group)
      hmis_user_group.add(target_user.related_hmis_user(data_source))
      create(
        :hmis_access_control,
        role: create(:hmis_role),
        user_group: hmis_user_group,
        access_group: hmis_collection,
      )
    end

    # ENABLE_HMIS_API is set for the spec container, so the gate is stubbed rather than
    # left to the environment, and a data source with a grant on it is created: the
    # column's absence is then attributable to the gate rather than to there being
    # nothing to report.
    it 'is absent when HMIS is not enabled' do
      grant_hmis_access(listed_user, create(:hmis_data_source, name: 'Solo Data Source'))
      allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(false)
      sign_in_with(granted_role, grant_report: true)

      get warehouse_user_directory_report_warehouse_reports_users_path

      aggregate_failures do
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('HMIS Access')
      end
    end

    it 'is absent when HMIS is enabled but no HMIS data source is configured' do
      allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
      sign_in_with(granted_role, grant_report: true)

      get warehouse_user_directory_report_warehouse_reports_users_path

      aggregate_failures do
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('HMIS Access')
      end
    end

    describe 'with a single HMIS data source' do
      before { allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true) }

      # A distinctive name: the factory default is 'HMIS', which also appears in the page
      # title and nav, so an absence-of-name assertion could never fail with it.
      let!(:hmis_data_source) { create(:hmis_data_source, name: 'Solo Data Source') }

      it 'shows a check, and not the data source name, for a user with access' do
        grant_hmis_access(listed_user, hmis_data_source)
        sign_in_with(granted_role, grant_report: true)

        get warehouse_user_directory_report_warehouse_reports_users_path

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(response.body).to include('HMIS Access')
          expect(response.body).to include(check_markup)
          # With one installation the name carries no information, so it is not rendered.
          expect(response.body).not_to include('Solo Data Source')
        end
      end

      it 'shows no check when no user has HMIS access' do
        sign_in_with(granted_role, grant_report: true)

        get warehouse_user_directory_report_warehouse_reports_users_path

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(response.body).to include('HMIS Access')
          expect(response.body).not_to include(check_markup)
        end
      end

      # The inactive listing is the same partial with a different scope, and an inactive
      # user's HMIS access is exactly what a reader auditing that tab is looking for.
      it 'is shown on the inactive listing too' do
        inactive_user = create(:acl_user, active: false)
        grant_hmis_access(inactive_user, hmis_data_source)
        sign_in_with(granted_role, grant_report: true)

        get inactive_user_directory_report_warehouse_reports_users_path

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(assigns(:users)).to include(inactive_user)
          expect(response.body).to include('HMIS Access')
          expect(response.body).to include(check_markup)
        end
      end
    end

    describe 'with several HMIS data sources' do
      before { allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true) }

      let!(:first_data_source) { create(:hmis_data_source) }
      let!(:second_data_source) { create(:hmis_data_source, name: 'Second HMIS') }

      before { grant_hmis_access(listed_user, second_data_source) }

      it 'names each accessible data source instead of showing a check' do
        sign_in_with(granted_role, grant_report: true)

        get warehouse_user_directory_report_warehouse_reports_users_path

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(response.body).to include('Second HMIS')
          expect(response.body).not_to include(check_markup)
        end
      end

      it 'links the name when the reader has both the permission and the grant' do
        sign_in_with(
          # can_view_imports_projects_or_organizations is derived, not a role column;
          # viewable_by requires can_view_projects specifically for an ACL user.
          create(:role, can_view_assigned_reports: true, can_view_projects: true),
          grant_report: true,
        )
        # After sign_in_with, which resets the collection's viewables to the report alone.
        collection.set_viewables(reports: [report_definition.id], data_sources: [second_data_source.id])

        get warehouse_user_directory_report_warehouse_reports_users_path

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(response.body).to include(%(href="#{data_source_path(second_data_source)}"))
        end
      end

      it 'leaves the name unlinked when the reader has the permission but not the grant' do
        # DataSourcesController#show finds through viewable_by, so a link here would raise
        # RecordNotFound for this reader even though the before_action would let them in.
        sign_in_with(
          create(:role, can_view_assigned_reports: true, can_view_projects: true),
          grant_report: true,
        )

        get warehouse_user_directory_report_warehouse_reports_users_path

        aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(response.body).to include('Second HMIS')
          expect(response.body).not_to include(%(href="#{data_source_path(second_data_source)}"))
        end
      end

      it 'leaves the name unlinked when the reader lacks the permission, grant aside' do
        # Pins the permission guard in hmis_data_source_linkable?. That guard exists for
        # legacy (non-ACL) readers, whose viewable_by branch is pure entity visibility with
        # no permission check -- an entity grant alone would otherwise produce a link that
        # show's before_action rejects. It cannot be reproduced with an ACL reader here,
        # since viewable_by's ACL branch returns none without can_view_projects anyway.
        sign_in_with(granted_role, grant_report: true)
        # After sign_in_with, which resets the collection's viewables to the report alone.
        collection.set_viewables(reports: [report_definition.id], data_sources: [second_data_source.id])

        aggregate_failures do
          expect(user.can_view_imports_projects_or_organizations?).to eq(false)

          get warehouse_user_directory_report_warehouse_reports_users_path

          expect(response).to have_http_status(:success)
          expect(response.body).to include('Second HMIS')
          expect(response.body).not_to include(%(href="#{data_source_path(second_data_source)}"))
        end
      end
    end
  end
end
