###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasAccess
  class ClientOpportunityMatchContact < CasBase
    self.table_name = 'client_opportunity_match_contacts'
    belongs_to :match, class_name: 'CasAccess::ClientOpportunityMatch'
    belongs_to :contact
  end
end
