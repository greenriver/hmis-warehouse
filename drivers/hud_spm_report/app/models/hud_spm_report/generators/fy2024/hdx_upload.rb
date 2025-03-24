# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Measure 2a and 2b: The Extent to which Persons Who Exit Homelessness
# to Permanent Housing Destinations Return to Homelessness within 6, 12,
# and 24 months.
module HudSpmReport::Generators::Fy2024
  class HdxUpload < MeasureBase
    def self.question_number
      'HDX Upload'
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
      A: ['CocCode', :metadata, 'CocCode', :string], # String(6)
      B: ['ReportDateTime', :metadata, 'ReportDateTime', :datetime],  # DateTime
      C: ['ReportStartDate', :metadata, 'ReportStartDate', :date],    # Date
      D: ['ReportEndDate', :metadata, 'ReportEndDate', :date],        # Date
      E: ['SoftwareName', :metadata, 'SoftwareName', :string],        # String(50)
      F: ['SourceContactFirst', :metadata, 'SourceContactFirst', :string], # String(50)
      G: ['SourceContactLast', :metadata, 'SourceContactLast', :string],   # String(50)
      H: ['SourceContactEmail', :metadata, 'SourceContactEmail', :string], # String(50)

      I: ['ESSHUniverse_1A', :spm, '1a', :B1, :integer],     # Integer
      J: ['ESSHAvgTime_1A', :spm, '1a', :D1, :decimal],      # Decimal
      K: ['ESSHMedianTime_1A', :spm, '1a', :G1, :decimal],   # Decimal
      L: ['ESSHTHUniverse_1A', :spm, '1a', :B2, :integer],   # Integer
      M: ['ESSHTHAvgTime_1A', :spm, '1a', :D2, :decimal],    # Decimal
      N: ['ESSHTHMedianTime_1A', :spm, '1a', :G2, :decimal], # Decimal

      O: ['ESSHUniverse_1B', :spm, '1b', :B1, :integer],     # Integer
      P: ['ESSHAvgTime_1B', :spm, '1b', :D1, :decimal],      # Decimal
      Q: ['ESSHMedianTime_1B', :spm, '1b', :G1, :decimal],   # Decimal
      R: ['ESSHTHUniverse_1B', :spm, '1b', :B2, :integer],   # Integer
      S: ['ESSHTHAvgTime_1B', :spm, '1b', :D2, :decimal],    # Decimal
      T: ['ESSHTHMedianTime_1B', :spm, '1b', :G2, :decimal], # Decimal

      U: ['SOExitPH_2', :spm, '2a and 2b', :B2, :integer],        # Integer
      V: ['SOReturn0to180_2', :spm, '2a and 2b', :C2, :integer],  # Integer
      W: ['SOReturn181to365_2', :spm, '2a and 2b', :E2, :integer], # Integer
      X: ['SOReturn366to730_2', :spm, '2a and 2b', :G2, :integer], # Integer
      Y: ['ESExitPH_2', :spm, '2a and 2b', :B3, :integer],        # Integer
      Z: ['ESReturn0to180_2', :spm, '2a and 2b', :C3, :integer],  # Integer
      AA: ['ESReturn181to365_2', :spm, '2a and 2b', :E3, :integer], # Integer
      AB: ['ESReturn366to730_2', :spm, '2a and 2b', :G3, :integer], # Integer
      AC: ['THExitPH_2', :spm, '2a and 2b', :B4, :integer],        # Integer
      AD: ['THReturn0to180_2', :spm, '2a and 2b', :C4, :integer],  # Integer
      AE: ['THReturn181to365_2', :spm, '2a and 2b', :E4, :integer], # Integer
      AF: ['THReturn366to730_2', :spm, '2a and 2b', :G4, :integer], # Integer
      AG: ['SHExitPH_2', :spm, '2a and 2b', :B5, :integer],        # Integer
      AH: ['SHReturn0to180_2', :spm, '2a and 2b', :C5, :integer],  # Integer
      AI: ['SHReturn181to365_2', :spm, '2a and 2b', :E5, :integer], # Integer
      AJ: ['SHReturn366to730_2', :spm, '2a and 2b', :G5, :integer], # Integer
      AK: ['PHExitPH_2', :spm, '2a and 2b', :B6, :integer],        # Integer
      AL: ['PHReturn0to180_2', :spm, '2a and 2b', :C6, :integer],  # Integer
      AM: ['PHReturn181to365_2', :spm, '2a and 2b', :E6, :integer], # Integer
      AN: ['PHReturn366to730_2', :spm, '2a and 2b', :G6, :integer], # Integer

      AO: ['TotalAnnual_3', :spm, '3.2', :C2, :integer],    # Integer
      AP: ['ESAnnual_3', :spm, '3.2', :C3, :integer],       # Integer
      AQ: ['SHAnnual_3', :spm, '3.2', :C4, :integer],       # Integer
      AR: ['THAnnual_3', :spm, '3.2', :C5, :integer],       # Integer

      AS: ['AdultStayers_4', :spm, '4.1', :C2, :integer],     # Integer
      AT: ['IncreaseEarned4_1', :spm, '4.1', :C3, :integer],  # Integer

      AU: ['IncreaseOther4_2', :spm, '4.2', :C3, :integer],   # Integer

      AV: ['IncreaseTotal4_3', :spm, '4.3', :C3, :integer],   # Integer

      AW: ['AdultLeavers_4', :spm, '4.4', :C2, :integer],     # Integer
      AX: ['IncreaseEarned4_4', :spm, '4.4', :C3, :integer],  # Integer

      AY: ['IncreaseOther4_5', :spm, '4.5', :C3, :integer],   # Integer

      AZ: ['IncreaseTotal4_6', :spm, '4.6', :C3, :integer],   # Integer

      BA: ['EnterESSHTH5_1', :spm, '5.1', :C2, :integer],        # Integer
      BB: ['ESSHTHWithPriorSvc5_1', :spm, '5.1', :C3, :integer], # Integer

      BC: ['EnterESSHTHPH5_2', :spm, '5.2', :C2, :integer],        # Integer
      BD: ['ESSHTHPHWithPriorSvc5_2', :spm, '5.2', :C3, :integer], # Integer

      BE: ['THExitPH_6', :spm, '6a.1 and 6b.1', :B4, :integer],        # Integer
      BF: ['THReturn0to180_6', :spm, '6a.1 and 6b.1', :C4, :integer],  # Integer
      BG: ['THReturn181to365_6', :spm, '6a.1 and 6b.1', :E4, :integer], # Integer
      BH: ['THReturn366to730_6', :spm, '6a.1 and 6b.1', :G4, :integer], # Integer
      BI: ['SHExitPH_6', :spm, '6a.1 and 6b.1', :B5, :integer],        # Integer
      BJ: ['SHReturn0to180_6', :spm, '6a.1 and 6b.1', :C5, :integer],  # Integer
      BK: ['SHReturn181to365_6', :spm, '6a.1 and 6b.1', :E5, :integer], # Integer
      BL: ['SHReturn366to730_6', :spm, '6a.1 and 6b.1', :G5, :integer], # Integer
      BM: ['PHExitPH_6', :spm, '6a.1 and 6b.1', :B6, :integer],        # Integer
      BN: ['PHReturn0to180_6', :spm, '6a.1 and 6b.1', :C6, :integer],  # Integer
      BO: ['PHReturn181to365_6', :spm, '6a.1 and 6b.1', :E6, :integer], # Integer
      BP: ['PHReturn366to730_6', :spm, '6a.1 and 6b.1', :G6, :integer], # Integer

      BQ: ['SHTHRRHCat3Leavers_6', :spm, '6c.1', :C2, :integer],     # Integer
      BR: ['SHTHRRHCat3ExitPH_6', :spm, '6c.1', :C3, :integer],      # Integer

      BS: ['PSHCat3Clients_6', :spm, '6c.2', :C2, :integer],         # Integer
      BT: ['PSHCat3StayOrExitPH_6', :spm, '6c.2', :C3, :integer],    # Integer

      BU: ['SOExit_7', :spm, '7a.1', :C2, :integer],             # Integer
      BV: ['SOExitTempInst_7', :spm, '7a.1', :C3, :integer],     # Integer
      BW: ['SOExitPH_7', :spm, '7a.1', :C4, :integer],           # Integer

      BX: ['ESSHTHRRHExit_7', :spm, '7b.1', :C2, :integer],      # Integer
      BY: ['ESSHTHRRHToPH_7', :spm, '7b.1', :C3, :integer],      # Integer

      BZ: ['PHClients_7', :spm, '7b.2', :C2, :integer],          # Integer
      CA: ['PHClientsStayOrExitPH_7', :spm, '7b.2', :C3, :integer], # Integer

      CB: ['ESSH_UndupHMIS_DQ', :essh, 'Q1', :B2, :integer],          # Integer
      CC: ['TH_UndupHMIS_DQ', :th, 'Q1', :B2, :integer],              # Integer
      CD: ['PSHOPH_UndupHMIS_DQ', :pshoph, 'Q1', :B2, :integer],      # Integer
      CE: ['RRH_UndupHMIS_DQ', :rrh, 'Q1', :B2, :integer],            # Integer
      CF: ['StOutreach_UndupHMIS_DQ', :so, 'Q1', :B2, :integer],      # Integer
      CG: ['ESSH_LeaversHMIS_DQ', :essh, 'Q1', :B6, :integer],        # Integer
      CH: ['TH_LeaversHMIS_DQ', :th, 'Q1', :B6, :integer],            # Integer
      CI: ['PSHOPH_LeaversHMIS_DQ', :pshoph, 'Q1', :B6, :integer],    # Integer
      CJ: ['RRH_LeaversHMIS_DQ', :rrh, 'Q1', :B6, :integer],          # Integer
      CK: ['StOutreach_LeaversHMIS_DQ', :so, 'Q1', :B6, :integer],    # Integer

      CL: ['ESSH_DkRMHMIS_DQ', :essh, 'Q4', :E2, :integer],           # Integer
      CM: ['TH_DkRMHMIS_DQ', :th, 'Q4', :E2, :integer],               # Integer
      CN: ['PSHOPH_DkRMHMIS_DQ', :pshoph, 'Q4', :E2, :integer],       # Integer
      CO: ['RRH_DkRMHMIS_DQ', :rrh, 'Q4', :E2, :integer],             # Integer
      CP: ['StOutreach_DkRMHMIS_DQ', :so, 'Q4', :E2, :integer],       # Integer
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

      # Set the column headers in row 1
      COLUMNS.each do |column, (label, *_)|
        answer = @report.answer(question: table_name, cell: column.to_s + '1')
        answer.update(summary: label)
      end

      # Set the values in row 2
      COLUMNS.each do |column, (_, section, *args)|
        data_type = args.last

        # Get raw value
        raw_value = case section
        when :metadata
          metadata(args.first)
        when :spm
          spm(args[0], args[1])
        else
          dq(section, args[0], args[1])
        end

        # Format value based on data type
        formatted_value = format_value(raw_value, data_type)

        answer = @report.answer(question: table_name, cell: column.to_s + '2')
        answer.update(summary: formatted_value)
      end
    end

    # Helper method to format values based on data type
    def format_value(value, data_type)
      case data_type
      when :integer
        value.presence ? value.to_i : 0
      when :decimal
        value.presence ? value.to_f.round(2) : 0.0
      when :date
        value.presence || Date.today.strftime('%Y-%m-%d')
      when :datetime
        value.presence || Time.now.strftime('%Y-%m-%d %H:%M:%S')
      when :string
        value.presence || ''
      else
        raise ArgumentError, "data type \"#{data_type}\" not supported"
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
      # Return a string to indicate this cell has been processed
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
      # The DQ version may differ from the SPM version
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
