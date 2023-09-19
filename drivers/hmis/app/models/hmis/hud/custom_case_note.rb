###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::CustomCaseNote < Hmis::Hud::Base
  self.table_name = :CustomCaseNote
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  belongs_to :user, **hmis_relation(:UserID, 'User')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  alias_to_underscore [:CustomCaseNoteID, :PersonalID, :EnrollmentID]

  replace_scope :viewable_by, ->(user) do
    client_scope = Hmis::Hud::Client.viewable_by(user)
    enrollment_scope = Hmis::Hud::Enrollment.viewable_by(user)

    case_statement = Arel::Nodes::Case.new
      .when(arel_table[:EnrollmentID].not_eq(nil))
      .then(arel_table[:EnrollmentID].in(enrollment_scope.select(:enrollment_id).arel))
      .else(arel_table[:PersonalID].in(client_scope.select(:personal_id).arel))

    viewable_scope = Hmis::Hud::CustomCaseNote
      .left_outer_joins(:client)
      .left_outer_joins(:enrollment)
      .where(case_statement)
    where(id: viewable_scope.select(:id))
  end

  def self.hud_key
    :CustomCaseNoteID
  end
end
