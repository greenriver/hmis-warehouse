###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudApr::Generators::Shared::Fy2026::QuestionFour do
  let(:report) { create(:hud_reports_report_instance) }
  let!(:data_source) { create(:source_data_source) }
  let(:project) { create(:grda_warehouse_hud_project, data_source: data_source) }
  let(:generator) { HudApr::Generators::Apr::Fy2026::Generator.new(report) }
  let(:question) { described_class.new(generator, report) }

  describe '#detect_ce_participation' do
    let(:report_start_date) { Date.new(2024, 1, 1) }
    let(:report_end_date) { Date.new(2024, 12, 31) }

    before do
      allow(report).to receive(:start_date).and_return(report_start_date)
      allow(report).to receive(:end_date).and_return(report_end_date)
    end

    context 'when project has no operating end date' do
      before do
        allow(project).to receive(:operating_end_date).and_return(nil)
      end

      it 'uses report end date as effective date' do
        ce_participation = create(
          :grda_warehouse_hud_ce_participation,
          project: project,
          CEParticipationStatusStartDate: report_start_date,
          CEParticipationStatusEndDate: report_end_date,
          AccessPoint: 1,
        )

        result = question.detect_ce_participation(project)
        expect(result).to eq(ce_participation)
      end
    end

    context 'when project has operating end date within report period' do
      let(:operating_end_date) { Date.new(2024, 6, 30) }

      before do
        allow(project).to receive(:operating_end_date).and_return(operating_end_date)
      end

      it 'uses operating end date as effective date' do
        ce_participation = create(
          :grda_warehouse_hud_ce_participation,
          project: project,
          CEParticipationStatusStartDate: report_start_date,
          CEParticipationStatusEndDate: operating_end_date,
          AccessPoint: 1,
        )

        result = question.detect_ce_participation(project)
        expect(result).to eq(ce_participation)
      end
    end

    context 'when multiple CE participation records exist' do
      let(:operating_end_date) { Date.new(2024, 6, 30) }

      before do
        allow(project).to receive(:operating_end_date).and_return(operating_end_date)
      end

      it 'selects the record with most recent end date' do
        _older_record = create(
          :grda_warehouse_hud_ce_participation,
          project: project,
          CEParticipationStatusStartDate: report_start_date,
          CEParticipationStatusEndDate: Date.new(2024, 5, 31),
          AccessPoint: 0,
        )

        newer_record = create(
          :grda_warehouse_hud_ce_participation,
          project: project,
          CEParticipationStatusStartDate: report_start_date,
          CEParticipationStatusEndDate: operating_end_date,
          AccessPoint: 1,
        )

        result = question.detect_ce_participation(project)
        expect(result).to eq(newer_record)
      end

      it 'handles missing end dates by using start dates' do
        no_end_date = create(
          :grda_warehouse_hud_ce_participation,
          project: project,
          CEParticipationStatusStartDate: Date.new(2024, 6, 1),
          CEParticipationStatusEndDate: nil,
          AccessPoint: 0,
        )

        _with_end_date = create(
          :grda_warehouse_hud_ce_participation,
          project: project,
          CEParticipationStatusStartDate: Date.new(2024, 5, 1),
          CEParticipationStatusEndDate: Date.new(2024, 5, 31),
          AccessPoint: 1,
        )

        result = question.detect_ce_participation(project)
        expect(result).to eq(no_end_date)
      end
    end

    context 'when no CE participation records exist' do
      it 'returns nil' do
        result = question.detect_ce_participation(project)
        expect(result).to be_nil
      end
    end
  end
end

RSpec.describe HudApr::Generators::CeApr::Fy2026::QuestionFour do
  let(:report) { create(:hud_reports_report_instance) }
  let!(:data_source) { create(:source_data_source) }
  let(:generator) { HudApr::Generators::CeApr::Fy2026::Generator.new(report) }
  let(:question) { described_class.new(generator, report) }

  describe '#q4_project_scope' do
    context 'when active_project_ids is empty (fallback path)' do
      before do
        allow(generator).to receive(:active_project_ids).and_return([])
      end

      it 'excludes projects where ContinuumProject = 0' do
        project = create(:grda_warehouse_hud_project, data_source: data_source, ContinuumProject: 0)
        allow(report).to receive(:project_ids).and_return([project.id])

        result = question.send(:q4_project_scope)
        expect(result.pluck(:id)).not_to include(project.id)
      end

      it 'excludes projects where ContinuumProject is nil' do
        project = create(:grda_warehouse_hud_project, data_source: data_source, ContinuumProject: nil)
        allow(report).to receive(:project_ids).and_return([project.id])

        result = question.send(:q4_project_scope)
        expect(result.pluck(:id)).not_to include(project.id)
      end

      it 'includes projects where ContinuumProject = 1' do
        project = create(:grda_warehouse_hud_project, data_source: data_source, ContinuumProject: 1)
        allow(report).to receive(:project_ids).and_return([project.id])

        result = question.send(:q4_project_scope)
        expect(result.pluck(:id)).to include(project.id)
      end
    end

    context 'when active_project_ids is non-empty (normal path)' do
      it 'excludes projects where ContinuumProject = 0 even when returned by active_project_ids' do
        non_continuum = create(:grda_warehouse_hud_project, data_source: data_source, ContinuumProject: 0)
        continuum = create(:grda_warehouse_hud_project, data_source: data_source, ContinuumProject: 1)
        allow(generator).to receive(:active_project_ids).and_return([non_continuum.id, continuum.id])
        allow(report).to receive(:project_ids).and_return([non_continuum.id, continuum.id])

        result = question.send(:q4_project_scope)
        expect(result.pluck(:id)).not_to include(non_continuum.id)
        expect(result.pluck(:id)).to include(continuum.id)
      end
    end
  end
end
