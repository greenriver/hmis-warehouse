###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientSearchUtil
  class ClientSearchableName < Hmis::HmisBase
    self.table_name = :client_searchable_names
    include ::Hmis::Concerns::HmisArelHelper
  end
end
