module HmisCsvTwentyTwenty::Importer
  module ImportConcern
    extend ActiveSupport::Concern

    included do
      belongs_to :importer_log

      def self.clean_row_for_import(row, deidentified:) # rubocop:disable  Lint/UnusedMethodArgument
        row
      end

      def self.date_columns
        hmis_columns = hmis_structure(version: '2020').keys
        content_columns.select do |c|
          c.type == :date && c.name.to_sym.in?(hmis_columns)
        end.map do |c|
          c.name.to_s
        end
      end

      def self.new_from(loaded)
        new(loaded.hmis_data.merge(source_type: loaded.class.name, source_id: loaded.id))
      end

      def calculate_processed_as
        keys = self.class.hmis_structure(version: '2020').keys - [:ExportID]
        Digest::SHA256.hexdigest(slice(keys).join('|'))
      end

      def set_processed_as
        self.processed_as = calculate_processed_as
      end

      def fix_date_columns
        raise FIXME
      end

      def run_row_validations
        raise FIXME
      end
    end
  end
end
