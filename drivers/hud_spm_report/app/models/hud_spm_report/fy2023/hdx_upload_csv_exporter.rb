###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Fy2023
  class HdxUploadCsvExporter
    def initialize(report:, generator:)
      @report = report
      @generator = generator
    end

    def csv_export
      CSV.generate(force_quotes: true, quote_empty: true) do |csv|
        add_metadata_rows(csv)
        add_spm_rows(csv)
        add_dq_rows(csv)
      end
    end

    def csv_filename
      "#{@generator.file_prefix} - #{DateTime.current.to_s(:db)}.csv"
    end

    private def add_metadata_rows(csv)
      csv << ['CocCode', @report.coc_codes.join(', ')]
      csv << ['ReportDateTime', @report.started_at.strftime('%Y-%m-%d %H:%M:%S')]
      csv << ['ReportStartDate', @report.start_date.strftime('%Y-%m-%d')]
      csv << ['ReportEndDate', @report.end_date.strftime('%Y-%m-%d')]
      csv << ['SoftwareName', 'OpenPath HMIS Data Warehouse']
      csv << ['SourceContactFirst', @report.user.first_name]
      csv << ['SourceContactLast', @report.user.last_name]
      csv << ['SourceContactEmail', @report.user.email]
    end

    private def add_spm_rows(csv)
      [
        ['ESSHUniverse_1A', '1a', :B1],
        ['ESSHAvgTime_1A', '1a', :D1],
        ['ESSHMedianTime_1A', '1a', :G1],
        ['ESSHTHUniverse_1A', '1a', :B2],
        ['ESSHTHAvgTime_1A', '1a', :D2],

        ['ESSHTHMedianTime_1A', '1a', :G2],
        ['ESSHUniverse_1B', '1b', :B1],
        ['ESSHAvgTime_1B', '1b', :D1],
        ['ESSHMedianTime_1B', '1b', :G1],
        ['ESSHTHUniverse_1B', '1b', :B2],
        ['ESSHTHAvgTime_1B', '1b', :D2],
        ['ESSHTHMedianTime_1B', '1b', :G2],

        ['SOExitPH_2', '2a and 2b', :B2],
        ['SOReturn0to180_2', '2a and 2b', :C2],
        ['SOReturn181to365_2', '2a and 2b', :E2],
        ['SOReturn366to730_2', '2a and 2b', :G2],
        ['ESExitPH_2', '2a and 2b', :B3],
        ['ESReturn0to180_2', '2a and 2b', :C3],
        ['ESReturn181to365_2', '2a and 2b', :E3],
        ['ESReturn366to730_2', '2a and 2b', :G3],
        ['THExitPH_2', '2a and 2b', :B4],
        ['THReturn0to180_2', '2a and 2b', :C4],
        ['THReturn181to365_2', '2a and 2b', :E4],
        ['THReturn366to730_2', '2a and 2b', :G4],
        ['SHExitPH_2', '2a and 2b', :B5],
        ['SHReturn0to180_2', '2a and 2b', :C5],
        ['SHReturn181to365_2', '2a and 2b', :E5],
        ['SHReturn366to730_2', '2a and 2b', :G5],
        ['PHExitPH_2', '2a and 2b', :B6],
        ['PHReturn0to180_2', '2a and 2b', :C6],
        ['PHReturn181to365_2', '2a and 2b', :E6],
        ['PHReturn366to730_2', '2a and 2b', :G6],

        ['TotalAnnual_3', '3.2', :C2],
        ['ESAnnual_3', '3.2', :C3],
        ['SHAnnual_3', '3.2', :C4],
        ['THAnnual_3', '3.2', :C5],

        ['AdultStayers_4', '4.1', :C2],
        ['IncreaseEarned4_1', '4.1', :C3],

        ['IncreaseOther4_2', '4.2', :C3],

        ['IncreaseTotal4_3', '4.3', :C3],

        ['AdultLeavers_4', '4.4', :C2],
        ['IncreaseEarned4_4', '4.4', :C3],

        ['IncreaseOther4_5', '4.5', :C3],

        ['IncreaseTotal4_6', '4.6', :C3],

        ['EnterESSHTH5_1', '5.1', :C2],
        ['ESSHTHWithPriorSvc5_1', '5.1', :C3],

        ['EnterESSHTHPH5_2', '5.2', :C2],
        ['ESSHTHPHWithPriorSvc5_2', '5.2', :C3],

        ['THExitPH_6', '6a.1 and 6b.1', :B4],
        ['THReturn0to180_6', '6a.1 and 6b.1', :C4],
        ['THReturn181to365_6', '6a.1 and 6b.1', :E4],
        ['THReturn366to730_6', '6a.1 and 6b.1', :G4],
        ['SHExitPH_6', '6a.1 and 6b.1', :B5],
        ['SHReturn0to180_6', '6a.1 and 6b.1', :C5],
        ['SHReturn181to365_6', '6a.1 and 6b.1', :E5],
        ['SHReturn366to730_6', '6a.1 and 6b.1', :G5],
        ['PHExitPH_6', '6a.1 and 6b.1', :B6],
        ['PHReturn0to180_6', '6a.1 and 6b.1', :C6],
        ['PHReturn181to365_6', '6a.1 and 6b.1', :E6],
        ['PHReturn366to730_6', '6a.1 and 6b.1', :G6],

        ['SHTHRRHCat3Leavers_6', '6c.1', :C2],
        ['SHTHRRHCat3ExitPH_6', '6c.1', :C3],

        ['PSHCat3Clients_6', '6c.2', :C2],
        ['PSHCat3StayOrExitPH_6', '6c.2', :C3],

        ['SOExit_7', '7a.1', :C2],
        ['SOExitTempInst_7', '7a.1', :C3],
        ['SOExitPH_7', '7a.1', :C4],

        ['ESSHTHRRHExit_7', '7b.1', :C2],
        ['ESSHTHRRHToPH_7', '7b.1', :C3],

        ['PHClients_7', '7b.2', :C2],
        ['PHClientsStayOrExitPH_7', '7b.2', :C3], # Spec says C2, AAQ submitted
      ].each do |label, table_name, cell_name|
        cell_value = if table_name.present?
          @report.answer(question: table_name, cell: cell_name)&.summary || ''
        else
          cell_name
        end
        csv << [label, cell_value]
      end
    end

    private def add_dq_rows(csv)
      [
        'ESSH_UndupHMIS_DQ',
        'TH_UndupHMIS_DQ',
        'PSHOPH_UndupHMIS_DQ',
        'RRH_UndupHMIS_DQ',
        'StOutreach_UndupHMIS_DQ',
        'ESSH_LeaversHMIS_DQ',
        'TH_LeaversHMIS_DQ',
        'PSHOPH_LeaversHMIS_DQ',
        'RRH_LeaversHMIS_DQ',
        'StOutreach_LeaversHMIS_DQ',
        'ESSH_DkRMHMIS_DQ',
        'TH_DkRMHMIS_DQ',
        'PSHOPH_DkRMHMIS_DQ',
        'RRH_DkRMHMIS_DQ',
        'StOutreach_DkRMHMIS_DQ',
      ].each do |label|
        value = ''
        csv << [label, value]
      end
    end
  end
end
