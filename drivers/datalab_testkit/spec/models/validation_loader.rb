# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ValidationLoader
  # Load validations for dynamic test generation at class level
  def self.load_validations
    validation_source_file = 'drivers/datalab_testkit/spec/fixtures/results/internal_consistency_validations/tup_validations.csv'
    validations = {}

    if File.exist?(validation_source_file)
      CSV.foreach(validation_source_file, headers: true) do |row|
        validations[row['Report']] ||= {}
        validations[row['Report']][row['Filename'].gsub('.csv', '')] ||= []
        validations[row['Report']][row['Filename'].gsub('.csv', '')] << {
          total: row['Field to validate'],
          source: {
            question: row['Filename'].gsub('.csv', ''),
            expression: row['Values to check against'],
          },
        }
      end
    end
    validations
  end
end
