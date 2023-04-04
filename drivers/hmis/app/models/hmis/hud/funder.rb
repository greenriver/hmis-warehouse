###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Funder < Hmis::Hud::Base
  self.table_name = :Funder
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::Funder
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::ProjectRelated
  validates_with Hmis::Hud::Validators::FunderValidator

  belongs_to :project, **hmis_relation(:ProjectID, 'Project')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :projects

  SORT_OPTIONS = [:start_date].freeze

  # Convert funder string to int #183572073
  def Funder # rubocop:disable Naming/MethodName
    super&.to_i
  end

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :start_date
      order(start_date: :desc)
    else
      raise NotImplementedError
    end
  end

  def required_fields
    @required_fields ||= [
      :ProjectID,
      :Funder,
      :GrantID,
      :StartDate,
    ]
  end

  def active
    return true unless end_date.present?

    end_date >= Date.today
  end
end
