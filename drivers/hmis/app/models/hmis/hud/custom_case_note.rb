###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

## "CustomCaseNote" is NOT a HUD defined record type. Although it uses CamelCase conventions, this model is particular to Open Path. CamelCase is used for compatibility with "Appendix C - Custom file transfer template"in the HUD HMIS CSV spec. This specifies optional additional CSV files with the naming convention of Custom*.csv

class Hmis::Hud::CustomCaseNote < Hmis::Hud::Base
  self.table_name = :CustomCaseNote
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  has_paper_trail(
    meta: {
      client_id: ->(r) { r.client&.id },
      enrollment_id: ->(r) { r.enrollment&.id },
      project_id: ->(r) { r.enrollment&.project&.id },
    },
  )

  include ::Hmis::Hud::Concerns::ClientProjectEnrollmentRelated
  include ::Hmis::Hud::Concerns::HasCustomDataElements

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :enrollment, **hmis_enrollment_relation, optional: true
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  alias_to_underscore [:CustomCaseNoteID, :PersonalID, :EnrollmentID]

  replace_scope :viewable_by, ->(user) do
    client_scope = Hmis::Hud::Client.viewable_by(user)
    enrollment_scope = Hmis::Hud::Enrollment.viewable_by(user)

    case_statement = Arel::Nodes::Case.new.
      when(arel_table[:EnrollmentID].not_eq(nil)).
      then(arel_table[:EnrollmentID].in(enrollment_scope.select(:enrollment_id).arel)).
      else(arel_table[:PersonalID].in(client_scope.select(:personal_id).arel))

    viewable_scope = Hmis::Hud::CustomCaseNote.
      left_outer_joins(:client).
      left_outer_joins(:enrollment).
      where(case_statement)
    where(id: viewable_scope.select(:id))
  end

  def self.hud_key
    :CustomCaseNoteID
  end

  SORT_OPTIONS = [:date_updated, :information_date, :date_created].freeze

  SORT_OPTION_DESCRIPTIONS = {
    date_updated: 'Date Updated',
    information_date: 'Information Date',
    date_created: 'Date Created',
  }.freeze

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :date_updated
      order(arel_table[:date_updated].desc)
    when :date_created
      order(arel_table[:date_created].desc)
    when :information_date
      order(arel_table[:information_date].desc.nulls_last)
    else
      raise NotImplementedError
    end
  end
end
