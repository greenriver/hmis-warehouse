###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Funder < Hmis::Hud::Base
  self.table_name = :Funder
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::Funder
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::ProjectRelated
  include ::Hmis::Hud::Concerns::HasCustomDataElements

  validates_with Hmis::Hud::Validators::FunderValidator

  belongs_to :project, **hmis_relation(:ProjectID, 'Project')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true, inverse_of: :projects
  has_many :custom_data_elements, as: :owner, dependent: :destroy

  accepts_nested_attributes_for :custom_data_elements, allow_destroy: true

  SORT_OPTIONS = [:start_date].freeze

  scope :open_on_date, ->(date = Date.current) do
    on_or_after_start = f_t[:start_date].lteq(date)
    on_or_before_end = f_t[:end_date].eq(nil).or(f_t[:end_date].gteq(date))
    where(on_or_after_start.and(on_or_before_end))
  end

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

  def active_on?(date = Date.current)
    return false if start_date.nil?
    return false if start_date > date

    end_date.nil? || end_date >= date
  end
  alias active? active_on?
end
