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
  has_many :user_viewable_entities, as: :entity, class_name: 'GrdaWarehouse::UserViewableEntity'

  has_many :uploads

  accepts_nested_attributes_for :organizations
  accepts_nested_attributes_for :projects

  scope :importable, -> do
    source.where(authoritative: false)
  end

  scope :source, -> do
    where.not(source_type: nil)
  end

  scope :destination, -> do
    where(source_type: nil)
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
    if user&.can_see_clients_in_window_for_assigned_data_sources?
      ds_ids = user.data_sources.pluck(:id)
      where(arel_table[:id].in(ds_ids).or(arel_table[:visible_in_window].eq(true)))
    else
      where(visible_in_window: true)
    end
  end

  private_class_method def self.has_access_to_data_source_through_viewable_entities(user, q, qc)
    data_source_table = quoted_table_name
    viewability_table = GrdaWarehouse::UserViewableEntity.quoted_table_name

    <<-SQL.squish

      EXISTS (
        SELECT 1 FROM
          #{viewability_table}
          WHERE
            #{viewability_table}.#{qc.('entity_id')}   = #{data_source_table}.#{qc.('id')}
            AND
            #{viewability_table}.#{qc.('entity_type')} = #{q.(sti_name)}
            AND
            #{viewability_table}.#{qc.('user_id')}     = #{user.id}
      )

    SQL
  end

  private_class_method def self.has_access_to_data_source_through_organizations(user, q, qc)
    data_source_table  = quoted_table_name
    viewability_table  = GrdaWarehouse::UserViewableEntity.quoted_table_name
    organization_table = GrdaWarehouse::Hud::Organization.quoted_table_name

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
            #{viewability_table}.#{qc.('user_id')}     = #{user.id}
          WHERE
            #{organization_table}.#{qc.('data_source_id')} = #{data_source_table}.#{qc.('id')}
            AND
            #{organization_table}.#{qc.(GrdaWarehouse::Hud::Organization.paranoia_column)} IS NULL
      )

    SQL
  end

  private_class_method def self.has_access_to_data_source_through_projects(user, q, qc)
    data_source_table = quoted_table_name
    viewability_table = GrdaWarehouse::UserViewableEntity.quoted_table_name
    project_table     = GrdaWarehouse::Hud::Project.quoted_table_name

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
            #{viewability_table}.#{qc.('user_id')}     = #{user.id}
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
          spans_by_id[ds][:end_date] = Date.today
        end
      end
      spans_by_id
    end
  end

  def users
    User.where(id: user_viewable_entities.uniq.map(&:user_id))
  end

  def data_span
    return unless enrollments.any?
    if self.id.present?
      self.class.data_spans_by_id[self.id]
    end
  end

  def manual_import_path
    "/tmp/uploaded#{file_path}"
  end

  def has_data?
    exports.any?
  end

  class << self
    extend Memoist
    def health_authoritative_id
      authoritative.where(short_name: 'Health')&.first&.id
    end
    memoize :health_authoritative_id
  end
end
