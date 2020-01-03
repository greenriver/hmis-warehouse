###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Cas
  class ClientOpportunityMatch < CasBase
    belongs_to :client
    scope :proposed, -> { where active: false, closed: false }
    scope :candidate, -> { proposed } # alias
    scope :active, -> { where active: true }
    scope :closed, -> { where closed: true }
    scope :successful, -> { where closed: true, closed_reason: 'success' }
    scope :rejected, -> { where closed: true, closed_reason: 'rejected' }
    scope :preempted, -> { where closed: true, closed_reason: 'preempted' }
  end
end
