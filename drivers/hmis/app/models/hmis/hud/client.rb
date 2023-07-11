###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Client < Hmis::Hud::Base
  extend OrderAsSpecified
  include ::HmisStructure::Client
  include ::Hmis::Hud::Concerns::Shared
  include ::HudConcerns::Client
  include ClientSearch

  attr_accessor :gender, :race

  self.table_name = :Client
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  self.ignored_columns = ['preferred_name']

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  has_many :names, **hmis_relation(:PersonalID, 'CustomClientName'), inverse_of: :client
  has_many :addresses, **hmis_relation(:PersonalID, 'CustomClientAddress'), inverse_of: :client
  has_many :contact_points, **hmis_relation(:PersonalID, 'CustomClientContactPoint'), inverse_of: :client
  has_one :primary_name, -> { where(primary: true) }, **hmis_relation(:PersonalID, 'CustomClientName'), inverse_of: :client

  # Enrollments for this Client, including WIP Enrollments
  has_many :enrollments, **hmis_relation(:PersonalID, 'Enrollment'), dependent: :destroy
  # Projects that this Client is enrolled in, NOT inluding WIP enrollments
  has_many :projects, through: :enrollments
  # WIP records representing enrollments for this Client
  has_many :wip, class_name: 'Hmis::Wip', through: :enrollments

  has_many :custom_assessments, through: :enrollments

  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :clients
  has_many :income_benefits, through: :enrollments
  has_many :disabilities, through: :enrollments
  has_many :health_and_dvs, through: :enrollments
  has_many :youth_education_statuses, through: :enrollments
  has_many :employment_educations, through: :enrollments
  has_many :households, through: :enrollments
  has_many :client_files, class_name: 'GrdaWarehouse::ClientFile', primary_key: :id, foreign_key: :client_id
  has_many :files, class_name: '::Hmis::File', dependent: :destroy, inverse_of: :client
  has_many :current_living_situations, through: :enrollments
  has_many :hmis_services, through: :enrollments # All services (HUD and Custom)
  has_many :custom_data_elements, as: :owner
  has_many :client_projects
  has_many :projects_including_wip, through: :client_projects, source: :project

  accepts_nested_attributes_for :custom_data_elements, allow_destroy: true
  accepts_nested_attributes_for :names, allow_destroy: true
  accepts_nested_attributes_for :addresses, allow_destroy: true
  accepts_nested_attributes_for :contact_points, allow_destroy: true

  # NOTE: only used for getting the client's Warehouse ID. Should not be used for anything else. See #184132767
  has_one :warehouse_client_source, class_name: 'GrdaWarehouse::WarehouseClient', foreign_key: :source_id, inverse_of: :source

  validates_with Hmis::Hud::Validators::ClientValidator

  CUSTOM_NAME_OPTIONS = {
    association: :names,
    klass: Hmis::Hud::CustomClientName,
    field_map: {
      FirstName: :first,
      LastName: :last,
    },
  }.freeze

  attr_accessor :image_blob_id
  attr_accessor :create_mci_id
  attr_accessor :update_mci_attributes
  after_save do
    current_image_blob = ActiveStorage::Blob.find_by(id: image_blob_id)
    self.image_blob_id = nil
    if current_image_blob
      file = GrdaWarehouse::ClientFile.new(
        client_id: id,
        user_id: user.id,
        name: 'Client Headshot',
        visible_in_window: false,
      )
      file.tag_list.add('Client Headshot')
      file.client_file.attach(current_image_blob)
      file.save!
    end
  end

  after_save do
    if HmisExternalApis::AcHmis::Mci.enabled?
      # Create a new MCI ID if specified by the ClientProcessor
      if create_mci_id
        self.create_mci_id = nil
        HmisExternalApis::AcHmis::Mci.new.create_mci_id(self)
      end

      # For MCI-linked clients, we notify the MCI any time relevant fields change (name, dob, etc).
      # 'update_mci_attributes' attr is specified by the ClientProcessor
      if update_mci_attributes
        self.update_mci_attributes = nil
        trigger_columns = HmisExternalApis::AcHmis::UpdateMciClientJob::MCI_CLIENT_COLS
        relevant_fields_changed = trigger_columns.any? { |field| previous_changes&.[](field) }
        HmisExternalApis::AcHmis::UpdateMciClientJob.perform_later(client_id: id) if relevant_fields_changed
      end
    end
  end

  scope :with_access, ->(user, *permissions, **kwargs) do
    pids = Hmis::Hud::Project.with_access(user, *permissions, **kwargs).pluck(:id)

    unenrolled_ids = user.permissions?(*permissions, **kwargs) ? unenrolled.joins(:data_source).merge(GrdaWarehouse::DataSource.hmis(user)).pluck(:id) : []
    enrolled_ids = joins(:projects).where(p_t[:id].in(pids)).pluck(:id)
    wip_ids = joins(:wip).where(wip_t[:project_id].in(pids)).pluck(:id)

    where(id: unenrolled_ids + enrolled_ids + wip_ids)
  end

  scope :visible_to, ->(user) do
    with_access(user, :can_view_clients)
  end

  class << self
    alias viewable_by visible_to
  end

  scope :searchable_to, ->(user) do
    visible_to(user)
  end

  scope :matching_search_term, ->(text_search) do
    text_searcher(text_search, custom_name_options: CUSTOM_NAME_OPTIONS) do |where|
      left_outer_joins(:names).where(where).pluck(:id)
    rescue RangeError
      return none
    end
  end

  scope :older_than, ->(age, or_equal: false) do
    target_dob = Date.today - (age + 1).years
    target_dob = Date.today - age.years if or_equal == true

    where(c_t[:dob].lt(target_dob))
  end

  # Clients that have no Enrollments (WIP or otherwise)
  scope :unenrolled, -> do
    # Clients that have no projects, AND no wip enrollments
    left_outer_joins(:projects, :wip).where(p_t[:id].eq(nil).and(wip_t[:id].eq(nil)))
  end

  def enrolled?
    enrollments.any?
  end

  def self.source_for(destination_id:, user:)
    source_id = GrdaWarehouse::WarehouseClient.find_by(destination_id: destination_id, data_source_id: user.hmis_data_source_id).source_id
    return nil unless source_id.present?

    searchable_to(user).where(id: source_id)
  end

  def ssn_serial
    self.SSN&.[](-4..-1)
  end

  def warehouse_id
    warehouse_client_source&.destination_id
  end

  def warehouse_url
    "https://#{ENV['FQDN']}/clients/#{id}/from_source"
  end

  private def clientview_url(mci_id_value)
    link_base = HmisExternalApis::AcHmis::Clientview.link_base
    return unless link_base&.present? && mci_id_value&.present?

    "#{link_base}/ClientInformation/Profile/#{mci_id_value}?aid=2"
  end

  def external_identifiers
    external_identifiers = [
      {
        type: :client_id,
        identifier: id,
        label: 'HMIS ID',
      },
      {
        type: :personal_id,
        identifier: personal_id,
        label: 'Personal ID',
      },
      {
        type: :warehouse_id,
        identifier: warehouse_id,
        url: warehouse_url,
        label: 'Warehouse ID',
      },
    ]

    if HmisExternalApis::AcHmis::Mci.enabled?
      if ac_hmis_mci_ids.present?
        ac_hmis_mci_ids.to_a.each do |mci_id|
          external_identifiers << {
            type: :mci_id,
            identifier: mci_id.value,
            url: clientview_url(mci_id.value),
            label: 'MCI ID',
          }
        end
      else
        external_identifiers << {
          type: :mci_id,
          identifier: nil,
          url: nil,
          label: 'MCI ID',
        }
      end
    end

    external_identifiers
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

  # Unused
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
      scope = text_searcher(input.text_search, custom_name_options: CUSTOM_NAME_OPTIONS) do |where|
        scope.left_outer_joins(:names).where(where).pluck(:id)
      end
    end

    if input.first_name.present?
      query = c_t[:FirstName].matches("#{input.first_name}%")
      ccn_query = ccn_t[:first].matches("#{input.first_name}%")
      query = nickname_search(query, input.first_name)
      query = metaphone_search(query, :FirstName, input.first_name)
      client_id_query = scope.left_outer_joins(:names).
        where(query.or(ccn_query)).
        pluck(:id)
      scope = scope.where(id: client_id_query)
    end

    if input.last_name.present?
      query = c_t[:LastName].matches("#{input.last_name}%")
      ccn_query = ccn_t[:last].matches("#{input.first_name}%")
      query = nickname_search(query, input.last_name)
      query = metaphone_search(query, :LastName, input.last_name)
      client_id_query = scope.left_outer_joins(:names).
        where(query.or(ccn_query)).
        pluck(:id)
      scope = scope.where(id: client_id_query)
    end

    # TODO: nicks and/or metaphone searches?
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

  # fix these so they use DATA_NOT_COLLECTED And the other standard names
  use_enum(:gender_enum_map, ::HudUtility.genders) do |hash|
    hash.map do |value, desc|
      {
        key: [8, 9, 99].include?(value) ? desc : ::HudUtility.gender_id_to_field_name[value],
        value: value,
        desc: desc,
        null: [8, 9, 99].include?(value),
      }
    end
  end

  use_enum(:race_enum_map, ::HudUtility.races.except('RaceNone'), include_base_null: true) do |hash|
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
    @image ||= client_files&.client_photos&.newest_first&.first&.client_file
  end

  def delete_image
    client_files&.client_photos&.newest_first&.first&.destroy!
    @image = nil
  end

  # Mirrors `clientBriefName` in frontend
  def brief_name
    [first_name, last_name].compact.join(' ')
  end

  include RailsDrivers::Extensions
end
