###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Exporter
  class HmisParticipation::Overrides
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
      missing_type = if row.project&.organization&.VictimServiceProvider == 1
        2 # Assume VSPs are using a CD if we don't know
      else
        0
      end

      row = replace_blank(row, hud_field: :HMISParticipationType, default_value: missing_type)
      row.HMISParticipationStatusStartDate ||= row.project.OperatingStartDate

      row
    end
  end
end
