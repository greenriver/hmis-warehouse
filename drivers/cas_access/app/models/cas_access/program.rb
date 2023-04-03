###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/boston-cas/blob/production/LICENSE.md
###

class CasAccess::Program < CasBase
  self.table_name = :programs
  include CasAccess::ControlledVisibility
  acts_as_paranoid
  has_many :sub_programs, inverse_of: :program
end
