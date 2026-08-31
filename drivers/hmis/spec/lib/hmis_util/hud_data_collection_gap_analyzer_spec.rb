###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisUtil::HudDataCollectionGapAnalyzer do
  subject(:analyzer) { described_class.new(data_source: data_source, date_range: date_range) }

  let(:date_range) { Date.new(2025, 1, 1)..Date.new(2025, 12, 31) }
  let(:data_source) { create(:grda_warehouse_data_source) }
  let(:hud) { HudHelper.util }
  let(:path_funder) do
    hud.funding_source('HHS: PATH - Street Outreach & Supportive Services Only', true, raise_on_missing: true)
  end
  let(:bed_night_record_type) { hud.record_type('Bed Night', true, raise_on_missing: true) }

  # ES Entry/Exit, funded by nothing HUD requires HOPWA or PATH collection for.
  def build_project(project_type: 2, operating_start: Date.new(2024, 1, 1), operating_end: nil, funders: [])
    project = create(
      :hud_project,
      data_source_id: data_source.id,
      ProjectType: project_type,
      OperatingStartDate: operating_start,
      OperatingEndDate: operating_end,
    )
    funders.each do |code|
      create(
        :hud_funder,
        data_source_id: data_source.id,
        ProjectID: project.ProjectID,
        Funder: code,
        StartDate: Date.new(2024, 1, 1),
      )
    end
    project
  end

  def enroll(project)
    create(:hud_enrollment, data_source_id: data_source.id, ProjectID: project.ProjectID)
  end

  describe 'project universe' do
    it 'includes an in-window project that has no funder records' do
      project = build_project(funders: [])

      ids = analyzer.perform.summary_rows.map { |row| row[:project_id] }

      expect(ids).to contain_exactly(project.id)
    end

    it 'includes a project with an open-ended operating period and one with no operating dates' do
      open_ended = build_project(operating_start: Date.new(2024, 1, 1), operating_end: nil)
      undated = build_project(operating_start: nil, operating_end: nil)

      ids = analyzer.perform.summary_rows.map { |row| row[:project_id] }

      expect(ids).to contain_exactly(open_ended.id, undated.id)
    end

    it 'excludes a project whose operating period closed before the window' do
      build_project(operating_start: Date.new(2020, 1, 1), operating_end: Date.new(2024, 6, 1))

      expect(analyzer.perform.summary_rows).to be_empty
    end

    it 'excludes projects in another data source' do
      other_source = create(:grda_warehouse_data_source)
      create(:hud_project, data_source_id: other_source.id, ProjectType: 2, OperatingStartDate: Date.new(2024, 1, 1))
      mine = build_project

      ids = analyzer.perform.summary_rows.map { |row| row[:project_id] }

      expect(ids).to contain_exactly(mine.id)
    end
  end

  describe 'field-level gaps' do
    # Verified against the real evaluator at project type 2 (ES Entry/Exit):
    #   no funders     -> income and HOPWA elements both absent from the form
    #   HUD: CoC - PSH -> income present, HOPWA viral load still absent
    #   HUD: HOPWA     -> viral load present
    # Each pair below holds the data constant and varies only the funder, so the HUD rule
    # evaluation is the only thing that can explain the difference.
    let(:coc_psh_funder) do
      hud.funding_source('HUD: CoC - Permanent Supportive Housing', true, raise_on_missing: true)
    end
    let(:hopwa_funder) { hud.funder_components.fetch('HUD: HOPWA').first }

    def add_viral_load(project)
      enrollment = enroll(project)
      create(
        :hud_disability,
        data_source_id: data_source.id,
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: enrollment.PersonalID,
        InformationDate: Date.new(2025, 5, 1),
        DisabilityType: 8,
        ViralLoad: 400,
      )
    end

    def add_income(project)
      enrollment = enroll(project)
      create(
        :hud_income_benefit,
        data_source_id: data_source.id,
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: enrollment.PersonalID,
        InformationDate: Date.new(2025, 5, 1),
        IncomeFromAnySource: 1,
      )
    end

    it 'reports a gap when viral load data exists but HUD does not require the element' do
      project = build_project(funders: [coc_psh_funder])
      add_viral_load(project)

      gaps = analyzer.perform.field_gap_rows.select { |row| row[:field_name] == 'viralLoad' }

      expect(gaps.first).to include(
        project_id: project.id,
        record_type: 'DISABILITY_GROUP',
        link_id: 'W4_C',
        count: 1,
        earliest: Date.new(2025, 5, 1),
      )
    end

    it 'reports no viral load gap for a HOPWA-funded project, where HUD requires it' do
      project = build_project(funders: [hopwa_funder])
      add_viral_load(project)

      field_names = analyzer.perform.field_gap_rows.map { |row| row[:field_name] }

      expect(field_names).not_to include('viralLoad')
    end

    it 'reports an income gap for an unfunded project that records income' do
      project = build_project(funders: [])
      add_income(project)

      gaps = analyzer.perform.field_gap_rows.select { |row| row[:field_name] == 'incomeFromAnySource' }

      expect(gaps.first).to include(project_id: project.id, count: 1)
    end

    it 'reports no income gap for a CoC-funded project, where HUD requires income' do
      project = build_project(funders: [coc_psh_funder])
      add_income(project)

      field_names = analyzer.perform.field_gap_rows.map { |row| row[:field_name] }

      expect(field_names).not_to include('incomeFromAnySource')
    end

    it 'reports no gap for an element with no data at all' do
      project = build_project(funders: [coc_psh_funder])
      enroll(project)

      field_names = analyzer.perform.field_gap_rows.map { |row| row[:field_name] }

      expect(field_names).not_to include('viralLoad')
    end
  end

  describe 'form-level gaps' do
    it 'reports a Bed Night gap for a non-NbN project that records bed nights' do
      project = build_project(project_type: 2)
      enrollment = enroll(project)
      create(
        :hud_service,
        data_source_id: data_source.id,
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: enrollment.PersonalID,
        DateProvided: Date.new(2025, 5, 1),
        RecordType: bed_night_record_type,
      )

      gaps = analyzer.perform.form_gap_rows

      expect(gaps.map { |row| row[:record_type] }).to include(bed_night_record_type)
    end

    it 'reports no Bed Night gap for an ES NbN project, where HUD requires it' do
      project = build_project(project_type: 1)
      enrollment = enroll(project)
      create(
        :hud_service,
        data_source_id: data_source.id,
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: enrollment.PersonalID,
        DateProvided: Date.new(2025, 5, 1),
        RecordType: bed_night_record_type,
      )

      gaps = analyzer.perform.form_gap_rows

      expect(gaps.map { |row| row[:record_type] }).not_to include(bed_night_record_type)
    end

    it 'reports a CLS gap for a project with situations but no CLS requirement' do
      project = build_project(project_type: 2, funders: [])
      enrollment = enroll(project)
      create(
        :hud_current_living_situation,
        data_source_id: data_source.id,
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: enrollment.PersonalID,
        InformationDate: Date.new(2025, 5, 1),
      )

      gaps = analyzer.perform.form_gap_rows.select { |row| row[:form] == 'Current Living Situation' }

      expect(gaps.first).to include(project_id: project.id, count: 1)
    end

    it 'reports no CLS gap for a PATH-funded project, where HUD requires CLS' do
      project = build_project(project_type: 4, funders: [path_funder])
      enrollment = enroll(project)
      create(
        :hud_current_living_situation,
        data_source_id: data_source.id,
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: enrollment.PersonalID,
        InformationDate: Date.new(2025, 5, 1),
      )

      gaps = analyzer.perform.form_gap_rows.select { |row| row[:form] == 'Current Living Situation' }

      expect(gaps).to be_empty
    end
  end
end
