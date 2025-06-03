###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::ValidationFiltering
  extend ActiveSupport::Concern

  included do
    private def detect_filename
      filename = params[:file] + '.csv'
      importable_files(version: version(importer_log, @import)).keys.detect { |v| v == filename }
    end

    private def pattern
      importable_file(version: version(importer_log, @import), filename: @filename).downcase
    end

    private def filter_setup
      @validation_classes = @validations.distinct.pluck(:type, :validated_column).
        map do |type, col|
          title = type.constantize.title
          title += " for #{col}" if col
          [
            title,
            [
              type,
              col,
            ],
          ]
        end.to_h
      chosen_option = params.dig(:filters, :validation)

      selected_validation, column = if chosen_option
        @validation_classes.values.detect { |m| m.to_s == chosen_option }
      else
        @validation_classes.values.first
      end
      @filters = OpenStruct.new(
        selected_validation: selected_validation,
        column: column,
        validation: [selected_validation, column].to_s,
      )
    end
  end
end
