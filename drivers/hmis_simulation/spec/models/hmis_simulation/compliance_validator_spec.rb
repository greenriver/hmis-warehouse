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
