###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::DataSource < GrdaWarehouseBase
  include RailsDrivers::Extensions
  include EntityAccess
  include ArelHelper

  self.primary_key = :id
  require 'memery'

  acts_as_paranoid
  validates :name, presence: true
  validates :short_name, presence: true

  after_create :maintain_system_group
  after_create :clear_ds_id_cache

  CACHE_EXPIRY = if Rails.env.production? then 20.hours else 20.seconds end

  has_many :import_logs, class_name: 'GrdaWarehouse::ImportLog'
  has_many :services, class_name: 'GrdaWarehouse::Hud::Service', inverse_of: :data_source
  has_many :enrollments, class_name: 'GrdaWarehouse::Hud::Enrollment', inverse_of: :data_source
  has_many :exits, class_name: 'GrdaWarehouse::Hud::Exit', inverse_of: :data_source
  has_many :clients, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :data_source
  has_many :organizations, class_name: 'GrdaWarehouse::Hud::Organization', inverse_of: :data_source
  has_many :projects, class_name: 'GrdaWarehouse::Hud::Project', inverse_of: :data_source
  accepts_nested_attributes_for :projects
  has_many :exports, class_name: 'GrdaWarehouse::Hud::Export', inverse_of: :data_source
  has_many :group_viewable_entities, -> { where(entity_type: 'GrdaWarehouse::DataSource') }, class_name: 'GrdaWarehouse::GroupViewableEntity', foreign_key: :entity_id
  has_many :uploads
  has_many :non_hmis_uploads

  has_one :hmis_import_config

  accepts_nested_attributes_for :organizations
  accepts_nested_attributes_for :projects

  scope :importable, -> do
    # Authoritative data sources are not importable. There is a temporary exception for HMIS data sources,
    # since they need to continue to accept imports during the migration phase. (PT #185835773)
    source.where(arel_table[:authoritative].eq(false).or(arel_table[:hmis].not_eq(nil)))
  end

  scope :source, -> do
    where(arel_table[:source_type].not_eq(nil).or(arel_table[:authoritative].eq(true)))
  end

  scope :destination, -> do
    where(source_type: nil, authoritative: false)
  end

  scope :importable_via_samba, -> do
    importable.where(source_type: 'samba')
  end

  scope :importable_via_sftp, -> do
    importable.where(source_type: 'sftp')
  end

  scope :importable_via_s3, -> do
    importable.where(source_type: 's3')
  end

  scope :obeys_consent, -> do
    where(obey_consent: true)
  end

  scope :viewable_by, ->(user, permission: :can_view_projects) do
    # TODO: START_ACL cleanup after migration to ACLs
    if user.using_acls?
      return none unless user&.send("#{permission}?")

      ids = data_source_ids_viewable_by(user, permission: permission)
      # If have a set (not a nil) and it's empty, this user can't access any projects
      return none if ids.is_a?(Set) && ids.empty?

      where(id: ids)
    else
      qc = ->(s) { connection.quote_column_name s }
      q  = ->(s) { connection.quote s }

      where(
        [
          has_access_to_data_source_through_viewable_entities(user, q, qc),
          has_access_to_data_source_through_organizations(user, q, qc),
          has_access_to_data_source_through_projects(user, q, qc),
        ].join(' OR '),
      )
    end
    # END_ACL
  end

  scope :editable_by, ->(user) do
    # TODO: START_ACL cleanup after migration to ACLs
    return none if user.using_acls? && ! user&.can_edit_data_sources?

    if user.using_acls?
      ids = data_source_ids_from_viewable_entities(user, :can_edit_data_sources)
      # If have a set (not a nil) and it's empty, this user can't access any projects
      return none if ids.is_a?(Set) && ids.empty?

      where(id: ids)
    else
      directly_viewable_by(user)
    end
    # END_ACL
  end

  scope :directly_viewable_by, ->(user, permission: :can_view_projects) do
    # TODO: START_ACL cleanup after migration to ACLs
    return none if user.using_acls? && ! user&.send("#{permission}?")

    if user.using_acls?
      ids = data_source_ids_from_viewable_entities(user, permission)
      # If we have a set (not a nil) and it's empty, this user can't access any projects
      return none if ids.is_a?(Set) && ids.empty?

      where(id: ids)
    else
      qc = ->(s) { connection.quote_column_name s }
      q  = ->(s) { connection.quote s }

      where has_access_to_data_source_through_viewable_entities(user, q, qc)
    end
    # END_ACL
  end

  scope :authoritative, -> do
    where(authoritative: true)
  end

  scope :hmis, ->(user = nil) do
    scope = where.not(hmis: nil)
    scope = scope.where(id: user.hmis_data_source_id) if user.present?
    scope
  end

  scope :not_hmis, -> { where(hmis: nil) }

  scope :scannable, -> do
    where(service_scannable: true)
  end

  scope :visible_in_window, -> do
    where(visible_in_window: true)
  end

  scope :available_for_new_clients, -> do
    authoritative.not_hmis
  end

  # TODO: START_ACL remove after migration to ACLs
  scope :visible_in_window_for_cohorts_to, ->(user) do
    return none unless user&.can_view_clients?

    ds_ids = user.data_sources.pluck(:id)
    scope = where('0=1')
    scope = scope.or(where(visible_in_window: true))
    scope = scope.or(where(id: ds_ids)) if ds_ids.any?
    scope
  end
  # END_ACL

  scope :youth, -> do
    where(authoritative_type: 'youth')
  end

  scope :health, -> do
    where(authoritative_type: 'health')
  end

  scope :vispdat, -> do
    where(authoritative_type: 'vispdat')
  end

  scope :coordinated_assessment, -> do
    where(authoritative_type: 'coordinated_assessment')
  end

  def self.data_source_ids_viewable_by(user, permission: :can_view_projects)
    return Set.new unless user&.send("#{permission}?")

    ids = Set.new
    ids += data_source_ids_from_viewable_entities(user, permission)
    ids += data_source_ids_from_organizations(user, permission)
    ids += data_source_ids_from_projects(user, permission)
    ids
  end

  def self.data_source_ids_from_viewable_entities(user, permission)
    return [] unless user.present?
    return [] unless user.send("#{permission}?")

    group_ids = user.collections_for_permission(permission)
    return [] if group_ids.empty?

    GrdaWarehouse::GroupViewableEntity.where(
      collection_id: group_ids,
      entity_type: 'GrdaWarehouse::DataSource',
    ).pluck(:entity_id)
  end

  def self.data_source_ids_from_entity_type(user, permission, entity_class)
    return [] unless user.present?
    return [] unless user.send("#{permission}?")

    group_ids = user.collections_for_permission(permission)
    return [] if group_ids.empty?

    entity_class.where(
      id: GrdaWarehouse::GroupViewableEntity.where(
        collection_id: group_ids,
        entity_type: entity_class.sti_name,
      ).select(:entity_id),
    ).joins(:data_source).pluck(ds_t[:id])
  end

  def self.data_source_ids_from_projects(user, permission)
    data_source_ids_from_entity_type(user, permission, GrdaWarehouse::Hud::Project)
  end

  def self.data_source_ids_from_organizations(user, permission)
    data_source_ids_from_entity_type(user, permission, GrdaWarehouse::Hud::Organization)
  end

  def self.source_data_source_ids
    Rails.cache.fetch(__method__, expires_in: 1.hours) do
      GrdaWarehouse::DataSource.source.pluck(:id)
    end
  end

  def self.destination_data_source_ids
    Rails.cache.fetch(__method__, expires_in: 1.hours) do
      GrdaWarehouse::DataSource.destination.pluck(:id)
    end
  end

  def self.authoritative_data_source_ids
    Rails.cache.fetch(__method__, expires_in: 1.hours) do
      GrdaWarehouse::DataSource.authoritative.pluck(:id)
    end
  end

  def self.window_data_source_ids
    Rails.cache.fetch(__method__, expires_in: 1.hours) do
      GrdaWarehouse::DataSource.visible_in_window.pluck(:id)
    end
  end

  def self.can_see_all_data_sources?(user)
    visible_source_ds = viewable_by(user).source.distinct
    # If we can't see any, it may be because there are none
    # Ensure we can see at least one
    return false unless visible_source_ds.count.positive?

    visible_source_ds.count == source.count
  end

  def self.view_column_names
    [
      'id',
      'name',
      'short_name',
    ]
  end

  def self.authoritative_types
    {
      'Youth' => :youth,
      'VI-SPDAT' => :vispdat,
      'Health' => :health,
      'Coordinated Entry' => :coordinated_assessment,
      'Other' => :other,
      'Synthetic' => :synthetic,
    }
  end

  # TODO: START_ACL remove after migration to ACLs
  def self.has_access_to_data_source_through_viewable_entities(user, q, qc) # rubocop:disable Naming/PredicateName,Naming/MethodParameterName
    data_source_table = quoted_table_name
    viewability_table = GrdaWarehouse::GroupViewableEntity.quoted_table_name
    viewability_deleted_column_name = GrdaWarehouse::GroupViewableEntity.paranoia_column
    group_ids = user.access_groups.pluck(:id)
    group_id_query = if group_ids.empty?
      '0=1'
    else
      "#{viewability_table}.#{qc.call('access_group_id')} IN (#{group_ids.join(', ')})"
    end

    <<-SQL.squish

      EXISTS (
        SELECT 1 FROM
          #{viewability_table}
          WHERE
            #{viewability_table}.#{qc.call('entity_id')}   = #{data_source_table}.#{qc.call('id')}
            AND
            #{viewability_table}.#{qc.call('entity_type')} = #{q.call(sti_name)}
            AND
            #{group_id_query}
            AND
            #{viewability_table}.#{qc.call(viewability_deleted_column_name)} IS NULL
            AND
            #{data_source_table}.#{qc.call(GrdaWarehouse::DataSource.paranoia_column)} IS NULL
      )

    SQL
  end

  def self.has_access_to_data_source_through_organizations(user, q, qc) # rubocop:disable Naming/PredicateName,Naming/MethodParameterName
    data_source_table  = quoted_table_name
    viewability_table  = GrdaWarehouse::GroupViewableEntity.quoted_table_name
    organization_table = GrdaWarehouse::Hud::Organization.quoted_table_name
    viewability_deleted_column_name = GrdaWarehouse::GroupViewableEntity.paranoia_column
    group_ids = user.access_groups.pluck(:id)
    group_id_query = if group_ids.empty?
      '0=1'
    else
      "#{viewability_table}.#{qc.call('access_group_id')} IN (#{group_ids.join(', ')})"
    end

    <<-SQL.squish

      EXISTS (
        SELECT 1 FROM
          #{viewability_table}
          INNER JOIN
          #{organization_table}
          ON
            #{viewability_table}.#{qc.call('entity_id')}   = #{organization_table}.#{qc.call('id')}
            AND
            #{viewability_table}.#{qc.call('entity_type')} = #{q.call(GrdaWarehouse::Hud::Organization.sti_name)}
            AND
            #{group_id_query}
            AND
            #{viewability_table}.#{qc.call(viewability_deleted_column_name)} IS NULL
          WHERE
            #{organization_table}.#{qc.call('data_source_id')} = #{data_source_table}.#{qc.call('id')}
            AND
            #{organization_table}.#{qc.call(GrdaWarehouse::Hud::Organization.paranoia_column)} IS NULL
      )

    SQL
  end

  def self.has_access_to_data_source_through_projects(user, q, qc) # rubocop:disable Naming/PredicateName,Naming/MethodParameterName
    data_source_table = quoted_table_name
    viewability_table = GrdaWarehouse::GroupViewableEntity.quoted_table_name
    project_table     = GrdaWarehouse::Hud::Project.quoted_table_name
    viewability_deleted_column_name = GrdaWarehouse::GroupViewableEntity.paranoia_column
    group_ids = user.access_groups.pluck(:id)
    group_id_query = if group_ids.empty?
      '0=1'
    else
      "#{viewability_table}.#{qc.call('access_group_id')} IN (#{group_ids.join(', ')})"
    end

    <<-SQL.squish

      EXISTS (
        SELECT 1 FROM
          #{viewability_table}
          INNER JOIN
          #{project_table}
          ON
            #{viewability_table}.#{qc.call('entity_id')}   = #{project_table}.#{qc.call('id')}
            AND
            #{viewability_table}.#{qc.call('entity_type')} = #{q.call(GrdaWarehouse::Hud::Project.sti_name)}
            AND
            #{group_id_query}
            AND
            #{viewability_table}.#{qc.call(viewability_deleted_column_name)} IS NULL
          WHERE
            #{project_table}.#{qc.call('data_source_id')} = #{data_source_table}.#{qc.call('id')}
            AND
            #{project_table}.#{qc.call(GrdaWarehouse::Hud::Project.paranoia_column)} IS NULL
      )

    SQL
  end
  # END_ACL

  def self.names
    importable.select(:id, :short_name).distinct.pluck(:short_name, :id)
  end

  def self.short_name(id)
    @short_names ||= importable.select(:id, :short_name).distinct.pluck(:id, :short_name).to_h
    @short_names[id]
  end

  def self.text_search(text)
    return none unless text.present?

    query = "%#{text}%"
    where(arel_table[:name].matches(query))
  end

  def self.data_spans_by_id
    Rails.cache.fetch('data_source_date_spans_by_id', expires_in: CACHE_EXPIRY) do
      spans_by_id = GrdaWarehouse::DataSource.pluck(:id).map { |id| [id, {}] }.to_h

      GrdaWarehouse::Hud::Enrollment.joins(:data_source).group(:data_source_id).
        pluck(:data_source_id, nf('MIN', [e_t[:EntryDate]])).each do |ds, date|
          next unless spans_by_id[ds]

          spans_by_id[ds][:start_date] = date
        end

      GrdaWarehouse::Hud::Service.joins(:data_source).group(:data_source_id).
        pluck(:data_source_id, nf('MAX', [s_t[:DateProvided]])).each do |ds, date|
          next unless spans_by_id[ds]

          spans_by_id[ds][:end_date] = date
        end

      GrdaWarehouse::Hud::Exit.joins(:data_source).group(:data_source_id).
        pluck(:data_source_id, nf('MAX', [ex_t[:ExitDate]])).each do |ds, date|
          next unless spans_by_id[ds]

          spans_by_id[ds][:end_date] = date if spans_by_id[ds].try(:[], :end_date).blank? || date > spans_by_id[ds][:end_date]
        end
      spans_by_id.each do |ds, dates|
        next unless spans_by_id[ds]

        spans_by_id[ds][:end_date] = Date.current if dates[:start_date].present? && dates[:end_date].blank?
      end
      spans_by_id
    end
  end

  def directly_viewable_by?(user, permission: :can_view_projects)
    # TODO: START_ACL cleanup after migration to ACLs
    if user.using_acls?
      self.class.directly_viewable_by(user, permission: permission).where(id: id).exists?
    else
      self.class.directly_viewable_by(user).where(id: id).exists?
    end
    # END_ACL
  end

  def users
    User.where(id: AccessGroup.contains(self).map(&:users).flatten.map(&:id))
  end

  def data_span
    return unless enrollments.any?
    return unless id.present?

    self.class.data_spans_by_id[id]
  end

  def unprocessed_enrollment_count
    @unprocessed_enrollment_count ||= enrollments.unprocessed.joins(:project, :destination_client).count
  end

  # Have we received the expected number of files at least once over the past 48 hours?
  # there is an assumption that within
  # return the date of the most-recent fully successful import
  def stalled_since?(date)
    return nil unless date.present?
    return nil if import_paused
    return nil unless hmis_import_config&.active

    # hmis_import_config.file_count is the expected number of uploads for a given day
    # fetch the expected number, and confirm they all arrived within a 24 hour window
    most_recent_uploads = uploads.completed.
      # limit look back to 6 months to improve performance
      where(user_id: User.system_user.id, completed_at: 6.months.ago.to_date..Date.current).
      order(created_at: :desc).
      select(:id, :data_source_id, :user_id, :completed_at).
      first(hmis_import_config.file_count)
    return nil unless most_recent_uploads

    most_recent_upload = most_recent_uploads.first
    previously_completed_upload = most_recent_uploads.last
    # Check that the expected number of files arrived within a 24 hour window, otherwise we might be looking
    # at two partial runs
    # If we only expect one file, then first and last will be the same and time_diff will be 0.0
    return nil if most_recent_upload.blank? || previously_completed_upload.blank?

    time_diff = most_recent_upload.completed_at - previously_completed_upload.completed_at
    return most_recent_upload.completed_at unless time_diff < 24.hours.to_i
    return nil if most_recent_upload.completed_at > 48.hours.ago

    most_recent_upload.completed_at.to_date
  end

  def self.stalled_imports?(user)
    Rails.cache.fetch(['data_source_stalled_imports', user], expires_in: 1.hours) do
      stalled = false
      viewable_by(user).each do |data_source|
        next if stalled

        most_recently_completed = data_source.import_logs.maximum(:completed_at)
        if most_recently_completed.present?
          stalled = true if data_source.stalled_since?(most_recently_completed)
        end
      end

      stalled
    end
  end

  def self.options_for_select(user:)
    # don't cache this, it's a class method
    viewable_by(user).
      distinct.
      order(name: :asc).
      pluck(:name, :short_name, :id).
      map do |name, short_name, id|
        [
          "#{name} (#{short_name})",
          id,
        ]
      end
  end

  def manual_import_path
    "/tmp/uploaded#{file_path}"
  end

  def has_data? # rubocop:disable Naming/PredicateName
    exports.any?
  end

  def organization_names
    organizations.order(OrganizationName: :asc).pluck(:OrganizationName)
  end

  def project_names
    projects.joins(:organization).order(ProjectName: :asc).pluck(:ProjectName)
  end

  def destroy_dependents!
    organizations.map(&:destroy_dependents!)
    organizations.update_all(DateDeleted: Time.current, source_hash: nil)
  end

  def client_count
    clients.count
  end

  def project_count
    projects.joins(:organization).count
  end

  def hmis?
    hmis.present?
  end

  def hmis_url_for(entity, user: nil)
    return unless hmis? && HmisEnforcement.hmis_enabled?
    return unless entity&.data_source_id == id

    base = "https://#{hmis}"
    url = case entity
    when GrdaWarehouse::Hud::Project
      "#{base}/projects/#{entity.id}"
    when GrdaWarehouse::Hud::Organization
      "#{base}/organizations/#{entity.id}"
    when GrdaWarehouse::Hud::Client
      "#{base}/client/#{entity.id}"
    when GrdaWarehouse::Hud::Enrollment
      "#{base}/client/#{entity.client&.id}/enrollments/#{entity.id}"
    when Hmis::Hud::CustomAssessment
      "#{base}/client/#{entity.enrollment&.client&.id}/enrollments/#{entity.enrollment&.id}/assessments/#{entity.id}"
    when Hmis::Hud::CustomService
      "#{base}/client/#{entity.enrollment&.client&.id}/enrollments/#{entity.enrollment&.id}/services"
    end

    # For any other Enrollment-related record, link to the enrollment page
    url ||= "#{base}/client/#{entity.client&.id}/enrollments/#{entity.enrollment&.id}" if entity.respond_to?(:enrollment) && entity.respond_to?(:client)

    # If we don't have the HMIS driver we probably aren't here, but we need to check for the next section
    # If we don't have a user, just return the URl (backwards compatibility)
    return url if user.blank?

    # If we have a user, check for access (on the HMIS side)
    hmis_entity = if entity.respond_to?(:as_hmis)
      entity.as_hmis
    else
      entity
    end
    hmis_user = user.related_hmis_user(self)

    known_permissions = {
      'Hmis::Hud::Project' => [:can_view_project],
      # 'Hmis::Hud::Organization' => [:can_view_organization],
      'Hmis::Hud::Client' => [:can_view_clients],
      'Hmis::Hud::Enrollment' => [:can_view_projects, :can_view_enrollment_details],
      'Hmis::Hud::CustomAssessment' => [:can_view_projects, :can_view_enrollment_details],
    }

    perms = known_permissions[hmis_entity.class.name]
    # If we can't determine if we can see this in HMIS, just go ahead and show the link,
    # HMIS will handle access
    return url if perms.blank?
    # If we can see this in HMIS, don't bother linking to it
    return nil unless hmis_user.permissions_for?(hmis_entity, *perms, mode: :all)

    url
  end

  private def maintain_system_group
    if Rails.env.test?
      AccessGroup.maintain_system_groups(group: :data_sources)
      Collection.maintain_system_groups(group: :data_sources)
    else
      AccessGroup.delayed_system_group_maintenance(group: :data_sources)
      Collection.delayed_system_group_maintenance(group: :data_sources)
    end
  end

  private def clear_ds_id_cache
    [
      :source_data_source_ids,
      :destination_data_source_ids,
      :authoritative_data_source_ids,
      :window_data_source_ids,
    ].each { |key| Rails.cache.delete(key) }
  end

  private def editable_role_name
    'System Role - Can Edit Data Sources'
  end

  private def editable_permission
    :can_edit_data_sources
  end

  private def editable_permissions
    [
      editable_permission,
    ]
  end

  def entity_relation_type
    :data_sources
  end

  class << self
    include Memery
    def health_authoritative_id
      authoritative.where(short_name: 'Health')&.first&.id
    end
    memoize :health_authoritative_id

    def warehouse_id
      destination.first.id
    end
    memoize :warehouse_id
  end

  include RailsDrivers::Extensions
end
