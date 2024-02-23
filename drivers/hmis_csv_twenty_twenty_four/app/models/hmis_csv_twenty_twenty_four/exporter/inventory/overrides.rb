###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Exporter
  class Inventory::Overrides
    include ::HmisCsvTwentyTwentyFour::Exporter::ExportConcern

    def initialize(options)
      @options = options
    end

    # This method gets called for each row of the kiba export
    # to enable these overrides to be applied outside of the kiba context, the overrides are written as class methods that take
    # an instance of the class, with appropriate preloads and returns an overridden version.
    # in addition, there is a single `apply_overrides` method if you want all of them
    # the `process method` will apply all overrides, and then set primary and foreign keys correctly for export
    def process(row)
      row = self.class.apply_overrides(row)

      row
    end

    def self.apply_overrides(row)
      [
        { hud_field: :CoCCode, override_field: nil, default_value: best_coc(row) },
      ].each do |settings|
        row = simple_override(row, **settings)
      end

      row
    end

    def self.best_coc(row)
      return row.CoCCode if row.CoCCode.present?

      project_cocs = row.project&.project_cocs&.map(&:CoCCode)
      project_cocs.uniq!
      # If we have more than one project coc, don't guess
      return nil if project_cocs.blank? || project_cocs.count > 1

      project_cocs.first
    end
  end
end
