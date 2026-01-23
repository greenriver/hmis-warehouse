###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::DefaultSwimlaneAssignment, type: :model do
  let!(:ds1) { create :hmis_data_source }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1 }
  let!(:o2) { create :hmis_hud_organization, data_source: ds1 }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1 }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o2 }

  let!(:user1) { create :hmis_user, data_source: ds1 }
  let!(:user2) { create :hmis_user, data_source: ds1 }

  let!(:template) { create :hmis_workflow_definition_template, data_source: ds1 }
  let!(:swimlane1) { create :hmis_workflow_definition_swimlane, template: template, name: 'CE Staff' }
  let!(:swimlane2) { create :hmis_workflow_definition_swimlane, template: template, name: 'Providers' }
  let!(:unit_group) { create :hmis_unit_group, project: p1, workflow_template: template }

  describe 'scopes' do
    describe '.for_project' do
      context 'with only project-level assignments' do
        let!(:assignment) { create :hmis_ce_default_swimlane_assignment, user: user1, swimlane: swimlane1, owner: p1 }
        let!(:other_assignment) { create :hmis_ce_default_swimlane_assignment, user: user1, swimlane: swimlane1, owner: p2 }

        it 'returns only assignments owned by the project' do
          result = described_class.for_project(p1)
          expect(result).to contain_exactly(assignment)
          expect(result).not_to include(other_assignment)
        end
      end

      context 'with mixed-level assignments' do
        let!(:assignment_p1) { create :hmis_ce_default_swimlane_assignment, user: user1, swimlane: swimlane1, owner: p1 }
        let!(:assignment_o1) { create :hmis_ce_default_swimlane_assignment, user: user2, swimlane: swimlane2, owner: o1 }
        let!(:assignment_ds1) { create :hmis_ce_default_swimlane_assignment, :for_data_source, user: user1, swimlane: swimlane2, owner: ds1 }
        let!(:assignment_p2) { create :hmis_ce_default_swimlane_assignment, user: user1, swimlane: swimlane1, owner: p2 }

        it 'returns all assignments from project, organization, and data source' do
          result = described_class.for_project(p1)
          expect(result).to contain_exactly(assignment_p1, assignment_o1, assignment_ds1)
          expect(result).not_to include(assignment_p2)
        end
      end

      context 'with no assignments at any level' do
        it 'returns empty' do
          result = described_class.for_project(p1)
          expect(result).to be_empty
        end
      end

      context 'with same user assigned at multiple levels for the same swimlane' do
        let!(:assignment_p1) { create :hmis_ce_default_swimlane_assignment, user: user1, swimlane: swimlane1, owner: p1 }
        let!(:assignment_o1) { create :hmis_ce_default_swimlane_assignment, user: user1, swimlane: swimlane1, owner: o1 }
        let!(:assignment_ds1) { create :hmis_ce_default_swimlane_assignment, :for_data_source, user: user1, swimlane: swimlane1, owner: ds1 }

        it 'returns all assignments' do
          result = described_class.for_project(p1)
          expect(result).to contain_exactly(assignment_p1, assignment_o1, assignment_ds1)
        end
      end

      context 'with a global default contact for a swimlane not used by this project' do
        let!(:other_template) { create :hmis_workflow_definition_template, data_source: ds1 }
        let!(:swimlane3) { create :hmis_workflow_definition_swimlane, template: other_template, name: 'CE Staff' }
        let!(:assignment) { create :hmis_ce_default_swimlane_assignment, user: user1, swimlane: swimlane3, owner: ds1 }

        it 'does not return the irrelevant assignment' do
          result = described_class.for_project(p1)
          expect(result).not_to include(assignment)
        end
      end
    end
  end
end
