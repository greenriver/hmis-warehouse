###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasAccess
  class Contact < CasBase
    self.table_name = :contacts
    belongs_to :user, optional: true
    has_many :clent_opportunity_match_contacts, class_name: 'CasAccess::ClientOpportunityMatchContact', inverse_of: :contact
    has_many :client_opportunity_matches, through: :clent_opportunity_match_contacts, source: :match
  end
end
