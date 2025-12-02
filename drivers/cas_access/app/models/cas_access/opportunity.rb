###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CasAccess
  class Opportunity < CasBase
    self.table_name = :opportunities
    belongs_to :voucher, optional: true
    has_many :programs, through: :voucher
    has_many :opportunity_contacts
  end
end
