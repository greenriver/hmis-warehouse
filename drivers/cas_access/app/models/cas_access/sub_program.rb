###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/boston-cas/blob/production/LICENSE.md
###

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
