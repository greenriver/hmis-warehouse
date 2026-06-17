###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CasAccess::Program < CasBase
  self.table_name = :programs
  include CasAccess::ControlledVisibility
  acts_as_paranoid
  has_many :sub_programs, inverse_of: :program
end
