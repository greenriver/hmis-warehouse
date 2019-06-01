###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::ClientNotes
  class HomeLinkNote < Base 
    def self.type_name
      "Note Migrated from HomeLink"
    end
  end
end 
