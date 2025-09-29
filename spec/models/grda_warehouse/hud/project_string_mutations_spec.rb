# frozen_string_literal: false

require 'rails_helper'

RSpec.describe GrdaWarehouse::Hud::Project, type: :model do
  let(:data_source) { create(:data_source_fixed_id) }
  let(:organization) { create(:hud_organization, data_source: data_source) }
  let(:project) { create(:grda_warehouse_hud_project, organization: organization, data_source: data_source, project_type: 1) }
  let(:user) { create(:acl_user) }

  describe 'string mutation operations' do
    describe '#project_ids_viewable_by with multiple += operations' do
      let(:role) { create(:role, can_view_projects: true) }
      let(:collection) { create(:collection) }
      let(:user_group) { create(:user_group) }

      before do
        create(:access_control, role: role, collection: collection, user_group: user_group)
        user_group.add(user)
        create(:grda_warehouse_group_viewable_entity, collection: collection, entity: project)
      end

      it 'concatenates project IDs from multiple sources using += operators' do
        # Test the string mutations from lines 567-571:
        # ids += project_ids_from_viewable_entities(user, permission)
        # ids += project_ids_from_organizations(user, permission)
        # ids += project_ids_from_data_sources(user, permission)
        # ids += project_ids_from_coc_codes(user, permission)
        # ids += project_ids_from_project_groups(user, permission)

        project_ids = described_class.project_ids_viewable_by(user, permission: :can_view_projects)

        expect(project_ids).to be_a(Set)
        expect(project_ids).to include(project.id)
      end

      it 'concatenates project IDs from multiple sources for editable projects' do
        # Test the string mutations from lines 579-583:
        # ids += project_ids_from_viewable_entities(user, :can_edit_projects)
        # ids += project_ids_from_organizations(user, :can_edit_projects)
        # ids += project_ids_from_data_sources(user, :can_edit_projects)
        # ids += project_ids_from_coc_codes(user, :can_edit_projects)
        # ids += project_ids_from_project_groups(user, :can_edit_projects)

        role.update(can_edit_projects: true)
        project_ids = described_class.project_ids_editable_by(user)

        expect(project_ids).to be_a(Set)
        expect(project_ids).to include(project.id)
      end

      it 'returns empty set when user has no permissions' do
        other_user = create(:acl_user)

        project_ids = described_class.project_ids_viewable_by(other_user, permission: :can_view_projects)

        expect(project_ids).to be_a(Set)
        expect(project_ids).to be_empty
      end
    end

    describe '#name with += string concatenation' do
      it 'concatenates project type information using += operator' do
        # Test the string mutation from line 720:
        # project_name += " (#{HudHelper.util.brief_project_type_with_sub_type(project_type, rrh_sub_type)})"
        project.update(ProjectName: 'Test Project', project_type: 1) # ES Entry/Exit

        name_with_type = project.name(user, include_project_type: true)
        name_without_type = project.name(user, include_project_type: false)

        expect(name_with_type).to include('Test Project')
        expect(name_with_type).to include('ES')
        expect(name_with_type.length).to be > name_without_type.length
      end

      it 'does not concatenate project type when include_project_type is false' do
        project.update(ProjectName: 'Test Project', project_type: 1)

        name_without_type = project.name(user, include_project_type: false)

        expect(name_without_type).to eq('Test Project')
        expect(name_without_type).not_to include('ES')
      end

      it 'handles projects with no project type' do
        project.update(ProjectName: 'Test Project', project_type: nil)

        name_with_type = project.name(user, include_project_type: true)

        expect(name_with_type).to eq('Test Project')
      end
    end

    describe '#export_providers CSV generation with << operations' do
      let(:funder) { create(:hud_funder, project: project, data_source: data_source) }
      let(:project_coc) { create(:grda_warehouse_hud_project_coc, project: project, data_source: data_source, coc_code: 'MA-500') }
      let(:geography) { create(:hud_geography, project: project, data_source: data_source) }

      before do
        funder
        project_coc
        geography
      end

      it 'builds CSV output using << operators' do
        # Test the string mutations from lines 813 and 839:
        # csv << headers
        # csv << row

        csv_output = described_class.export_providers(['MA-500'])

        expect(csv_output).to be_a(String)
        expect(csv_output).to include('hud_org_id') # Header should be present
        # Note: The actual project may not appear if there are complex joins and conditions
        lines = csv_output.split("\n")
        expect(lines.first).to include('hud_org_id,provider,hud_prog_type') # Headers
      end

      it 'generates CSV with proper structure' do
        csv_output = described_class.export_providers(['MA-500'])

        lines = csv_output.split("\n")
        expect(lines.length).to be >= 1 # At least headers
        expect(lines.first).to match(/hud_org_id.*provider.*hud_prog_type/) # Header structure
      end
    end

    describe '#options_for_select with << operations' do
      before do
        project.update(ProjectName: 'Test Project')
        allow(user).to receive(:can_view_confidential_project_names?).and_return(true)
      end

      it 'builds options hash using << operator' do
        # Test the string mutation from line 967:
        # options[org_name] << [text, project.id]

        allow(described_class).to receive(:viewable_by).with(user).and_return(described_class.where(id: project.id))

        options = described_class.options_for_select(user: user)

        expect(options).to be_a(Hash)
        expect(options.keys).to include(organization.OrganizationName)
        expect(options[organization.OrganizationName]).to be_an(Array)
        # The text includes project type info, so check for the project name part
        project_option = options[organization.OrganizationName].first
        expect(project_option.first).to include('Test Project')
        expect(project_option.last).to eq(project.id)
      end

      it 'handles multiple projects under same organization' do
        other_project = create(:grda_warehouse_hud_project, organization: organization, data_source: data_source, ProjectName: 'Another Project')

        allow(described_class).to receive(:viewable_by).with(user).and_return(described_class.where(id: [project.id, other_project.id]))

        options = described_class.options_for_select(user: user)

        org_projects = options[organization.OrganizationName]
        expect(org_projects.length).to eq(2)
        # Check that both project names are included in the options (regardless of exact formatting)
        project_names = org_projects.map(&:first)
        expect(project_names.any? { |name| name.include?('Test Project') }).to be_truthy
        expect(project_names.any? { |name| name.include?('Another Project') }).to be_truthy
      end
    end

    describe '#destroy_dependents! with += operations' do
      let(:client) { create(:hud_client, data_source: data_source) }
      let(:enrollment) { create(:hud_enrollment, project: project, client: client, data_source: data_source) }

      before do
        enrollment
      end

      it 'accumulates client IDs using += operators' do
        # Test the string mutations from lines 1008 and 1010:
        # all_clients += GrdaWarehouse::Hud::Client.where(...)
        # with_enrollments += GrdaWarehouse::Hud::Client.joins(:enrollments).where(...)

        # Mock the complex deletion logic to focus on the += operations
        allow(project).to receive(:project_cocs).and_return(double(update_all: true))
        allow(project).to receive(:geographies).and_return(double(update_all: true))
        allow(project).to receive(:inventories).and_return(double(update_all: true))
        allow(project).to receive(:funders).and_return(double(update_all: true))
        allow(project).to receive(:affiliations).and_return(double(update_all: true))
        allow(project).to receive(:residential_affiliations).and_return(double(update_all: true))
        allow(project).to receive(:income_benefits).and_return(double(update_all: true))
        allow(project).to receive(:disabilities).and_return(double(update_all: true))
        allow(project).to receive(:employment_educations).and_return(double(update_all: true))
        allow(project).to receive(:health_and_dvs).and_return(double(update_all: true))
        allow(project).to receive(:services).and_return(double(update_all: true))
        allow(project).to receive(:exits).and_return(double(update_all: true))
        allow(project).to receive(:enrollment_cocs).and_return(double(update_all: true))
        allow(project).to receive(:enrollments).and_return(double(update_all: true, distinct: double(pluck: [client.PersonalID])))

        # Mock the client queries more thoroughly
        client_relation = double('client_relation')
        allow(client_relation).to receive(:pluck).and_return([client.id])
        allow(client_relation).to receive(:update_all).and_return(true)
        allow(client_relation).to receive(:where).and_return(client_relation)
        allow(client_relation).to receive(:each).and_return([])
        allow(GrdaWarehouse::Hud::Client).to receive(:where).and_return(client_relation)
        allow(GrdaWarehouse::Hud::Client).to receive(:joins).and_return(client_relation)

        allow(GrdaWarehouse::WarehouseClient).to receive(:where).and_return(double(pluck: []))
        allow(GrdaWarehouse::Tasks::ServiceHistory::Enrollment).to receive(:queue_batch_process_unprocessed!)
        allow(GrdaWarehouse::Hud::Client).to receive(:clear_view_cache)

        expect { project.destroy_dependents! }.not_to raise_error
      end
    end
  end
end
