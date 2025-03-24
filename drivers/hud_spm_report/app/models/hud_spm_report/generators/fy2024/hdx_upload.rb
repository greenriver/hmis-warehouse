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

    HdxColumn = Struct.new(
      :column_letter, # The Excel column letter (A, B, C, etc.)
      :variable_name,   # The name used in HDX (e.g., 'CocCode')
      :source_type,     # Where to get data from (:metadata, :spm, :essh, etc.)
      :source_table,    # For SPM/DQ, which table to look at (e.g., '1a', 'Q1')
      :source_cell,     # For SPM/DQ, which cell to get data from (e.g., :B1)
      :data_type,       # Format type (:string, :integer, :decimal, :date, :datetime)
      :max_length,      # For strings, maximum allowed length (optional)
      keyword_init: true,
    ) do
      # Get the raw value for this column
      def get_raw_value(context)
        case source_type
        when :metadata
          context.metadata(source_table)
        when :spm
          context.spm(source_table, source_cell)
        else
          context.dq(source_type, source_table, source_cell)
        end
      end

      # Format value based on data type and constraints
      def format_value(value)
        # Handle nil/blank values first
        return default_value if value.blank?

        case data_type
        when :integer
          value.to_i
        when :decimal
          value.to_f.round(2)
        when :date
          value.is_a?(Date) ? value.strftime('%Y-%m-%d') : value.to_s
        when :datetime
          value.is_a?(Time) ? value.strftime('%Y-%m-%d %H:%M:%S') : value.to_s
        when :string
          formatted_string = value.to_s
          formatted_string = formatted_string[0...max_length] if max_length.present?
          formatted_string
        else
          raise ArgumentError, "data type \"#{data_type}\" not supported"
        end
      end

      # Default value for this column's data type
      def default_value
        case data_type
        when :integer
          0
        when :decimal
          0.0
        when :date
          Date.today.strftime('%Y-%m-%d')
        when :datetime
          Time.now.strftime('%Y-%m-%d %H:%M:%S')
        when :string
          ''
        else
          raise ArgumentError, "data type \"#{data_type}\" not supported"
        end
      end
    end
    private_constant :HdxColumn

    COLUMNS = [
      # Metadata fields
      { column_letter: 'A', variable_name: 'CocCode', source_type: :metadata, source_table: 'CocCode', data_type: :string, max_length: 6 },
      { column_letter: 'B', variable_name: 'ReportDateTime', source_type: :metadata, source_table: 'ReportDateTime', data_type: :datetime },
      { column_letter: 'C', variable_name: 'ReportStartDate', source_type: :metadata, source_table: 'ReportStartDate', data_type: :date },
      { column_letter: 'D', variable_name: 'ReportEndDate', source_type: :metadata, source_table: 'ReportEndDate', data_type: :date },
      { column_letter: 'E', variable_name: 'SoftwareName', source_type: :metadata, source_table: 'SoftwareName', data_type: :string, max_length: 50 },
      { column_letter: 'F', variable_name: 'SourceContactFirst', source_type: :metadata, source_table: 'SourceContactFirst', data_type: :string, max_length: 50 },
      { column_letter: 'G', variable_name: 'SourceContactLast', source_type: :metadata, source_table: 'SourceContactLast', data_type: :string, max_length: 50 },
      { column_letter: 'H', variable_name: 'SourceContactEmail', source_type: :metadata, source_table: 'SourceContactEmail', data_type: :string, max_length: 50 },

      # Measure 1a fields
      { column_letter: 'I', variable_name: 'ESSHUniverse_1A', source_type: :spm, source_table: '1a', source_cell: :B1, data_type: :integer },
      { column_letter: 'J', variable_name: 'ESSHAvgTime_1A', source_type: :spm, source_table: '1a', source_cell: :D1, data_type: :decimal },
      { column_letter: 'K', variable_name: 'ESSHMedianTime_1A', source_type: :spm, source_table: '1a', source_cell: :G1, data_type: :decimal },
      { column_letter: 'L', variable_name: 'ESSHTHUniverse_1A', source_type: :spm, source_table: '1a', source_cell: :B2, data_type: :integer },
      { column_letter: 'M', variable_name: 'ESSHTHAvgTime_1A', source_type: :spm, source_table: '1a', source_cell: :D2, data_type: :decimal },
      { column_letter: 'N', variable_name: 'ESSHTHMedianTime_1A', source_type: :spm, source_table: '1a', source_cell: :G2, data_type: :decimal },

      # Measure 1b fields
      { column_letter: 'O', variable_name: 'ESSHUniverse_1B', source_type: :spm, source_table: '1b', source_cell: :B1, data_type: :integer },
      { column_letter: 'P', variable_name: 'ESSHAvgTime_1B', source_type: :spm, source_table: '1b', source_cell: :D1, data_type: :decimal },
      { column_letter: 'Q', variable_name: 'ESSHMedianTime_1B', source_type: :spm, source_table: '1b', source_cell: :G1, data_type: :decimal },
      { column_letter: 'R', variable_name: 'ESSHTHUniverse_1B', source_type: :spm, source_table: '1b', source_cell: :B2, data_type: :integer },
      { column_letter: 'S', variable_name: 'ESSHTHAvgTime_1B', source_type: :spm, source_table: '1b', source_cell: :D2, data_type: :decimal },
      { column_letter: 'T', variable_name: 'ESSHTHMedianTime_1B', source_type: :spm, source_table: '1b', source_cell: :G2, data_type: :decimal },

      # Measure 2 fields
      { column_letter: 'U', variable_name: 'SOExitPH_2', source_type: :spm, source_table: '2a and 2b', source_cell: :B2, data_type: :integer },
      { column_letter: 'V', variable_name: 'SOReturn0to180_2', source_type: :spm, source_table: '2a and 2b', source_cell: :C2, data_type: :integer },
      { column_letter: 'W', variable_name: 'SOReturn181to365_2', source_type: :spm, source_table: '2a and 2b', source_cell: :E2, data_type: :integer },
      { column_letter: 'X', variable_name: 'SOReturn366to730_2', source_type: :spm, source_table: '2a and 2b', source_cell: :G2, data_type: :integer },
      { column_letter: 'Y', variable_name: 'ESExitPH_2', source_type: :spm, source_table: '2a and 2b', source_cell: :B3, data_type: :integer },
      { column_letter: 'Z', variable_name: 'ESReturn0to180_2', source_type: :spm, source_table: '2a and 2b', source_cell: :C3, data_type: :integer },
      { column_letter: 'AA', variable_name: 'ESReturn181to365_2', source_type: :spm, source_table: '2a and 2b', source_cell: :E3, data_type: :integer },
      { column_letter: 'AB', variable_name: 'ESReturn366to730_2', source_type: :spm, source_table: '2a and 2b', source_cell: :G3, data_type: :integer },
      { column_letter: 'AC', variable_name: 'THExitPH_2', source_type: :spm, source_table: '2a and 2b', source_cell: :B4, data_type: :integer },
      { column_letter: 'AD', variable_name: 'THReturn0to180_2', source_type: :spm, source_table: '2a and 2b', source_cell: :C4, data_type: :integer },
      { column_letter: 'AE', variable_name: 'THReturn181to365_2', source_type: :spm, source_table: '2a and 2b', source_cell: :E4, data_type: :integer },
      { column_letter: 'AF', variable_name: 'THReturn366to730_2', source_type: :spm, source_table: '2a and 2b', source_cell: :G4, data_type: :integer },
      { column_letter: 'AG', variable_name: 'SHExitPH_2', source_type: :spm, source_table: '2a and 2b', source_cell: :B5, data_type: :integer },
      { column_letter: 'AH', variable_name: 'SHReturn0to180_2', source_type: :spm, source_table: '2a and 2b', source_cell: :C5, data_type: :integer },
      { column_letter: 'AI', variable_name: 'SHReturn181to365_2', source_type: :spm, source_table: '2a and 2b', source_cell: :E5, data_type: :integer },
      { column_letter: 'AJ', variable_name: 'SHReturn366to730_2', source_type: :spm, source_table: '2a and 2b', source_cell: :G5, data_type: :integer },
      { column_letter: 'AK', variable_name: 'PHExitPH_2', source_type: :spm, source_table: '2a and 2b', source_cell: :B6, data_type: :integer },
      { column_letter: 'AL', variable_name: 'PHReturn0to180_2', source_type: :spm, source_table: '2a and 2b', source_cell: :C6, data_type: :integer },
      { column_letter: 'AM', variable_name: 'PHReturn181to365_2', source_type: :spm, source_table: '2a and 2b', source_cell: :E6, data_type: :integer },
      { column_letter: 'AN', variable_name: 'PHReturn366to730_2', source_type: :spm, source_table: '2a and 2b', source_cell: :G6, data_type: :integer },

      # Measure 3 fields
      { column_letter: 'AO', variable_name: 'TotalAnnual_3', source_type: :spm, source_table: '3.2', source_cell: :C2, data_type: :integer },
      { column_letter: 'AP', variable_name: 'ESAnnual_3', source_type: :spm, source_table: '3.2', source_cell: :C3, data_type: :integer },
      { column_letter: 'AQ', variable_name: 'SHAnnual_3', source_type: :spm, source_table: '3.2', source_cell: :C4, data_type: :integer },
      { column_letter: 'AR', variable_name: 'THAnnual_3', source_type: :spm, source_table: '3.2', source_cell: :C5, data_type: :integer },

      # Measure 4 fields
      { column_letter: 'AS', variable_name: 'AdultStayers_4', source_type: :spm, source_table: '4.1', source_cell: :C2, data_type: :integer },
      { column_letter: 'AT', variable_name: 'IncreaseEarned4_1', source_type: :spm, source_table: '4.1', source_cell: :C3, data_type: :integer },
      { column_letter: 'AU', variable_name: 'IncreaseOther4_2', source_type: :spm, source_table: '4.2', source_cell: :C3, data_type: :integer },
      { column_letter: 'AV', variable_name: 'IncreaseTotal4_3', source_type: :spm, source_table: '4.3', source_cell: :C3, data_type: :integer },
      { column_letter: 'AW', variable_name: 'AdultLeavers_4', source_type: :spm, source_table: '4.4', source_cell: :C2, data_type: :integer },
      { column_letter: 'AX', variable_name: 'IncreaseEarned4_4', source_type: :spm, source_table: '4.4', source_cell: :C3, data_type: :integer },
      { column_letter: 'AY', variable_name: 'IncreaseOther4_5', source_type: :spm, source_table: '4.5', source_cell: :C3, data_type: :integer },
      { column_letter: 'AZ', variable_name: 'IncreaseTotal4_6', source_type: :spm, source_table: '4.6', source_cell: :C3, data_type: :integer },

      # Measure 5 fields
      { column_letter: 'BA', variable_name: 'EnterESSHTH5_1', source_type: :spm, source_table: '5.1', source_cell: :C2, data_type: :integer },
      { column_letter: 'BB', variable_name: 'ESSHTHWithPriorSvc5_1', source_type: :spm, source_table: '5.1', source_cell: :C3, data_type: :integer },
      { column_letter: 'BC', variable_name: 'EnterESSHTHPH5_2', source_type: :spm, source_table: '5.2', source_cell: :C2, data_type: :integer },
      { column_letter: 'BD', variable_name: 'ESSHTHPHWithPriorSvc5_2', source_type: :spm, source_table: '5.2', source_cell: :C3, data_type: :integer },

      # Measure 6 fields
      { column_letter: 'BE', variable_name: 'THExitPH_6', source_type: :spm, source_table: '6a.1 and 6b.1', source_cell: :B4, data_type: :integer },
      { column_letter: 'BF', variable_name: 'THReturn0to180_6', source_type: :spm, source_table: '6a.1 and 6b.1', source_cell: :C4, data_type: :integer },
      { column_letter: 'BG', variable_name: 'THReturn181to365_6', source_type: :spm, source_table: '6a.1 and 6b.1', source_cell: :E4, data_type: :integer },
      { column_letter: 'BH', variable_name: 'THReturn366to730_6', source_type: :spm, source_table: '6a.1 and 6b.1', source_cell: :G4, data_type: :integer },
      { column_letter: 'BI', variable_name: 'SHExitPH_6', source_type: :spm, source_table: '6a.1 and 6b.1', source_cell: :B5, data_type: :integer },
      { column_letter: 'BJ', variable_name: 'SHReturn0to180_6', source_type: :spm, source_table: '6a.1 and 6b.1', source_cell: :C5, data_type: :integer },
      { column_letter: 'BK', variable_name: 'SHReturn181to365_6', source_type: :spm, source_table: '6a.1 and 6b.1', source_cell: :E5, data_type: :integer },
      { column_letter: 'BL', variable_name: 'SHReturn366to730_6', source_type: :spm, source_table: '6a.1 and 6b.1', source_cell: :G5, data_type: :integer },
      { column_letter: 'BM', variable_name: 'PHExitPH_6', source_type: :spm, source_table: '6a.1 and 6b.1', source_cell: :B6, data_type: :integer },
      { column_letter: 'BN', variable_name: 'PHReturn0to180_6', source_type: :spm, source_table: '6a.1 and 6b.1', source_cell: :C6, data_type: :integer },
      { column_letter: 'BO', variable_name: 'PHReturn181to365_6', source_type: :spm, source_table: '6a.1 and 6b.1', source_cell: :E6, data_type: :integer },
      { column_letter: 'BP', variable_name: 'PHReturn366to730_6', source_type: :spm, source_table: '6a.1 and 6b.1', source_cell: :G6, data_type: :integer },
      { column_letter: 'BQ', variable_name: 'SHTHRRHCat3Leavers_6', source_type: :spm, source_table: '6c.1', source_cell: :C2, data_type: :integer },
      { column_letter: 'BR', variable_name: 'SHTHRRHCat3ExitPH_6', source_type: :spm, source_table: '6c.1', source_cell: :C3, data_type: :integer },
      { column_letter: 'BS', variable_name: 'PSHCat3Clients_6', source_type: :spm, source_table: '6c.2', source_cell: :C2, data_type: :integer },
      { column_letter: 'BT', variable_name: 'PSHCat3StayOrExitPH_6', source_type: :spm, source_table: '6c.2', source_cell: :C3, data_type: :integer },

      # Measure 7 fields
      { column_letter: 'BU', variable_name: 'SOExit_7', source_type: :spm, source_table: '7a.1', source_cell: :C2, data_type: :integer },
      { column_letter: 'BV', variable_name: 'SOExitTempInst_7', source_type: :spm, source_table: '7a.1', source_cell: :C3, data_type: :integer },
      { column_letter: 'BW', variable_name: 'SOExitPH_7', source_type: :spm, source_table: '7a.1', source_cell: :C4, data_type: :integer },
      { column_letter: 'BX', variable_name: 'ESSHTHRRHExit_7', source_type: :spm, source_table: '7b.1', source_cell: :C2, data_type: :integer },
      { column_letter: 'BY', variable_name: 'ESSHTHRRHToPH_7', source_type: :spm, source_table: '7b.1', source_cell: :C3, data_type: :integer },
      { column_letter: 'BZ', variable_name: 'PHClients_7', source_type: :spm, source_table: '7b.2', source_cell: :C2, data_type: :integer },
      { column_letter: 'CA', variable_name: 'PHClientsStayOrExitPH_7', source_type: :spm, source_table: '7b.2', source_cell: :C3, data_type: :integer },

      # Data Quality Report fields - ES-SH
      { column_letter: 'CB', variable_name: 'ESSH_UndupHMIS_DQ', source_type: :essh, source_table: 'Q1', source_cell: :B2, data_type: :integer },
      { column_letter: 'CG', variable_name: 'ESSH_LeaversHMIS_DQ', source_type: :essh, source_table: 'Q1', source_cell: :B6, data_type: :integer },
      { column_letter: 'CL', variable_name: 'ESSH_DkRMHMIS_DQ', source_type: :essh, source_table: 'Q4', source_cell: :E2, data_type: :integer },

      # Data Quality Report fields - TH
      { column_letter: 'CC', variable_name: 'TH_UndupHMIS_DQ', source_type: :th, source_table: 'Q1', source_cell: :B2, data_type: :integer },
      { column_letter: 'CH', variable_name: 'TH_LeaversHMIS_DQ', source_type: :th, source_table: 'Q1', source_cell: :B6, data_type: :integer },
      { column_letter: 'CM', variable_name: 'TH_DkRMHMIS_DQ', source_type: :th, source_table: 'Q4', source_cell: :E2, data_type: :integer },

      # Data Quality Report fields - PSH/OPH
      { column_letter: 'CD', variable_name: 'PSHOPH_UndupHMIS_DQ', source_type: :pshoph, source_table: 'Q1', source_cell: :B2, data_type: :integer },
      { column_letter: 'CI', variable_name: 'PSHOPH_LeaversHMIS_DQ', source_type: :pshoph, source_table: 'Q1', source_cell: :B6, data_type: :integer },
      { column_letter: 'CN', variable_name: 'PSHOPH_DkRMHMIS_DQ', source_type: :pshoph, source_table: 'Q4', source_cell: :E2, data_type: :integer },

      # Data Quality Report fields - RRH
      { column_letter: 'CE', variable_name: 'RRH_UndupHMIS_DQ', source_type: :rrh, source_table: 'Q1', source_cell: :B2, data_type: :integer },
      { column_letter: 'CJ', variable_name: 'RRH_LeaversHMIS_DQ', source_type: :rrh, source_table: 'Q1', source_cell: :B6, data_type: :integer },
      { column_letter: 'CO', variable_name: 'RRH_DkRMHMIS_DQ', source_type: :rrh, source_table: 'Q4', source_cell: :E2, data_type: :integer },

      # Data Quality Report fields - Street Outreach
      { column_letter: 'CF', variable_name: 'StOutreach_UndupHMIS_DQ', source_type: :so, source_table: 'Q1', source_cell: :B2, data_type: :integer },
      { column_letter: 'CK', variable_name: 'StOutreach_LeaversHMIS_DQ', source_type: :so, source_table: 'Q1', source_cell: :B6, data_type: :integer },
      { column_letter: 'CP', variable_name: 'StOutreach_DkRMHMIS_DQ', source_type: :so, source_table: 'Q4', source_cell: :E2, data_type: :integer },
    ].map { |attrs| HdxColumn.new(attrs).freeze }.freeze

    def run_csv(table_name)
      # Setup table structure
      prepare_table(
        table_name,
        ROWS,
        COLUMNS.map { |col| [col.column_letter.to_sym, col.variable_name] }.to_h,
        hide_column_header: true,
        external_column_header: false,
        external_row_label: true,
      )

      # Set the column headers in row 1
      COLUMNS.each do |column|
        answer = @report.answer(question: table_name, cell: "#{column.column_letter}1")
        answer.update(summary: column.variable_name)
      end

      # Set the values in row 2
      COLUMNS.each do |column|
        # Get and format the value in one step
        raw_value = column.get_raw_value(self)
        formatted_value = column.format_value(raw_value)

        # Update the report cell
        answer = @report.answer(question: table_name, cell: "#{column.column_letter}2")
        answer.update(summary: formatted_value)
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
