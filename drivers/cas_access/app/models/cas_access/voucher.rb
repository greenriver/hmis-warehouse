###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CasAccess
  class Voucher < CasBase
    self.table_name = :vouchers
    belongs_to :sub_program, optional: true
    has_many :programs, through: :sub_program
  end
end
