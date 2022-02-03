###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'csv'
module ClaimsReporting
  class CcsLookup < HealthBase
    # e.g. ClaimsReporting::CcsLookup.load_csv('tmp/CCS/2019_ccs_services_procedures.csv', '1992-01-01'..'2020-12-31')
    def self.load_csv(file, effective_range)
      data = []
      CSV.foreach(file,
                  'r:us-ascii',
                  row_sep: :auto,
                  headers: true,
                  quote_char: '"',
                  skip_lines: /Valid codes are in ranges|CLINCAL CLASSIFICATIONS SOFTWARE/) do |row|
        range = row['Code Range'].gsub("'", '').split('-')
        data << {
          hcpcs_start: range.first,
          hcpcs_end: range.last,
          ccs_id: row['CCS'],
          ccs_label: row['CCS Label'],
          effective_start: effective_range&.min,
          effective_end: effective_range&.max,
        }
      end
      import(data, on_duplicate_key_update: {
               conflict_target: [:effective_start, :hcpcs_start, :hcpcs_end],
               columns: [:ccs_id, :ccs_label, :updated_at],
             }).ids.count
    end

    def self.lookup_table
      @lookup_table ||= all.order(hcpcs_start: :asc, effective_start: :asc).readonly.to_a
    end

    def self.classify_medical_claims(scope = ClaimsReporting::MedicalClaim.all)
      scope.select(:id, :ccs_id, :procedure_code).in_batches do |batch|
        updates = batch.map do |c|
          {
            id: c.id,
            ccs_id: lookup(c.procedure_code, nil)&.ccs_label,
          }
        end
        scope.import(updates, on_duplicate_key_update: { conflict_target: [:id], columns: [:ccs_id] })
      end
    end

    def self.lookup(hcpcs, date = nil)
      date = date&.to_date
      hcpcs = hcpcs.to_s
      lookup_table.bsearch do |e|
        if hcpcs < e.hcpcs_start
          -1
        elsif hcpcs > e.hcpcs_end
          1
        elsif date && date < e.effective_start
          -1
        elsif date && date > e.effective_end
          1
        else
          0
        end
      end
    end
  end
end
