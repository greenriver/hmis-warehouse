###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasAccess
  class Opportunity < CasBase
    self.table_name = :opportunities
    belongs_to :voucher, optional: true
    has_many :programs, through: :voucher
    has_many :opportunity_contacts

    has_one :status_match, -> { where arel_table[:active].eq(true).or(arel_table[:closed].eq(true).and(arel_table[:closed_reason].eq('success'))) }, class_name: 'ClientOpportunityMatch'
    has_many :closed_matches, -> do
      where(closed: true).
        order(updated_at: :desc)
    end, class_name: 'ClientOpportunityMatch'
  end
end
