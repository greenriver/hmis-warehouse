###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'roo'
module Hl7
  class ValueSetCode < HealthBase
    def self.load_from_xlsx(file, sheet:, headers: nil)
      headers ||= {
        value_set_name: 'Value Set Name',
        value_set_oid: 'Value Set OID',
        value_set_version: 'Value Set Version',
        code_system: 'Code System',
        code_system_oid: 'Code System OID',
        code_system_version: 'Code System Version',
        code: 'Code',
        definition: 'Definition',
      }

      records_read = 0
      batch = []
      insert_batch_size = 500
      start = Time.current

      bm = Benchmark.measure do
        logger.info { "Hl7::ValueSetCode#load_from_xlsx parsing #{file} sheet:#{sheet}" }
        data = ::Roo::Excelx.new(file).sheet(sheet).parse(**headers)
        logger.info { 'Hl7::ValueSetCode#load_from_xlsx processing rows' }

        transaction do
          data.each do |row|
            records_read += 1
            record = row.merge(created_at: start, updated_at: start)
            batch << record
            if batch.size >= insert_batch_size
              upsert batch
              batch.clear
            end
          end
          upsert batch
        end
      end
      {
        elapsed_seconds: bm.real,
        cpu_seconds: bm.total,
        records_read: records_read,
        rps: (records_read / bm.real).round,
        # failures: [],
      }
    end

    # #import with preconfigured options to upsert a batch of new
    # data
    def self.upsert(batch, dedupe: true)
      logger.info { "Hl7::ValueSetCode#load_from_xlsx upsert batch.size=#{batch.size}" }

      if dedupe
        grouped_by_key = batch.group_by { |row| row.values_at(:value_set_oid, :code_system_oid, :code) }.values
        dupes = grouped_by_key.select { |rows| rows.size > 1 }
        if dupes.any?
          logger.warn "Found #{dupes.size} sets of rows with duplicate keys. Using the first value found: #{dupes.inspect}"
          batch = grouped_by_key.map(&:first)
        end
      end

      import(batch, validate: false, on_duplicate_key_update: {
         conflict_target: [:value_set_oid, :code_system, :code],
         columns: [
           :value_set_name,
           :value_set_version,
           :code_system,
           :code_system_version,
           :code,
           :definition,
           :updated_at,
         ],
       })
    end
  end
end
