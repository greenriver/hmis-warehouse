###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CasAccess::SubProgram < CasBase
  self.table_name = :sub_programs
  acts_as_paranoid

  belongs_to :program, inverse_of: :sub_programs

  scope :open, -> do
    where(closed: false)
  end

  scope :closed, -> do
    where(closed: true)
  end
end
