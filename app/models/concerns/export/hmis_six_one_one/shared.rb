require 'csv'
module Export::HMISSixOneOne::Shared
  extend ActiveSupport::Concern
  included do
    include NotifierConfig

    attr_accessor :file_path

    after_initialize do
      setup_notifier('HMIS Exporter 6.11')
    end
  end
  class_methods do
    def export_to_path export_scope:, path:, export: 
      export_path = File.join(path, file_name)
      export_id = export.export_id
      CSV.open(export_path, 'wb') do |csv|
        csv << clean_headers(hud_csv_headers)
        if paranoid? && export.include_deleted
          export_scope = export_scope.with_deleted
        end

        export_scope.pluck_in_batches(*columns_to_pluck, batch_size: 10000) do |batch|
          cleaned_batch = batch.map do |row|
            row = Hash[hud_csv_headers.zip(row)]
            row[:ExportID] = export_id
            csv << clean_row(row).values
          end
        end
      end
    end

    # Override as necessary
    def clean_headers(headers)
      headers
    end

    # Override as necessary
    def clean_row(row)
      row
    end

    def columns_to_pluck
      @columns_to_pluck ||= hud_csv_headers.map do |k|
        if k == hud_key.to_sym
          arel_table[:id].as(hud_key.to_s).to_sql
        else
          k
        end
      end
    end
  end
end