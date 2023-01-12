###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::AssessmentDetail < ::GrdaWarehouseBase
  include Hmis::Hud::Concerns::HasEnums
  self.table_name = :hmis_assessment_details
  belongs_to :assessment, class_name: 'Hmis::Hud::Assessment'
  belongs_to :definition
  has_one :processor, dependent: :destroy

  def initialize(*)
    super
    build_processor
  end

  scope :with_role, ->(role) do
    where(role: role)
  end
end
