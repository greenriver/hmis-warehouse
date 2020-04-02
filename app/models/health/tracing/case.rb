###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Describes a patient and contains PHI
# Control: PHI attributes NOT documented
module Health::Tracing
  class Case < HealthBase
    acts_as_paranoid
    has_paper_trail

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    has_many :locations
    has_many :contacts
    has_many :site_leaders
    has_many :staffs
  end
end
