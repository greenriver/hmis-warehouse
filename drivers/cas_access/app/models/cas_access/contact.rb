###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasAccess
  class Contact < CasBase
    self.table_name = :contacts
    belongs_to :user, optional: true
  end
end
