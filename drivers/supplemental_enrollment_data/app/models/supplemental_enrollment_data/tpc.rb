###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'roo'
require 'roo-xls'
module SupplementalEnrollmentData
  class Tpc < ::GrdaWarehouseBase
    # Re-using the existing table
    self.table_name = :enrollment_extras
    belongs_to :file, class_name: 'GrdaWarehouse::NonHmisUpload'
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', primary_key: [:EnrollmentID, :data_source_id], foreign_key: [:hud_enrollment_id, :data_source_id]
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', primary_key: [:PersonalID, :data_source_id], foreign_key: [:client_id, :data_source_id]

    def self.title
      'Supplemental Enrollment Data'
    end

    def self.to_partial_path
      'supplemental_enrollment_data/tpc'
    end

    def self.describe
      "Use this form to upload data specifically related to the CE Performance report.  The attached file should be an **XLSX** file with the following headers in the first tab:

#{expected_headers.join(', ')}"
    end

    def self.expected_headers
      spec.values
    end

    def self.spec
      {
        hud_enrollment_id: 'Entry Exit Uid',
        enrollment_group_id: 'Entry Exit Group Id',
        client_id: 'Client Uid',
        client_uid: 'Client Unique Id',
        project_name: 'Entry Exit Provider Id',
        entry_date: 'Entry Date',
        exit_date: 'Exit Date',
        vispdat_ended_at: 'VI-SPDAT Date',
        vispdat_type: 'VI-SPDAT Type',
        vispdat_grand_total: 'VI-SPDAT Score',
        vispdat_range: 'VI-SPDAT Range',
        prioritization_tool_type: 'Prioritization Tool Type',
        prioritization_tool_score: 'Prioritization Tool Score',
        agency_name: 'Agency Name:',
        community: 'City/County',
        lgbtq_household_members: 'Do any members of your household identify as LGBT?',
        client_lgbtq: 'Do you identify as LGBT?',
        dv_survivor: 'Do you consider yourself a survivor of interpersonal violence?',
        prevention_tool_score: 'Prevention Tool Score:',
      }
    end

    def self.conflict_update_columns
      spec.keys + [:file_id, :data_source_id]
    end

    def self.conflict_key
      [
        :hud_enrollment_id,
        :entry_date,
        :vispdat_ended_at,
        :project_name,
        :agency_name,
        :community,
        :data_source_id,
      ]
    end

    def self.run!(data_source_id, source_file, upload_id)
      workbook = Roo::Excelx.new(source_file)
      transaction do
        name = workbook.sheets[0]
        sheet = workbook.sheet(0)
        Rails.logger.info "Importing sheet #{name} from #{@source}"
        validate_headers(sheet, name)
        batch = []
        sheet.each(**spec).with_index do |row, i|
          # skip the header line
          next if i.zero?

          batch << new(row.merge(data_source_id: data_source_id, file_id: upload_id))
        end
        import!(
          batch,
          on_duplicate_key_update: { conflict_target: conflict_key, columns: conflict_update_columns },
        )
      end
    end

    def self.validate_headers(sheet, name)
      sheet_headers = sheet.to_a[1]
      return if sheet_headers.sort == expected_headers.sort

      raise "Unexpected headers in: #{name} \n #{sheet_headers.inspect} \n Looking for: \n #{expected_headers.inspect}"
    end
  end
end
