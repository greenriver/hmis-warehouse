###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Client < Hmis::Hud::Base
  include ::HmisStructure::Client
  include ::Hmis::Hud::Concerns::Shared
  include ArelHelper
  include ClientSearch
  # include ClientImageConsumer

  attr_accessor :gender, :race

  self.table_name = :Client
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  has_many :enrollments, **hmis_relation(:PersonalID, 'Enrollment')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :clients

  # NOTE: this does not include project where the enrollment is WIP
  has_many :projects, through: :enrollments
  has_many :income_benefits, through: :enrollments
  has_many :disabilities, through: :enrollments
  has_many :health_and_dvs, through: :enrollments
  # has_many :client_files, class_name: 'GrdaWarehouse::ClientFile'
  has_many :current_living_situations, through: :enrollments

  validates_with Hmis::Hud::Validators::ClientValidator

  scope :visible_to, ->(user) do
    joins(:data_source).merge(GrdaWarehouse::DataSource.hmis(user))
  end

  scope :searchable_to, ->(user) do
    # TODO: additional access control rules go here
    visible_to(user)
  end

  def self.source_for(destination_id:, user:)
    source_id = GrdaWarehouse::WarehouseClient.find_by(destination_id: destination_id, data_source_id: user.hmis_data_source_id).source_id
    return nil unless source_id.present?

    searchable_to(user).where(id: source_id)
  end

  def ssn_serial
    self.SSN&.[](-4..-1)
  end

  SORT_OPTIONS = [
    :last_name_a_to_z,
    :last_name_z_to_a,
    :first_name_a_to_z,
    :first_name_z_to_a,
    :age_youngest_to_oldest,
    :age_oldest_to_youngest,
  ].freeze

  SORT_OPTION_DESCRIPTIONS = {
    last_name_a_to_z: 'Last Name: A-Z',
    last_name_z_to_a: 'Last Name: Z-A',
    first_name_a_to_z: 'First Name: A-Z',
    first_name_z_to_a: 'First Name: Z-A',
    age_youngest_to_oldest: 'Age: Youngest to Oldest',
    age_oldest_to_youngest: 'Age: Oldest to Youngest',
  }.freeze

  # ! Remove once concern works right
  def fake_client_image_data
    gender = if self[:Male].in?([1]) then 'male' else 'female' end
    age_group = if age.blank? || age > 18 then 'adults' else 'children' end
    image_directory = File.join('public', 'fake_photos', age_group, gender)
    available = Dir[File.join(image_directory, '*.jpg')]
    image_id = "#{self.FirstName}#{self.LastName}".sum % available.count
    Rails.logger.debug "Client#image id:#{self.id} faked #{self.PersonalID} #{available.count} #{available[image_id]}" # rubocop:disable Style/RedundantSelf
    image_data = File.read(available[image_id]) # rubocop:disable Lint/UselessAssignment
  end

  def self.client_search(input:, user: nil)
    # Apply ID searches directly, as they can only ever return a single client
    return searchable_to(user).where(id: input.id) if input.id.present?
    return searchable_to(user).where(PersonalID: input.personal_id) if input.personal_id
    return source_for(destination_id: input.warehouse_id, user: user) if input.warehouse_id

    # Build search scope
    scope = Hmis::Hud::Client.where(id: searchable_to(user).select(:id))
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

    scope = scope.joins(:projects).merge(Hmis::Hud::Project.viewable_by(user).where(id: input.projects)) if input.projects.present?
    scope = scope.joins(projects: :organization).merge(Hmis::Hud::Organization.viewable_by(user).where(id: input.organizations)) if input.organizations.present?

    Hmis::Hud::Client.where(id: scope.select(:id))
  end

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :last_name_a_to_z
      order(arel_table[:last_name].asc.nulls_last)
    when :last_name_z_to_a
      order(arel_table[:last_name].desc.nulls_last)
    when :first_name_a_to_z
      order(arel_table[:first_name].asc.nulls_last)
    when :first_name_z_to_a
      order(arel_table[:first_name].desc.nulls_last)
    when :age_youngest_to_oldest
      order(arel_table[:dob].desc.nulls_last)
    when :age_oldest_to_youngest
      order(arel_table[:dob].asc.nulls_last)
    when :recently_added
      order(arel_table[:date_created].desc.nulls_last)
    else
      raise NotImplementedError
    end
  end

  use_enum(:gender_enum_map, ::HUD.genders) do |hash|
    hash.map do |value, desc|
      {
        key: [8, 9, 99].include?(value) ? desc : ::HUD.gender_id_to_field_name[value],
        value: value,
        desc: desc,
        null: [8, 9, 99].include?(value),
      }
    end
  end

  use_enum(:race_enum_map, ::HUD.races.except('RaceNone'), include_base_null: true) do |hash|
    hash.map do |value, desc|
      {
        key: value,
        value: value,
        desc: desc,
      }
    end
  end

  def age(date = Date.current)
    GrdaWarehouse::Hud::Client.age(date: date, dob: self.DOB)
  end

  def image
    # TODO: Remove this when stub is no longer needed
    fake_client_image_data
  end
end
