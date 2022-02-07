###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::HMIS
  class ClientAttributeDefinedText < Base
    dub 'client_attributes_defined_text'

    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :client_attributes_defined_text, optional: true


  end
end
