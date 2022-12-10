###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasAccess
  class ClientOpportunityMatch < CasBase
    self.table_name = :client_opportunity_matches
    belongs_to :client, optional: true
    belongs_to :opportunity
    has_many :programs, through: :opportunity

    scope :proposed, -> { where active: false, closed: false }
    scope :candidate, -> { proposed } # alias
    scope :active, -> { where active: true }
    scope :closed, -> { where closed: true }
    scope :successful, -> { where closed: true, closed_reason: 'success' }
    scope :rejected, -> { where closed: true, closed_reason: 'rejected' }
    scope :preempted, -> { where closed: true, closed_reason: 'preempted' }
  end
end
