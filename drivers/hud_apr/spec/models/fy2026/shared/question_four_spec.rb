###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
