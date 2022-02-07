###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Importers::HmisAutoDetect
  def self.available_importers
    Rails.application.config.hmis_importers || []
  end

  def self.add_importer(importer)
    importers = available_importers
    importers << importer
    Rails.application.config.hmis_importers = importers
  end
end
