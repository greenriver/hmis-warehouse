###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Service < Hmis::Hud::Base
  include ::HmisStructure::Service
  include ::Hmis::Hud::Shared
  self.table_name = :Services
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :enrollment, **hmis_relation(:EnrollmentID, 'Enrollment')
  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :services
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  validates_with Hmis::Hud::Validators::ServiceValidator

  SORT_OPTIONS = [:date_provided].freeze

  scope :viewable_by, ->(user) do
    joins(:enrollment).merge(Hmis::Hud::Enrollment.viewable_by(user))
  end

  scope :editable_by, ->(user) do
    joins(:enrollment).merge(Hmis::Hud::Enrollment.editable_by(user))
  end

  def self.generate_services_id
    generate_uuid
  end

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :date_provided
      order(DateProvided: :desc)
    else
      raise NotImplementedError
    end
  end
end
