###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Client < Hmis::Hud::Base
  include ::HmisStructure::Client
  include ::Hmis::Hud::Shared
  include ArelHelper
  include ClientSearch

  attr_accessor :gender, :race
  attr_writer :skip_validations

  self.table_name = :Client
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  validates_with Hmis::Hud::Validators::ClientValidator

  scope :visible_to, ->(user) do
    joins(:data_source).merge(GrdaWarehouse::DataSource.hmis(user))
  end

  scope :searchable_to, ->(user) do
    # TODO: additional access control rules go here
    visible_to(user)
  end

  def skip_validations
    @skip_validations ||= []
  end

  def self.source_for(destination_id:, user:)
    source_id = GrdaWarehouse::WarehouseClient.find_by(destination_id: destination_id, data_source_id: user.hmis_data_source_id).source_id
    return nil unless source_id.present?

    searchable_to(user).where(id: source_id)
  end

  def ssn_serial
    self.SSN&.[](-4..-1)
  end

  has_many :enrollments, **hmis_relation(:PersonalID, 'Enrollment')
  has_many :projects, through: :enrollments

  SORT_OPTIONS = [:last_name_asc, :last_name_desc].freeze

  def self.client_search(input:, user: nil)
    # Apply ID searches directly, as they can only ever return a single client
    return searchable_to(user).where(id: input.id) if input.id.present?
    return searchable_to(user).where(PersonalID: input.personal_id) if input.personal_id
    return source_for(destination_id: input.warehouse_id, user: user) if input.warehouse_id

    # Build search scope
    scope = GrdaWarehouse::Hud::Client.where(id: searchable_to(user).select(:id))
    if input.text_search.present?
      scope = text_searcher(input.text_search) do |where|
        scope.where(where).pluck(:id)
      end
    end

    if input.first_name.present?
      query = c_t[:FirstName].matches("#{input.first_name}%")
      query = nickname_search(query, input.first_name)
      query = metaphone_search(query, :FirstName, input.first_name)
      scope = scope.where(query)
    end

    if input.last_name.present?
      query = c_t[:LastName].matches("#{input.last_name}%")
      query = nickname_search(query, input.last_name)
      query = metaphone_search(query, :LastName, input.last_name)
      scope = scope.where(query)
    end

    # TODO: nicks and/or metaphone searches?
    scope = scope.where(c_t[:preferred_name].matches("#{input.preferred_name}%")) if input.preferred_name.present?
    scope = scope.where(c_t[:SSN].matches("%#{input.ssn_serial}")) if input.ssn_serial.present?
    scope = scope.where(c_t[:DOB].eq(Date.parse(input.dob))) if input.dob.present?

    # TODO: projects
    # TODO: organizations

    Hmis::Hud::Client.where(id: scope.select(:id))
  end

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :last_name_asc
      order(:LastName)
    when :last_name_desc
      order(LastName: :desc)
    else
      raise NotImplementedError
    end
  end

  def self.name_data_quality_enum_map
    Hmis::FieldMap.new(
      ::HUD.name_data_quality_options.map do |value, desc|
        {
          key: desc,
          value: value,
          desc: desc,
          null: [8, 9, 99].include?(value),
        }
      end,
      include_base_null: false,
    )
  end

  def self.ssn_data_quality_enum_map
    Hmis::FieldMap.new(
      ::HUD.ssn_data_quality_options.map do |value, desc|
        {
          key: desc,
          value: value,
          desc: desc,
          null: [8, 9, 99].include?(value),
        }
      end,
      include_base_null: false,
    )
  end

  def self.dob_data_quality_enum_map
    Hmis::FieldMap.new(
      ::HUD.dob_data_quality_options.map do |value, desc|
        {
          key: desc,
          value: value,
          desc: desc,
          null: [8, 9, 99].include?(value),
        }
      end,
      include_base_null: false,
    )
  end

  def self.race_enum_map
    Hmis::FieldMap.new(
      ::HUD.races.except('RaceNone').map do |field, desc|
        {
          key: field,
          value: field,
          desc: desc,
        }
      end,
      include_base_null: true,
    )
  end

  def self.gender_enum_map
    Hmis::FieldMap.new(
      ::HUD.genders.map do |value, desc|
        {
          key: desc,
          value: value,
          desc: desc,
          null: [8, 9, 99].include?(value),
        }
      end,
      include_base_null: false,
    )
  end

  def self.ethnicity_enum_map
    Hmis::FieldMap.new(
      ::HUD.ethnicities.slice(0, 1).map do |value, desc|
        {
          key: desc,
          value: value,
          desc: desc,
        }
      end,
    )
  end

  def self.veteran_status_enum_map
    Hmis::FieldMap.no_yes_reasons
  end
end
