###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::ComplianceValidator do
  let!(:data_source) { create(:hmis_data_source) }

  before { User.setup_system_user }

  subject(:validator) { described_class.new(data_source_id: data_source.id) }

  def violation_types(violations)
    violations.map { |v| v[:type] }
  end

  describe '#validate! — project-level checks' do
    context 'when a project is missing HmisParticipation' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 0) }

      it 'reports a missing_hmis_participation violation' do
        expect(violation_types(validator.validate!)).to include(:missing_hmis_participation)
      end

      it 'includes the project name in the violation' do
        violation = validator.validate!.find { |v| v[:type] == :missing_hmis_participation }
        expect(violation[:project_name]).to eq(project.ProjectName)
      end
    end

    context 'when a project has HmisParticipation' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 0) }
      let!(:_participation) do
        create(:hmis_hud_hmis_participation, data_source: data_source, project: project)
      end

      it 'does not report an hmis_participation violation for that project' do
        expect(violation_types(validator.validate!)).not_to include(:missing_hmis_participation)
      end
    end

    context 'when a CE project is missing CeParticipation' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 14) }
      let!(:_hmis_participation) do
        create(:hmis_hud_hmis_participation, data_source: data_source, project: project)
      end

      it 'reports a missing_ce_participation violation' do
        expect(violation_types(validator.validate!)).to include(:missing_ce_participation)
      end
    end

    context 'when a CE project has CeParticipation' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 14) }
      let!(:_hmis_participation) do
        create(:hmis_hud_hmis_participation, data_source: data_source, project: project)
      end
      let!(:_ce_participation) do
        create(:hmis_hud_ce_participation, data_source: data_source, project: project)
      end

      it 'does not report a ce_participation violation' do
        expect(violation_types(validator.validate!)).not_to include(:missing_ce_participation)
      end
    end

    context 'when a non-CE project has no CeParticipation' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 3) }
      let!(:_participation) do
        create(:hmis_hud_hmis_participation, data_source: data_source, project: project)
      end

      it 'does not report a ce_participation violation' do
        expect(violation_types(validator.validate!)).not_to include(:missing_ce_participation)
      end
    end
  end

  describe '#validate! — enrollment-level checks' do
    context 'when an SO enrollment is missing DateOfEngagement' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 4) }
      let!(:_enrollment) do
        create(
          :hmis_hud_enrollment,
          data_source: data_source,
          project: project,
          DateOfEngagement: nil,
        )
      end

      it 'reports a missing_date_of_engagement violation' do
        expect(violation_types(validator.validate!)).to include(:missing_date_of_engagement)
      end
    end

    context 'when an SO enrollment has DateOfEngagement' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 4) }
      let!(:_enrollment) do
        create(
          :hmis_hud_enrollment,
          data_source: data_source,
          project: project,
          DateOfEngagement: Date.current,
        )
      end

      it 'does not report a date_of_engagement violation' do
        expect(violation_types(validator.validate!)).not_to include(:missing_date_of_engagement)
      end
    end

    context 'when a non-SO enrollment is missing DateOfEngagement' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 3) }
      let!(:_enrollment) do
        create(
          :hmis_hud_enrollment,
          data_source: data_source,
          project: project,
          DateOfEngagement: nil,
        )
      end

      it 'does not report a date_of_engagement violation' do
        expect(violation_types(validator.validate!)).not_to include(:missing_date_of_engagement)
      end
    end

    context 'when an enrollment is missing LivingSituation' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 1) }
      let!(:_enrollment) do
        create(
          :hmis_hud_enrollment,
          data_source: data_source,
          project: project,
          LivingSituation: nil,
        )
      end

      it 'reports a missing_living_situation violation' do
        expect(violation_types(validator.validate!)).to include(:missing_living_situation)
      end
    end

    context 'when an enrollment has LivingSituation set' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 1) }
      let!(:_enrollment) do
        create(
          :hmis_hud_enrollment,
          data_source: data_source,
          project: project,
          LivingSituation: 116,
        )
      end

      it 'does not report a living_situation violation' do
        expect(violation_types(validator.validate!)).not_to include(:missing_living_situation)
      end
    end
  end

  describe '#validate! — inventory checks' do
    context 'when a residential project is missing an Inventory record' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 1) }
      let!(:_participation) { create(:hmis_hud_hmis_participation, data_source: data_source, project: project) }

      it 'reports a missing_inventory violation' do
        expect(violation_types(validator.validate!)).to include(:missing_inventory)
      end

      it 'includes the project name in the violation' do
        violation = validator.validate!.find { |v| v[:type] == :missing_inventory }
        expect(violation[:project_name]).to eq(project.ProjectName)
      end
    end

    context 'when a residential project has an Inventory record' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 1) }
      let!(:_participation) { create(:hmis_hud_hmis_participation, data_source: data_source, project: project) }
      let!(:_project_coc) { create(:hmis_hud_project_coc, data_source: data_source, project: project) }
      let!(:_inventory) { create(:hmis_hud_inventory, data_source: data_source, project: project) }

      it 'does not report a missing_inventory violation' do
        expect(violation_types(validator.validate!)).not_to include(:missing_inventory)
      end
    end

    context 'when a non-residential project (SO) has no Inventory' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 4) }
      let!(:_participation) { create(:hmis_hud_hmis_participation, data_source: data_source, project: project) }

      it 'does not report a missing_inventory violation' do
        expect(violation_types(validator.validate!)).not_to include(:missing_inventory)
      end
    end
  end

  describe '#validate! — employment education checks' do
    context 'when a residential enrollment has no EmploymentEducation at entry' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 1) }
      let!(:_participation) { create(:hmis_hud_hmis_participation, data_source: data_source, project: project) }
      let!(:_project_coc) { create(:hmis_hud_project_coc, data_source: data_source, project: project) }
      let!(:_inventory) { create(:hmis_hud_inventory, data_source: data_source, project: project) }
      let!(:_enrollment) do
        create(:hmis_hud_enrollment, data_source: data_source, project: project, LivingSituation: 116)
      end

      it 'reports a missing_employment_education violation' do
        expect(violation_types(validator.validate!)).to include(:missing_employment_education)
      end
    end

    context 'when a residential enrollment has an entry EmploymentEducation' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 1) }
      let!(:_participation) { create(:hmis_hud_hmis_participation, data_source: data_source, project: project) }
      let!(:_project_coc) { create(:hmis_hud_project_coc, data_source: data_source, project: project) }
      let!(:_inventory) { create(:hmis_hud_inventory, data_source: data_source, project: project) }
      let!(:client) { create(:hmis_hud_client, data_source: data_source) }
      let!(:enrollment) do
        create(:hmis_hud_enrollment, data_source: data_source, project: project,
                                     client: client, LivingSituation: 116)
      end
      let!(:_ee) do
        create(:hmis_employment_education, data_source: data_source, enrollment: enrollment,
                                           client: client, data_collection_stage: 1)
      end

      it 'does not report a missing_employment_education violation' do
        expect(violation_types(validator.validate!)).not_to include(:missing_employment_education)
      end
    end

    context 'when a non-residential enrollment (SO) has no EmploymentEducation' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 4) }
      let!(:_participation) { create(:hmis_hud_hmis_participation, data_source: data_source, project: project) }
      let!(:_enrollment) do
        create(:hmis_hud_enrollment, data_source: data_source, project: project, LivingSituation: 116)
      end

      it 'does not report a missing_employment_education violation' do
        expect(violation_types(validator.validate!)).not_to include(:missing_employment_education)
      end
    end
  end

  describe '#validate! — CE assessment checks' do
    context 'when a CE enrollment has no Assessment' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 14) }
      let!(:_hmis_participation) { create(:hmis_hud_hmis_participation, data_source: data_source, project: project) }
      let!(:_ce_participation) { create(:hmis_hud_ce_participation, data_source: data_source, project: project) }
      let!(:_enrollment) do
        create(:hmis_hud_enrollment, data_source: data_source, project: project, LivingSituation: 116)
      end

      it 'reports a missing_ce_assessment violation' do
        expect(violation_types(validator.validate!)).to include(:missing_ce_assessment)
      end
    end

    context 'when a CE enrollment has an Assessment' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 14) }
      let!(:_hmis_participation) { create(:hmis_hud_hmis_participation, data_source: data_source, project: project) }
      let!(:_ce_participation) { create(:hmis_hud_ce_participation, data_source: data_source, project: project) }
      let!(:client) { create(:hmis_hud_client, data_source: data_source) }
      let!(:enrollment) do
        create(:hmis_hud_enrollment, data_source: data_source, project: project,
                                     client: client, LivingSituation: 116)
      end
      let!(:_assessment) do
        create(:hmis_hud_assessment, data_source: data_source, enrollment: enrollment, client: client)
      end

      it 'does not report a missing_ce_assessment violation' do
        expect(violation_types(validator.validate!)).not_to include(:missing_ce_assessment)
      end
    end

    context 'when a non-CE enrollment has no Assessment' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 1) }
      let!(:_participation) { create(:hmis_hud_hmis_participation, data_source: data_source, project: project) }
      let!(:_project_coc) { create(:hmis_hud_project_coc, data_source: data_source, project: project) }
      let!(:_inventory) { create(:hmis_hud_inventory, data_source: data_source, project: project) }
      let!(:client) { create(:hmis_hud_client, data_source: data_source) }
      let!(:enrollment) do
        create(:hmis_hud_enrollment, data_source: data_source, project: project,
                                     client: client, LivingSituation: 116)
      end
      let!(:_ee) do
        create(:hmis_employment_education, data_source: data_source, enrollment: enrollment,
                                           client: client, data_collection_stage: 1)
      end

      it 'does not report a missing_ce_assessment violation' do
        expect(violation_types(validator.validate!)).not_to include(:missing_ce_assessment)
      end
    end
  end

  describe '#validate!' do
    it 'returns an Array' do
      expect(validator.validate!).to be_an(Array)
    end

    it 'returns an empty array when there are no projects or enrollments' do
      expect(validator.validate!).to be_empty
    end

    it 'each violation has required keys' do
      create(:hmis_hud_project, data_source: data_source, ProjectType: 0)
      violations = validator.validate!
      violations.each do |v|
        expect(v).to include(:type, :message)
      end
    end
  end
end
