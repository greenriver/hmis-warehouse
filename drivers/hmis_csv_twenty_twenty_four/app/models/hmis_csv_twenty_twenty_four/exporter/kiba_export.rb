###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Exporter
  module KibaExport
    module_function

    def export!(source_class:, source_config:, transforms:, dest_class:, dest_config:, options:)
      job = Kiba.parse do
        source(source_class, source_config)

        transforms.each do |t|
          transform(t, options)
        end

        destination(dest_class, **dest_config)
      end
      Kiba.run(job)
    end
  end
end
