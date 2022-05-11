###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class ProjectCoc::Overrides
    include ::HmisCsvTwentyTwentyTwo::Exporter::ExportConcern

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
        { hud_field: :CoCCode, override_field: :hud_coc_code },
        { hud_field: :GeographyType, override_field: :geography_type_override, default_value: 99 },
        { hud_field: :Geocode, override_field: :geocode_override, default_value: '0' * 6 },
        { hud_field: :Zip, override_field: :zip_override, default_value: '0' * 5 },

      ].each do |settings|
        row = simple_override(row, **settings)
      end

      # Technical limit of HMIS spec
      row.Address1 = row.Address1[0...100] if row.Address1
      row.Address2 = row.Address2[0...100] if row.Address2
      row.City = row.City[0...50] if row.City
      row.Zip = row.Zip.to_s.rjust(5, '0')[0...5] if row.Zip

      row
    end

    def self.best_coc(row, export)
      return row.CoCCode if row.CoCCode.present?

      if export.include_deleted || export.period_type == 1
        row.project_with_deleted&.project_cocs_with_deleted&.first&.CoCCode
      else
        row.project&.project_cocs&.first&.CoCCode
      end
    end
  end
end
