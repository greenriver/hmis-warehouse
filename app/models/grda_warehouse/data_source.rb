###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
    source.where(authoritative: false)
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
    return none unless user&.send("#{permission}?")

    ids = data_source_ids_viewable_by(user, permission: permission)
    # If have a set (not a nil) and it's empty, this user can't access any projects
    return none if ids.is_a?(Set) && ids.empty?

    where(id: ids)
  end

  scope :editable_by, ->(user) do
    return none unless user.can_edit_data_sources?

    ids = data_source_ids_from_viewable_entities(user, :can_edit_data_sources)
    # If have a set (not a nil) and it's empty, this user can't access any projects
    return none if ids.is_a?(Set) && ids.empty?

    where(id: ids)
  end

  scope :directly_viewable_by, ->(user, permission: :can_view_projects) do
    return none unless user.send("#{permission}?")

    ids = data_source_ids_from_viewable_entities(user, permission)
    # If have a set (not a nil) and it's empty, this user can't access any projects
    return none if ids.is_a?(Set) && ids.empty?

    where(id: ids)
  end

  scope :authoritative, -> do
    where(authoritative: true)
  end

  scope :hmis, ->(user = nil) do
    scope = where.not(hmis: nil)
    scope = scope.where(id: user.hmis_data_source_id) if user.present?
    scope
  end

  scope :scannable, -> do
    where(service_scannable: true)
  end

  scope :visible_in_window, -> do
    where(visible_in_window: true)
  end

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

    group_ids = user.entity_groups_for_permission(permission)
    return [] if group_ids.empty?

    GrdaWarehouse::GroupViewableEntity.where(
      access_group_id: group_ids,
      entity_type: 'GrdaWarehouse::DataSource',
    ).pluck(:entity_id)
  end

  def self.data_source_ids_from_entity_type(user, permission, entity_class)
    return [] unless user.present?
    return [] unless user.send("#{permission}?")

    group_ids = user.entity_groups_for_permission(permission)
    return [] if group_ids.empty?

    entity_class.where(
      id: GrdaWarehouse::GroupViewableEntity.where(
        access_group_id: group_ids,
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
    self.class.directly_viewable_by(user, permission: permission).where(id: id).exists?
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

  private def maintain_system_group
    if Rails.env.test?
      AccessGroup.maintain_system_groups(group: :data_sources)
    else
      AccessGroup.delayed_system_group_maintenance(group: :data_sources)
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
end
