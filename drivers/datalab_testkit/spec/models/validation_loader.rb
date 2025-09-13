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
        # Remove the CSV extension and capitalize the first letter to match the warehouse question names
        question = row['Filename'].gsub('.csv', '').sub('q', 'Q')
        source_question = row['Filename'].gsub('.csv', '').sub('q', 'Q')

        # -1 means all project types are applicable
        project_types = if row['Applicable project types'] == '-1'
          HudUtility2026.project_types.keys.freeze
        else
          row['Applicable project types'].split(',').map(&:to_i)
        end
        validations[row['Report']][question] ||= []
        validations[row['Report']][question] << {
          total: row['Field to validate'],
          source: {
            question: source_question,
            expression: row['Values to check against'],
            relevant_project_types: project_types,
          },
        }
      end
    end
    validations
  end
end
