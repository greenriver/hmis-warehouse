###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/boston-cas/blob/production/LICENSE.md
###

class CasAccess::SubProgram < CasBase
  acts_as_paranoid

  belongs_to :program, inverse_of: :sub_programs

  scope :open, -> do
    where(closed: false)
  end

  scope :closed, -> do
    where(closed: true)
  end
end
