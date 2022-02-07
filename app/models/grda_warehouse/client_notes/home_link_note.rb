###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::ClientNotes
  class HomeLinkNote < Base
    def self.type_name
      'Note Migrated from HomeLink'
    end
  end
end
