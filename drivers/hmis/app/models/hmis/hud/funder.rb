###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Funder < Hmis::Hud::Base
  include ::HmisStructure::Funder
  include ::Hmis::Hud::Shared
  self.table_name = :Funder
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  validates_with Hmis::Hud::Validators::FunderValidator

  belongs_to :project, **hmis_relation(:ProjectID, 'Project')

  use_enum :funding_source_enum_map, ::HUD.funding_sources

  # TODO validate other_funder Required if 2.06.1 = 46

  scope :viewable_by, ->(user) do
    viewable_projects = Hmis::Hud::Project.viewable_by(user).pluck(:id)
    where(project_id: viewable_projects, data_source_id: user.hmis_data_source_id)
  end

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
end
