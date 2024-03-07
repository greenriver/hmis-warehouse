###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Client < Hmis::Hud::Base
  extend OrderAsSpecified
  include ::HmisStructure::Client
  include ::Hmis::Hud::Concerns::Shared
  include ::HudConcerns::Client
  include ::HudChronicDefinition
  include ClientSearch

  has_paper_trail(meta: { client_id: :id })

  attr_accessor :gender, :race

  self.table_name = :Client
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  self.ignored_columns += [:preferred_name]

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  has_many :names, **hmis_relation(:PersonalID, 'CustomClientName'), inverse_of: :client, dependent: :destroy
  has_many(
    :addresses,
    # Exclude enrollment addresses from client record (per spec). This prevents client addresses from
    # clobbering enrollment.addresses when saved via accepts_nested_attributes_for
    -> { where(EnrollmentID: nil) },
    **hmis_relation(:PersonalID, 'CustomClientAddress'), inverse_of: :client, dependent: :destroy,
  )
  has_many :contact_points, **hmis_relation(:PersonalID, 'CustomClientContactPoint'), inverse_of: :client, dependent: :destroy
  has_many :custom_case_notes, **hmis_relation(:PersonalID, 'CustomCaseNote'), inverse_of: :client, dependent: :destroy
  has_one :primary_name, -> { where(primary: true) }, **hmis_relation(:PersonalID, 'CustomClientName'), inverse_of: :client

  # Enrollments for this Client, including WIP Enrollments
  has_many :enrollments, **hmis_relation(:PersonalID, 'Enrollment'), dependent: :destroy
  # Projects that this Client is enrolled in, NOT inluding WIP enrollments
  has_many :projects, through: :enrollments
  # WIP records representing enrollments for this Client
  has_many :wip, class_name: 'Hmis::Wip', through: :enrollments

  has_many :custom_assessments, through: :enrollments

  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :clients, optional: true
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
  has_many :services, through: :enrollments # HUD Services only
  has_many :custom_services, through: :enrollments # Custom Services only
  has_many :custom_data_elements, as: :owner, dependent: :destroy
  has_many :client_projects
  has_many :projects_including_wip, through: :client_projects, source: :project

  # History of merges into this client
  has_many :merge_histories, class_name: 'Hmis::ClientMergeHistory', primary_key: :id, foreign_key: :retained_client_id
  # History of this client being merged into other clients (only present for deleted clients)
  has_many :reverse_merge_histories, class_name: 'Hmis::ClientMergeHistory', primary_key: :id, foreign_key: :deleted_client_id
  # Merge Audits for merges into this client
  has_many :merge_audits, -> { distinct }, through: :merge_histories, source: :client_merge_audit
  # Merge Audits for merges from this client into another client
  has_many :reverse_merge_audits, -> { distinct }, through: :reverse_merge_histories, source: :client_merge_audit

  accepts_nested_attributes_for :custom_data_elements, allow_destroy: true
  accepts_nested_attributes_for :names, allow_destroy: true
  accepts_nested_attributes_for :addresses, allow_destroy: true
  accepts_nested_attributes_for :contact_points, allow_destroy: true

  # NOTE: only used for getting the client's Warehouse ID, or finding potential duplicates.
  has_one :warehouse_client_source, class_name: 'Hmis::WarehouseClient', foreign_key: :source_id, inverse_of: :source
  has_one :destination_client, through: :warehouse_client_source, source: :destination, inverse_of: :source_clients
  has_many :warehouse_client_destination, class_name: 'Hmis::WarehouseClient', foreign_key: :destination_id, inverse_of: :destination
  has_many :source_clients, through: :warehouse_client_destination, source: :source, inverse_of: :destination_client

  has_many :scan_card_codes, class_name: 'Hmis::ScanCardCode', inverse_of: :client

  has_many :alerts, class_name: '::Hmis::ClientAlert', dependent: :destroy, inverse_of: :client

  validates_with Hmis::Hud::Validators::ClientValidator, on: [:client_form, :new_client_enrollment_form]

  attr_accessor :image_blob_id
  after_create :warehouse_identify_duplicate_clients
  after_update :warehouse_match_existing_clients
  before_save :set_source_hash
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

  # Includes clients where..
  #  1. The Client has enrollment(s) at any Project where the User has this specified Permissions(s)
  #     OR,
  #  2. The Client has NO enrollments AND the User has these Permission(s) at _any_ project
  #
  # NOTE: This could include clients that are enrolled at projects that the User can't necessarily see (e.g. they lack can_view_projects at that project).
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
    text_searcher(text_search, sorted: true)
  end

  scope :older_than, ->(age, or_equal: false) do
    target_dob = Date.current - (age + 1).years
    target_dob = Date.current - age.years if or_equal == true

    where(c_t[:dob].lt(target_dob))
  end

  # Clients that have no Enrollments (WIP or otherwise)
  scope :unenrolled, -> do
    # Clients that have no projects, AND no wip enrollments
    left_outer_joins(:projects, :wip).where(p_t[:id].eq(nil).and(wip_t[:id].eq(nil)))
  end

  scope :with_open_enrollment_in_project, ->(project_ids) do
    joins(:projects_including_wip).where(p_t[:id].in(Array.wrap(project_ids)))
  end

  scope :with_open_enrollment_in_organization, ->(organization_ids) do
    tuples = Hmis::Hud::Organization.where(id: Array.wrap(organization_ids)).pluck(:data_source_id, :organization_id)
    ds_ids = tuples.map(&:first).compact.map(&:to_i).uniq
    hud_org_ids = tuples.map(&:second)
    raise 'orgs are in multiple data sources' if ds_ids.size > 1

    joins(:projects_including_wip).where(p_t[:organization_id].in(hud_org_ids).and(p_t[:data_source_id].eq(ds_ids.first)))
  end

  scope :with_service_in_range, ->(start_date:, end_date: Date.current, project_id: nil, custom_service_type_id: nil) do
    cst = Hmis::Hud::CustomServiceType.find(custom_service_type_id) if custom_service_type_id
    if cst&.hud_service?
      # For HUD service type, join directly with the hud service table (optimization)
      service_relation = :services
      service_arel = Hmis::Hud::Service.arel_table
      matches_type = s_t[:record_type].eq(cst.hud_record_type).and(s_t[:type_provided].eq(cst.hud_type_provided))
    elsif cst
      # For Custom service type, join directly with the custom service table (optimization)
      service_relation = :custom_services
      service_arel = Hmis::Hud::CustomService.arel_table
      matches_type = cs_t[:custom_service_type_id].eq(custom_service_type_id)
    else
      # Service type was not specified, so use the HmisService view which includes both HUD and Custom services
      service_relation = :hmis_services
      service_arel = Hmis::Hud::HmisService.arel_table
      matches_type = Arel::Nodes::True
    end

    # Clients with services rendered
    scope = joins(enrollments: service_relation)

    # Filter down to only clients with services rendered at the specified project, if applicable. Includes services rendered at WIP Enrollments.
    scope = scope.merge(Hmis::Hud::Enrollment.with_project(project_id)) if project_id

    # Filter down by service date range and service type
    scope.where(
      service_arel[:date_provided].gteq(start_date).
      and(service_arel[:date_provided].lteq(end_date)).
      and(matches_type),
    ).distinct
  end

  def build_primary_custom_client_name
    return unless names.empty?

    names.new(
      primary: true,
      first: first_name,
      last: last_name,
      middle: middle_name,
      suffix: name_suffix,
      user_id: user_id || Hmis::Hud::User.system_user(data_source_id: data_source_id).user_id,
      **slice(:name_data_quality, :data_source_id, :date_created, :date_updated),
    )
  end

  def enrolled?
    enrollments.any?
  end

  def self.source_for(destination_id:, user:)
    source_id = GrdaWarehouse::WarehouseClient.find_by(destination_id: destination_id, data_source_id: user.hmis_data_source_id)&.source_id
    return Hmis::Hud::Client.none unless source_id.present?

    searchable_to(user).where(id: source_id)
  end

  def ssn_serial
    self.SSN&.[](-4..-1)
  end

  def warehouse_id
    warehouse_client_source&.destination_id
  end

  SORT_OPTIONS = [
    :best_match,
    :last_name_a_to_z,
    :last_name_z_to_a,
    :first_name_a_to_z,
    :first_name_z_to_a,
    :age_youngest_to_oldest,
    :age_oldest_to_youngest,
    :recently_added,
  ].freeze

  SORT_OPTION_DESCRIPTIONS = {
    best_match: 'Most Relevant',
    last_name_a_to_z: 'Last Name: A-Z',
    last_name_z_to_a: 'Last Name: Z-A',
    first_name_a_to_z: 'First Name: A-Z',
    first_name_z_to_a: 'First Name: Z-A',
    age_youngest_to_oldest: 'Age: Youngest to Oldest',
    age_oldest_to_youngest: 'Age: Oldest to Youngest',
    recently_added: 'Recently Added',
  }.freeze

  def self.client_search(input:, user: nil, sorted: false)
    # Apply ID searches directly, as they can only ever return a single client
    return searchable_to(user).where(id: input.id) if input.id.present?
    return searchable_to(user).where(PersonalID: input.personal_id) if input.personal_id
    return source_for(destination_id: input.warehouse_id, user: user) if input.warehouse_id

    # Build search scope
    scope = Hmis::Hud::Client.where(id: searchable_to(user).select(:id))
    # early return to preserve sort order, avoids client.where(id: scope.select(:id))
    return scope.text_searcher(input.text_search, sorted: sorted) if input.text_search.present?

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
    when :best_match
      current_scope # no order, use text search rank
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

  def self.apply_filters(input)
    Hmis::Filter::ClientFilter.new(input).filter_scope(self)
  end

  # fix these so they use DATA_NOT_COLLECTED And the other standard names
  use_enum(:gender_enum_map, ::HudUtility2024.genders) do |hash|
    hash.map do |value, desc|
      {
        key: [8, 9, 99].include?(value) ? desc : ::HudUtility2024.gender_id_to_field_name[value],
        value: value,
        desc: desc,
        null: [8, 9, 99].include?(value),
      }
    end
  end

  use_enum(:race_enum_map, ::HudUtility2024.races.except('RaceNone'), include_base_null: true) do |hash|
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

  def delete_image
    client_files&.client_photos&.newest_first&.first&.destroy!
    @image = nil
  end

  # Mirrors `clientBriefName` in frontend
  def brief_name
    [first_name, last_name].compact.join(' ')
  end

  def full_name
    [first_name, middle_name, last_name, name_suffix].compact.join(' ')
  end

  # Run if we changed name/DOB/SSN
  private def warehouse_match_existing_clients
    return unless warehouse_columns_changed?
    return if Delayed::Job.queued?(['GrdaWarehouse::Tasks::IdentifyDuplicates', 'match_existing!'])

    GrdaWarehouse::Tasks::IdentifyDuplicates.new.delay(queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)).match_existing!
  end

  # Run when we add a new client to the system
  private def warehouse_identify_duplicate_clients
    return if Delayed::Job.where(failed_at: nil, locked_at: nil).jobs_for_class('GrdaWarehouse::Tasks::IdentifyDuplicates').jobs_for_class('run!').exists?

    GrdaWarehouse::Tasks::IdentifyDuplicates.new.delay(queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)).run!
  end

  private def warehouse_columns_changed?
    (saved_changes.keys & ['FirstName', 'LastName', 'DOB', 'SSN', 'DateDeleted']).any?
  end

  include RailsDrivers::Extensions

  # The warehouse uses the source hash to determine if the record has changed and to maintain the
  # associated warehouse record for reporting.
  # This gets called during a pre-commit hook
  def set_source_hash
    hmis_keys = self.class.hmis_configuration(version: '2024').keys
    hmis_data = slice(*hmis_keys)
    self.source_hash = Digest::SHA256.hexdigest(hmis_data.except(:ExportID).to_s)
  end

  # A tool to batch reset all source hashes for a particular data source
  def self.reset_source_hashes!(data_source_id)
    where(data_source_id: data_source_id).find_in_batches do |batch|
      original_hashes = batch.map(&:source_hash)
      batch.each(&:set_source_hash)
      batch.reject!.with_index { |c, i| c.source_hash == original_hashes[i] }
      puts "Updating #{batch.size} client source hashes"
      next unless batch.size.positive?

      import!(
        batch,
        validate: false,
        timestamps: false,
        on_duplicate_key_update: { conflict_target: [:id], columns: [:source_hash] },
      )
    end
  end
end
