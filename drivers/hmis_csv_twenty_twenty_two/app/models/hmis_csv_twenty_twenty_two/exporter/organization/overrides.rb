###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class Organization::Overrides
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
      row = self.class.apply_overrides(row, options: @options)

      row
    end

    def self.apply_overrides(row, options:)
      row = replace_blank(row, hud_field: :VictimServiceProvider, default_value: 99)
      row = ensure_reasonable_name(row, confidential: options[:confidential])

      row
    end

    def self.ensure_reasonable_name(row, confidential: false)
      if confidential
        row.OrganizationName = GrdaWarehouse::Hud::Organization.confidential_organization_name
        row.OrganizationCommonName = row.OrganizationName
      end
      row.OrganizationCommonName = row.OrganizationName if row.OrganizationCommonName.blank?
      row.OrganizationCommonName = row.OrganizationCommonName[0...50] if row.OrganizationCommonName.present?

      row
    end
  end
end
