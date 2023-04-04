###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasAccess
  class Voucher < CasBase
    self.table_name = :vouchers
    belongs_to :sub_program, optional: true
    has_many :programs, through: :sub_program
  end
end
