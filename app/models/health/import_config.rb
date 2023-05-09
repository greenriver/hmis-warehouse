###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class ImportConfig < HealthBase
    self.table_name = :import_configs

    attr_encrypted :password, key: ENV['ENCRYPTION_KEY'][0..31]

    scope :epic_data, -> do
      where(kind: :epic_data)
    end
  end
end
