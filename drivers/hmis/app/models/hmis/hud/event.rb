###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Event < Hmis::Hud::Base
  self.table_name = :Event
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::Event
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :events
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  SORT_OPTIONS = [:event_date].freeze

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :event_date
      order(EventDate: :desc)
    else
      raise NotImplementedError
    end
  end
end
