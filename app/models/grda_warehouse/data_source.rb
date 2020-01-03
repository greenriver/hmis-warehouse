###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class GrdaWarehouse::DataSource < GrdaWarehouseBase
  require 'memoist'
  include ArelHelper
  validates :name, presence: true
  validates :short_name, presence: true

  CACHE_EXPIRY = if Rails.env.production? then 20.hours else 20.seconds end

  has_many :import_logs
  has_many :services, class_name: GrdaWarehouse::Hud::Service.name, inverse_of: :data_source
  has_many :enrollments, class_name: GrdaWarehouse::Hud::Enrollment.name, inverse_of: :data_source
  has_many :exits, class_name: GrdaWarehouse::Hud::Exit.name, inverse_of: :data_source
  has_many :clients, class_name: GrdaWarehouse::Hud::Client.name, inverse_of: :data_source
  has_many :organizations, class_name: GrdaWarehouse::Hud::Organization.name, inverse_of: :data_source
  has_many :projects, class_name: GrdaWarehouse::Hud::Project.name, inverse_of: :data_source
  has_many :exports, class_name: GrdaWarehouse::Hud::Export.name, inverse_of: :data_source
  has_many :group_viewable_entities, :class_name => 'GrdaWarehouse::GroupViewableEntity', foreign_key: :entity_id

  has_many :uploads
  has_many :non_hmis_uploads

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
    importable.where(source_type: "samba")
  end

  scope :importable_via_sftp, -> do
    importable.where(source_type: "sftp")
  end

  scope :importable_via_s3, -> do
    importable.where(source_type: "s3")
  end

  scope :viewable_by, -> (user) do
    if user.can_edit_anything_super_user?
      current_scope
    else
      qc = -> (s) { connection.quote_column_name s }
      q  = -> (s) { connection.quote s }

      where(
        [
          has_access_to_data_source_through_viewable_entities(user, q, qc),
          has_access_to_data_source_through_organizations(user, q, qc),
          has_access_to_data_source_through_projects(user, q, qc)
        ].join ' OR '
      )
    end
  end
  scope :editable_by, -> (user) do
    if user.can_edit_anything_super_user?
      current_scope
    else
      qc = -> (s) { connection.quote_column_name s }
      q  = -> (s) { connection.quote s }

      where has_access_to_data_source_through_viewable_entities(user, q, qc)
    end
  end

  scope :authoritative, -> do
    where(authoritative: true)
  end

  scope :visible_in_window_to, -> (user) do
    return none unless user

    ds_ids = user.data_sources.pluck(:id)

    if user&.can_edit_anything_super_user?
      current_scope
    elsif user&.can_view_clients_with_roi_in_own_coc?
      if user&.can_see_clients_in_window_for_assigned_data_sources? && ds_ids.present?
        sql = arel_table[:id].in(ds_ids).or(arel_table[:id].in(current_scope.select(:id)))
        if user.can_view_or_search_clients_or_window?
          sql = sql.or(arel_table[:visible_in_window].eq(true))
        end
        where(sql)
      else
        current_scope # this will get limited by client visibility
      end
    elsif user&.can_see_clients_in_window_for_assigned_data_sources? && ds_ids.present?
      # some users can see all clients for a specific data source,
      # even if the data source as a whole is not available to anyone else in the window
      sql = arel_table[:id].in(ds_ids)
      if user.can_view_or_search_clients_or_window?
        sql = sql.or(arel_table[:visible_in_window].eq(true))
      end
      where(sql)
    elsif user.can_view_or_search_clients_or_window?
      health_id = self.health_authoritative_id
      # only show record in window if the data source is visible in the window or
      # the record is a health record and the user has access to health..
      sql = arel_table[:visible_in_window].eq(true)
      if user&.has_some_patient_access?
        sql = sql.or(arel_table[:id].eq(health_id))
      end
      where(sql)
    else
      # Note this should be `none` but active record is being incorrigible
      where(Arel.sql('0=1'))
    end
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

  def self.authoritative_types
    {
      'Youth' => :youth,
      'VI-SPDAT' => :vispdat,
      'Health' => :health,
      'Coordinated Assessment' => :coordinated_assessment,
    }
  end

  private_class_method def self.has_access_to_data_source_through_viewable_entities(user, q, qc)
    data_source_table = quoted_table_name
    viewability_table = GrdaWarehouse::GroupViewableEntity.quoted_table_name
    viewability_deleted_column_name = GrdaWarehouse::GroupViewableEntity.paranoia_column
    group_ids = user.access_groups.pluck(:id)
    group_id_query = if group_ids.empty?
      "0=1"
    else
      "#{viewability_table}.#{qc.('access_group_id')} IN (#{group_ids.join(', ')})"
    end

    <<-SQL.squish

      EXISTS (
        SELECT 1 FROM
          #{viewability_table}
          WHERE
            #{viewability_table}.#{qc.('entity_id')}   = #{data_source_table}.#{qc.('id')}
            AND
            #{viewability_table}.#{qc.('entity_type')} = #{q.(sti_name)}
            AND
            #{group_id_query}
            AND
            #{viewability_table}.#{qc.(viewability_deleted_column_name)} IS NULL
      )

    SQL
  end

  private_class_method def self.has_access_to_data_source_through_organizations(user, q, qc)
    data_source_table  = quoted_table_name
    viewability_table  = GrdaWarehouse::GroupViewableEntity.quoted_table_name
    organization_table = GrdaWarehouse::Hud::Organization.quoted_table_name
    viewability_deleted_column_name = GrdaWarehouse::GroupViewableEntity.paranoia_column
    group_ids = user.access_groups.pluck(:id)
    group_id_query = if group_ids.empty?
      '0=1'
    else
      "#{viewability_table}.#{qc.('access_group_id')} IN (#{group_ids.join(', ')})"
    end

    <<-SQL.squish

      EXISTS (
        SELECT 1 FROM
          #{viewability_table}
          INNER JOIN
          #{organization_table}
          ON
            #{viewability_table}.#{qc.('entity_id')}   = #{organization_table}.#{qc.('id')}
            AND
            #{viewability_table}.#{qc.('entity_type')} = #{q.(GrdaWarehouse::Hud::Organization.sti_name)}
            AND
            #{group_id_query}
            AND
            #{viewability_table}.#{qc.(viewability_deleted_column_name)} IS NULL
          WHERE
            #{organization_table}.#{qc.('data_source_id')} = #{data_source_table}.#{qc.('id')}
            AND
            #{organization_table}.#{qc.(GrdaWarehouse::Hud::Organization.paranoia_column)} IS NULL
      )

    SQL
  end

  private_class_method def self.has_access_to_data_source_through_projects(user, q, qc)
    data_source_table = quoted_table_name
    viewability_table = GrdaWarehouse::GroupViewableEntity.quoted_table_name
    project_table     = GrdaWarehouse::Hud::Project.quoted_table_name
    viewability_deleted_column_name = GrdaWarehouse::GroupViewableEntity.paranoia_column
    group_ids = user.access_groups.pluck(:id)
    group_id_query = if group_ids.empty?
      "0=1"
    else
      "#{viewability_table}.#{qc.('access_group_id')} IN (#{group_ids.join(', ')})"
    end


    <<-SQL.squish

      EXISTS (
        SELECT 1 FROM
          #{viewability_table}
          INNER JOIN
          #{project_table}
          ON
            #{viewability_table}.#{qc.('entity_id')}   = #{project_table}.#{qc.('id')}
            AND
            #{viewability_table}.#{qc.('entity_type')} = #{q.(GrdaWarehouse::Hud::Project.sti_name)}
            AND
            #{group_id_query}
            AND
            #{viewability_table}.#{qc.(viewability_deleted_column_name)} IS NULL
          WHERE
            #{project_table}.#{qc.('data_source_id')} = #{data_source_table}.#{qc.('id')}
            AND
            #{project_table}.#{qc.(GrdaWarehouse::Hud::Project.paranoia_column)} IS NULL
      )

    SQL
  end

  accepts_nested_attributes_for :projects

  def self.names
    importable.select(:id, :short_name).distinct.pluck(:short_name, :id)
  end

  def self.short_name id
    @short_names ||= importable.select(:id, :short_name).distinct.pluck(:id, :short_name).to_h
    @short_names[id]
  end

  def self.text_search(text)
    return none unless text.present?

    query = "%#{text}%"
    where(
      arel_table[:name].matches(query)
    )
  end

  def self.data_spans_by_id
    Rails.cache.fetch('data_source_date_spans_by_id', expires_in: CACHE_EXPIRY) do
      spans_by_id = GrdaWarehouse::DataSource.pluck(:id).map do |id| [id, {}] end.to_h

      GrdaWarehouse::Hud::Enrollment.group(:data_source_id).
        pluck(:data_source_id, nf('MIN', [e_t[:EntryDate]]).to_sql).each do |ds, date|
          spans_by_id[ds][:start_date] = date
        end

      GrdaWarehouse::Hud::Service.group(:data_source_id).
        pluck(:data_source_id, nf('MAX', [s_t[:DateProvided]]).to_sql).each do |ds, date|
          spans_by_id[ds][:end_date] = date
        end

      GrdaWarehouse::Hud::Exit.group(:data_source_id).
        pluck(:data_source_id, nf('MAX', [ex_t[:ExitDate]]).to_sql).each do |ds, date|
          if spans_by_id[ds].try(:[],:end_date).blank? || date > spans_by_id[ds][:end_date]
            spans_by_id[ds][:end_date] = date
          end
        end
      spans_by_id.each do |ds, dates|
        if dates[:start_date].present? && dates[:end_date].blank?
          spans_by_id[ds][:end_date] = Date.current
        end
      end
      spans_by_id
    end
  end

  def users
    User.where(id: AccessGroup.contains(self).map(&:users).flatten.map(&:id))
  end

  def data_span
    return unless enrollments.any?
    if self.id.present?
      self.class.data_spans_by_id[self.id]
    end
  end

  # are there any uploads for this data_source
  # with the same file name on previous days
  # where the upload was uploaded by the system user?
  # return the first date we saw this filename or nil
  def stalled_since? date
    return nil unless date.present?
    day_before = date - 1.days
    two_months_ago = date - 2.months
    user = User.setup_system_user
    stalled = GrdaWarehouse::Upload.where(
      data_source_id: id,
      user_id: user.id,
      file: GrdaWarehouse::Upload.where(data_source_id: id, user_id: user.id).
        order(id: :desc).
        select(:file).
        limit(1),
      completed_at: [two_months_ago .. day_before]
      ).exists?
    if stalled
      GrdaWarehouse::Upload.where(
          data_source_id: id,
          user_id: user.id,
          file: GrdaWarehouse::Upload.where(data_source_id: id, user_id: user.id).
            order(id: :desc).
            select(:file).
            limit(1)
        ).minimum(:completed_at).to_date
    end
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

  def manual_import_path
    "/tmp/uploaded#{file_path}"
  end

  def has_data?
    exports.any?
  end

  def organization_names
    organizations.order(OrganizationName: :asc).pluck(:OrganizationName)
  end

  def project_names
    projects.order(ProjectName: :asc).pluck(:ProjectName)
  end

  class << self
    extend Memoist
    def health_authoritative_id
      authoritative.where(short_name: 'Health')&.first&.id
    end
    memoize :health_authoritative_id
  end
end
