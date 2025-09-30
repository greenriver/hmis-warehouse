###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'tempfile'

RSpec.describe AcHmis::ImportCeMatchRules20251001 do
  let!(:organization) { create(:hmis_hud_organization) }
  let!(:project) { create(:hmis_hud_project, organization: organization) }
  let!(:unit_type_1) { create(:hmis_unit_type, description: '1 Bed Room') }
  let!(:unit_type_sro) { create(:hmis_unit_type, description: 'SRO') }
  let!(:unit_group_1) { create(:hmis_unit_group, project: project, unit_type: unit_type_1) }
  let!(:unit_group_sro) { create(:hmis_unit_group, project: project, unit_type: unit_type_sro) }

  def csv_for(rows)
    file = Tempfile.new(['ce_rules', '.csv'])
    file.write("Project Name,Project ID,Unit Group Name,Rule Name,Rule Expression\n")
    rows.each { |r| file.write([r[:project_name], r[:project_id], r[:unit_group_name], r[:rule_name], r[:rule_expression]].join(',') + "\n") }
    file.flush
    file
  end

  describe '#import!' do
    before do
      # Ensure all unit types referenced by the importer mapping exist
      all_unit_type_names = described_class::ASSESSMENT_RESPONSE_TO_UNIT_TYPES.values.flatten.uniq
      all_unit_type_names.each do |name|
        Hmis::UnitType.find_or_create_by!(description: name)
      end
    end

    it 'creates new project-level rules and default unit-group rules, and deletes others' do
      create(:hmis_ce_eligibility_requirement, owner: project, name: 'Old Rule', expression: 'x = 1')

      csv = csv_for([
                      { project_name: project.ProjectName, project_id: project.ProjectID, unit_group_name: nil, rule_name: 'Adults only', rule_expression: 'current_age >= 18' },
                    ])

      importer = described_class.new(csv.path)
      importer.import!

      names = Hmis::Ce::Match::Rule.eligibility_requirement.where(owner: project).pluck(:name)
      expect(names).to include('Adults only')
      expect(names).not_to include('Old Rule')

      # Default unit-group rule for 1 Bed Room should be created
      ug_rules = Hmis::Ce::Match::Rule.eligibility_requirement.where(owner: unit_group_1).pluck(:name)
      expect(ug_rules).to include('Must be referred to 1 Bed')

      # SRO mapping also creates a default rule for SRO group
      sro_rules = Hmis::Ce::Match::Rule.eligibility_requirement.where(owner: unit_group_sro).pluck(:name)
      expect(sro_rules).to include('Must be referred to SRO')
    ensure
      csv&.close!
    end

    it 'skips creating duplicate rules on re-import and keeps existing ones' do
      # First import
      csv1 = csv_for([
                       { project_name: project.ProjectName, project_id: project.ProjectID, unit_group_name: nil, rule_name: 'Adults only', rule_expression: 'current_age >= 18' },
                     ])
      described_class.new(csv1.path).import!

      # Second import with same rule
      csv2 = csv_for([
                       { project_name: project.ProjectName, project_id: project.ProjectID, unit_group_name: nil, rule_name: 'Adults only', rule_expression: 'current_age >= 18' },
                     ])

      expect { described_class.new(csv2.path).import! }.
        not_to(change { Hmis::Ce::Match::Rule.eligibility_requirement.where(owner: project).count })
    ensure
      csv1&.close!
      csv2&.close!
    end

    it 'records errors for unknown projects or unit groups and continues' do
      csv = csv_for([
                      { project_name: 'Missing', project_id: 999999, unit_group_name: nil, rule_name: 'R', rule_expression: 'x' },
                      { project_name: project.ProjectName, project_id: project.ProjectID, unit_group_name: 'Unknown Group', rule_name: 'R2', rule_expression: 'y' },
                    ])

      importer = described_class.new(csv.path)
      expect { importer.import! }.to output(/ERROR: Project with ID 999999 not found/).to_stdout
      expect { importer.import! }.to output(/ERROR: Unit Group 'Unknown Group' not found/).to_stdout
    ensure
      csv&.close!
    end
  end
end
