###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  module KibaExport
    module_function

    def export!(source_class:, source_config:, transforms:, dest_class:, dest_config:)
      job = Kiba.parse do
        source source_class, source_config

        transforms.each do |t|
          transform t
        end

        destination dest_class, dest_config
      end
      Kiba.run(job)
    end
  end
end
