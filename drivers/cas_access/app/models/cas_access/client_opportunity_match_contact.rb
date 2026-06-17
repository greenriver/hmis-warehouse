###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CasAccess
  class ClientOpportunityMatchContact < CasBase
    self.table_name = 'client_opportunity_match_contacts'
    belongs_to :match, class_name: 'CasAccess::ClientOpportunityMatch'
    belongs_to :contact
  end
end
