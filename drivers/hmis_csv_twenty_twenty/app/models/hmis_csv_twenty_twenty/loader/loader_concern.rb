module HmisCsvTwentyTwenty::Loader
  module LoaderConcern
    extend ActiveSupport::Concern

    included do
      acts_as_copy_target
      # def self.clean_row_for_import(row, deidentified:) # Lint/UnusedMethodArgument
      #   row
      # end

      # def self.date_columns
      #   hmis_columns = hmis_structure(version: '2020').keys
      #   content_columns.select do |c|
      #     c.type == :date && c.name.to_sym.in?(hmis_columns)
      #   end.map do |c|
      #     c.name.to_s
      #   end
      # end

      # def self.load_from_csv
      # end
    end
  end
end
