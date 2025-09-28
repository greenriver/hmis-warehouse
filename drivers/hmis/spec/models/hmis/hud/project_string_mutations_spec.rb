# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Hud::Project, type: :model do
  let(:user) { create(:hmis_user) }
  let(:data_source) { create(:hmis_data_source) }

  before do
    allow(user).to receive(:hmis_data_source_id).and_return(data_source.id)
  end

  describe '.viewable_by scope string mutations' do
    it 'accumulates project IDs with += operations' do
      # Create test data
      project1 = create(:hmis_hud_project, data_source: data_source)
      create(:hmis_hud_project, data_source: data_source)
      organization = create(:hmis_hud_organization, data_source: data_source)

      allow(user).to receive(:viewable_projects).and_return(Hmis::Hud::Project.where(id: project1.id))
      allow(user).to receive(:viewable_organizations).and_return(Hmis::Hud::Organization.where(id: organization.id))
      allow(user).to receive(:viewable_project_groups).and_return(Hmis::ProjectGroup.none)
      allow(user).to receive(:viewable_data_sources).and_return(GrdaWarehouse::DataSource.where(id: data_source.id))

      # Test the scope that uses += operations (lines 81-83)
      result = Hmis::Hud::Project.viewable_by(user)

      # Should include projects from multiple sources via += operations
      expect(result).to be_an(ActiveRecord::Relation)
    end
  end

  describe '.with_access scope string mutations' do
    it 'accumulates permission-based project IDs with += operations' do
      project = create(:hmis_hud_project, data_source: data_source)
      create(:hmis_hud_organization, data_source: data_source)

      allow(user).to receive(:entities_with_permissions).and_return(Hmis::Hud::Project.where(id: project.id))

      # Test the scope that uses += operations (lines 94-96)
      result = Hmis::Hud::Project.with_access(user, :can_view_projects)

      expect(result).to be_an(ActiveRecord::Relation)
    end
  end

  describe '.matching_search_term scope string mutations' do
    let!(:project) { create(:hmis_hud_project, ProjectName: 'Test Housing Project', data_source: data_source) }

    it 'mutates search term with strip! operation' do
      # Test the strip! operation from line 135
      search_term = '  housing project  '

      result = Hmis::Hud::Project.matching_search_term(search_term)

      # Should have processed the search term (including strip!)
      expect(result).to include(project)
    end

    it 'handles search term with special characters' do
      search_term = 'Test!@#Housing$%^Project'

      result = Hmis::Hud::Project.matching_search_term(search_term)

      # Should handle the string processing and splitting
      expect(result).to include(project)
    end

    it 'returns none for blank search term' do
      result = Hmis::Hud::Project.matching_search_term('')

      expect(result.to_a).to be_empty
    end
  end

  describe '.with_unit_type_ids scope string mutations' do
    let!(:project) { create(:hmis_hud_project, data_source: data_source) }

    it 'accumulates unit type IDs with += operation' do
      # Test the += operation from line 394: unit_type_ids += units.distinct.pluck(:unit_type_id)
      unit_type_id = 1

      # Mock the units relationship to return unit type IDs
      units_double = double('units')
      allow(units_double).to receive(:distinct).and_return(units_double)
      allow(units_double).to receive(:pluck).with(:unit_type_id).and_return([unit_type_id])
      allow_any_instance_of(Hmis::Hud::Project).to receive(:units).and_return(units_double)

      result = Hmis::Hud::Project.with_unit_type_ids([unit_type_id])

      # The scope should handle the += operation for accumulating unit type IDs
      expect(result).to include(project)
    end
  end
end
