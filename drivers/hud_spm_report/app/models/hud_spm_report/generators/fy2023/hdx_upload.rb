###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Measure 2a and 2b: The Extent to which Persons Who Exit Homelessness
# to Permanent Housing Destinations Return to Homelessness within 6, 12,
# and 24 months.
module HudSpmReport::Generators::Fy2023
  class HdxUpload < MeasureBase
    def self.question_number
      'HDX Upload'.freeze
    end

    def self.table_descriptions
      {
        'HDX Upload': 'CSV Upload for HDX 2.0',
      }.freeze
    end

    def run_question!
      tables = [
        ['csv', :run_csv],
      ]

      @report.start(self.class.question_number, tables.map(&:first))

      tables.each do |name, msg|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    ROWS = {
      1 => 'Variable Name',
      2 => 'Variable Value',
    }.freeze

    COLUMNS = {
      A: ['CocCode', :metadata],
      B: ['ReportDateTime', :metadata],
      C: ['ReportStartDate', :metadata],
      D: ['ReportEndDate', :metadata],
      E: ['SoftwareName', :metadata],
      F: ['SourceContactFirst', :metadata],
      G: ['SourceContactLast', :metadata],
      H: ['SourceContactEmail', :metadata],

      I: ['ESSHUniverse_1A', :spm, '1a', :B1],
      J: ['ESSHAvgTime_1A', :spm, '1a', :D1],
      K: ['ESSHMedianTime_1A', :spm, '1a', :G1],
      L: ['ESSHTHUniverse_1A', :spm, '1a', :B2],
      M: ['ESSHTHAvgTime_1A', :spm, '1a', :D2],
      N: ['ESSHTHMedianTime_1A', :spm, '1a', :G2],

      O: ['ESSHUniverse_1B', :spm, '1b', :B1],
      P: ['ESSHAvgTime_1B', :spm, '1b', :D1],
      Q: ['ESSHMedianTime_1B', :spm, '1b', :G1],
      R: ['ESSHTHUniverse_1B', :spm, '1b', :B2],
      S: ['ESSHTHAvgTime_1B', :spm, '1b', :D2],
      T: ['ESSHTHMedianTime_1B', :spm, '1b', :G2],

      U: ['SOExitPH_2', :spm, '2a and 2b', :B2],
      V: ['SOReturn0to180_2', :spm, '2a and 2b', :C2],
      W: ['SOReturn181to365_2', :spm, '2a and 2b', :E2],
      X: ['SOReturn366to730_2', :spm, '2a and 2b', :G2],
      Y: ['ESExitPH_2', :spm, '2a and 2b', :B3],
      Z: ['ESReturn0to180_2', :spm, '2a and 2b', :C3],
      AA: ['ESReturn181to365_2', :spm, '2a and 2b', :E3],
      AB: ['ESReturn366to730_2', :spm, '2a and 2b', :G3],
      AC: ['THExitPH_2', :spm, '2a and 2b', :B4],
      AD: ['THReturn0to180_2', :spm, '2a and 2b', :C4],
      AE: ['THReturn181to365_2', :spm, '2a and 2b', :E4],
      AF: ['THReturn366to730_2', :spm, '2a and 2b', :G4],
      AG: ['SHExitPH_2', :spm, '2a and 2b', :B5],
      AH: ['SHReturn0to180_2', :spm, '2a and 2b', :C5],
      AI: ['SHReturn181to365_2', :spm, '2a and 2b', :E5],
      AJ: ['SHReturn366to730_2', :spm, '2a and 2b', :G5],
      AK: ['PHExitPH_2', :spm, '2a and 2b', :B6],
      AL: ['PHReturn0to180_2', :spm, '2a and 2b', :C6],
      AM: ['PHReturn181to365_2', :spm, '2a and 2b', :E6],
      AN: ['PHReturn366to730_2', :spm, '2a and 2b', :G6],

      AO: ['TotalAnnual_3', :spm, '3.2', :C2],
      AP: ['ESAnnual_3', :spm, '3.2', :C3],
      AQ: ['SHAnnual_3', :spm, '3.2', :C4],
      AR: ['THAnnual_3', :spm, '3.2', :C5],

      AS: ['AdultStayers_4', :spm, '4.1', :C2],
      AT: ['IncreaseEarned4_1', :spm, '4.1', :C3],

      AU: ['IncreaseOther4_2', :spm, '4.2', :C3],

      AV: ['IncreaseTotal4_3', :spm, '4.3', :C3],

      AW: ['AdultLeavers_4', :spm, '4.4', :C2],
      AX: ['IncreaseEarned4_4', :spm, '4.4', :C3],

      AY: ['IncreaseOther4_5', :spm, '4.5', :C3],

      AZ: ['IncreaseTotal4_6', :spm, '4.6', :C3],

      BA: ['EnterESSHTH5_1', :spm, '5.1', :C2],
      BB: ['ESSHTHWithPriorSvc5_1', :spm, '5.1', :C3],

      BC: ['EnterESSHTHPH5_2', :spm, '5.2', :C2],
      BD: ['ESSHTHPHWithPriorSvc5_2', :spm, '5.2', :C3],

      BE: ['THExitPH_6', :spm, '6a.1 and 6b.1', :B4],
      BF: ['THReturn0to180_6', :spm, '6a.1 and 6b.1', :C4],
      BG: ['THReturn181to365_6', :spm, '6a.1 and 6b.1', :E4],
      BH: ['THReturn366to730_6', :spm, '6a.1 and 6b.1', :G4],
      BI: ['SHExitPH_6', :spm, '6a.1 and 6b.1', :B5],
      BJ: ['SHReturn0to180_6', :spm, '6a.1 and 6b.1', :C5],
      BK: ['SHReturn181to365_6', :spm, '6a.1 and 6b.1', :E5],
      BL: ['SHReturn366to730_6', :spm, '6a.1 and 6b.1', :G5],
      BM: ['PHExitPH_6', :spm, '6a.1 and 6b.1', :B6],
      BN: ['PHReturn0to180_6', :spm, '6a.1 and 6b.1', :C6],
      BO: ['PHReturn181to365_6', :spm, '6a.1 and 6b.1', :E6],
      BP: ['PHReturn366to730_6', :spm, '6a.1 and 6b.1', :G6],

      BQ: ['SHTHRRHCat3Leavers_6', :spm, '6c.1', :C2],
      BR: ['SHTHRRHCat3ExitPH_6', :spm, '6c.1', :C3],

      BS: ['PSHCat3Clients_6', :spm, '6c.2', :C2],
      BT: ['PSHCat3StayOrExitPH_6', :spm, '6c.2', :C3],

      BU: ['SOExit_7', :spm, '7a.1', :C2],
      BV: ['SOExitTempInst_7', :spm, '7a.1', :C3],
      BW: ['SOExitPH_7', :spm, '7a.1', :C4],

      BX: ['ESSHTHRRHExit_7', :spm, '7b.1', :C2],
      BY: ['ESSHTHRRHToPH_7', :spm, '7b.1', :C3],

      BZ: ['PHClients_7', :spm, '7b.2', :C2],
      CA: ['PHClientsStayOrExitPH_7', :spm, '7b.2', :C3],

      CB: ['ESSH_UndupHMIS_DQ', :essh, 'Q1', :B2],
      CC: ['TH_UndupHMIS_DQ', :th, 'Q1', :B2],
      CD: ['PSHOPH_UndupHMIS_DQ', :pshoph, 'Q1', :B2],
      CE: ['RRH_UndupHMIS_DQ', :rrh, 'Q1', :B2],
      CF: ['StOutreach_UndupHMIS_DQ', :so, 'Q1', :B2],
      CG: ['ESSH_LeaversHMIS_DQ', :essh, 'Q1', :B6],
      CH: ['TH_LeaversHMIS_DQ', :th, 'Q1', :B6],
      CI: ['PSHOPH_LeaversHMIS_DQ', :pshoph, 'Q1', :B6],
      CJ: ['RRH_LeaversHMIS_DQ', :rrh, 'Q1', :B6],
      CK: ['StOutreach_LeaversHMIS_DQ', :so, 'Q1', :B6],

      CL: ['ESSH_DkRMHMIS_DQ', :essh, 'Q4', :E2],
      CM: ['TH_DkRMHMIS_DQ', :th, 'Q4', :E2],
      CN: ['PSHOPH_DkRMHMIS_DQ', :pshoph, 'Q4', :E2],
      CO: ['RRH_DkRMHMIS_DQ', :rrh, 'Q4', :E2],
      CP: ['StOutreach_DkRMHMIS_DQ', :so, 'Q4', :E2],
    }.freeze

    private def run_csv(table_name)
      prepare_table(
        table_name,
        ROWS,
        COLUMNS,
        hide_column_header: true, # Column headers are part of the table
        external_column_header: false,
        external_row_label: true,
      )

      COLUMNS.transform_values(&:first).each do |column, label|
        answer = @report.answer(question: table_name, cell: column.to_s + '1')
        answer.update(summary: label)
      end

      COLUMNS.each do |column, (label, section, *args)|
        cell_value = case section
        when :metadata
          metadata(label)
        when :spm
          spm(*args)
        else
          dq(section, *args)
        end

        answer = @report.answer(question: table_name, cell: column.to_s + '2')
        answer.update(summary: cell_value)
      end
    end

    def metadata(column)
      case column
      when 'CocCode'
        @report.coc_codes.join(', ')
      when 'ReportDateTime'
        @report.started_at.strftime('%Y-%m-%d %H:%M:%S')
      when 'ReportStartDate'
        @report.start_date.strftime('%Y-%m-%d')
      when 'ReportEndDate'
        @report.end_date.strftime('%Y-%m-%d')
      when 'SoftwareName'
        'OpenPath HMIS Data Warehouse'
      when 'SourceContactFirst'
        @report.user.first_name
      when 'SourceContactLast'
        @report.user.last_name
      when 'SourceContactEmail'
        @report.user.email
      end
    end

    def spm(table_name, cell_name)
      @report.answer(question: table_name, cell: cell_name)&.summary || ''
    end

    def dq(section, table_name, cell_name)
      return unless RailsDrivers.loaded.include?(:hud_apr)

      @attempted ||= Set.new
      @reports ||= {}

      # prevent retrying reports that don't have any projects
      return '' if @attempted.include?(section) && @reports[section].nil?

      dq_report = case section
      when :essh
        @reports[section] ||= generate_dq(HudUtility2024.residential_project_type_numbers_by_codes(:es, :sh))
      when :th
        @reports[section] ||= generate_dq(HudUtility2024.residential_project_type_numbers_by_codes(:th))
      when :pshoph
        @reports[section] ||= generate_dq(HudUtility2024.residential_project_type_numbers_by_codes(:psh, :oph))
      when :rrh
        @reports[section] ||= generate_dq(HudUtility2024.residential_project_type_numbers_by_codes(:rrh))
      when :so
        @reports[section] ||= generate_dq(HudUtility2024.residential_project_type_numbers_by_codes(:so))
      end

      # prevent retrying reports that don't have any projects
      @attempted << section
      dq_report&.answer(question: table_name, cell: cell_name)&.summary || ''
    end

    private def generate_dq(project_types)
      dq_filter = filter.deep_dup
      # The DQ version differs from the SPM version
      dq_filter.report_version = :fy2024

      # limit DQ report to projects in the appropriate project types that were in this SPM
      project_ids = GrdaWarehouse::Hud::Project.where(ProjectType: project_types, id: @report.project_ids).pluck(:id)
      return unless project_ids.any?

      # Clear out other mechanisms of setting projects
      dq_filter.relevant_project_types = []
      dq_filter.project_type_codes = []
      dq_filter.project_type_numbers = []
      dq_filter.project_group_ids = []
      dq_filter.data_source_ids = []
      dq_filter.project_ids = project_ids

      generator = HudApr::Generators::Dq::Fy2024::Generator
      report = ::HudReports::ReportInstance.from_filter(dq_filter, generator.title, build_for_questions: ['Question 1', 'Question 4'])
      generator.new(report).run!(email: false, manual: false)

      report
    end

    def filter
      @filter ||= ::Filters::HudFilterBase.new(user_id: @report.user.id).update(@report.options)
    end
  end
end
