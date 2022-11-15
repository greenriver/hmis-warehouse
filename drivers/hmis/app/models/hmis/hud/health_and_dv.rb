###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::HealthAndDv < Hmis::Hud::Base
  include ::HmisStructure::HealthAndDv
  include ::Hmis::Hud::Shared
  self.table_name = :HealthAndDV
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  scope :viewable_by, ->(user) do
    joins(:enrollment).merge(Hmis::Hud::Enrollment.viewable_by(user))
  end

  scope :editable_by, ->(user) do
    joins(:enrollment).merge(Hmis::Hud::Enrollment.editable_by(user))
  end
end
