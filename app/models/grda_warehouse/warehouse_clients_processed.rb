class GrdaWarehouse::WarehouseClientsProcessed < GrdaWarehouseBase
  include RandomScope
  include ArelHelper

  self.table_name = :warehouse_clients_processed

  belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
  belongs_to :warehouse_client, class_name: GrdaWarehouse::WarehouseClient.name, foreign_key: :client_id, primary_key: :destination_id
  has_many :service_history_enrollments, class_name: GrdaWarehouse::ServiceHistoryEnrollment.name, primary_key: :client_id, foreign_key: :client_id

  scope :service_history, -> {where(routine: 'service_history')}
  # scope :chronic?, -> {where chronically_homeless: true}

  # def chronic?
  #   chronically_homeless
  # end

  def self.update_cached_counts client_ids: []
    client_ids.each do |client_id|
      processed = self.class.where(client_id: client_id, routine: :service_history).
        first_or_initialize
      homeless_in_last_three = all_homeless_in_last_three_years(client_ids: client_ids).try(:[], client_id) || 0
      literally_homeless_in_last_three = all_literally_homeless_last_three_years(client_ids: client_ids).try(:[], client_id) || 0
      homeless_ever = homeless_counts(client_ids: client_ids).try(:[], client_id) || 0
      attrs = {
        last_service_updated_at: Date.today,
        first_homeless_date: first_homeless_dates(client_ids: client_ids).try(:[], client_id),
        last_homeless_date: most_recent_homeless_dates(client_ids: client_ids).try(:[], client_id),
        homeless_days: homeless_ever,
        first_chronic_date: first_chronic_dates(client_ids: client_ids).try(:[], client_id),
        last_chronic_date: most_recent_chronic_dates(client_ids: client_ids).try(:[], client_id),
        chronic_days: chronic_counts(client_ids: client_ids).try(:[], client_id),
        first_date_served: first_total_dates(client_ids: client_ids).try(:[], client_id),
        last_date_served: most_recent_total_dates(client_ids: client_ids).try(:[], client_id),
        days_served: total_counts(client_ids: client_ids).try(:[], client_id),
        days_homeless_last_three_years: homeless_in_last_three,
        literally_homeless_last_three_years: literally_homeless_in_last_three,
      }

      processed.update_attributes(attrs)
      processed.save
      GrdaWarehouse::Hud::Client.destination.clear_view_cache(client_id)
    end
  end

  def most_recent_homeless_dates client_ids: []
    @most_recent_homeless_dates ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.homeless.
      where(client_id: client_ids).
      group(:client_id).
      maximum(:date)
  end
  def first_homeless_dates client_ids: []
    @first_homeless_dates ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.homeless.
      where(client_id: client_ids).
      group(:client_id).
      minimum(:date)
  end
  def homeless_counts client_ids: []
    @homeless_counts ||= begin
      shsm_table_name = GrdaWarehouse::ServiceHistoryServiceMaterialized.table_name
      shsm = Arel::Table.new(shsm_table_name.to_sym)
      shsm_a = shsm.alias('a')
      shsm_b = shsm.alias('b')
      shsm_c = shsm.alias('c')

      non_homeless_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
        where(shsm_a[:project_type].in(r_non_homeless)).
        where(shsm_a[:client_id].in(client_ids)).
        where(shsm_a[:date].eq(shsm_b[:date])).
        where(shsm_a[:client_id].eq(shsm_b[:client_id])).
        select(shsm_a[:client_id], shsm_a[:date]).
        exists.not.
        to_sql.
        sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as a")

      homeless_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
        where(shsm_b[:project_type].in(GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES)).
        where(shsm_b[:client_id].in(client_ids)).
        where(non_homeless_sql).
        select(shsm_b[:client_id], shsm_b[:date]).
        to_sql.
        sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as b")

      GrdaWarehouse::ServiceHistoryServiceMaterialized.
        from("(#{homeless_sql}) as c").
        distinct.
        group(shsm_c[:client_id]).
        count('c.date')
    end

  end

  # days in ES, SO, SH, or TH that don't overlap with PH
  def all_literally_homeless_last_three_years client_ids: []
    @all_literally_homeless_last_three_years ||= begin
      shsm_table_name = GrdaWarehouse::ServiceHistoryServiceMaterialized.table_name
      shsm = Arel::Table.new(shsm_table_name.to_sym)
      shsm_a = shsm.alias('a')
      shsm_b = shsm.alias('b')
      shsm_c = shsm.alias('c')

      non_homeless_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
        where(shsm_a[:project_type].in(r_non_homeless(chronic: true))).
        where(shsm_a[:date].between(3.years.ago.to_date..Date.today)).
        where(shsm_a[:client_id].in(client_ids)).
        where(shsm_a[:date].eq(shsm_b[:date])).
        where(shsm_a[:client_id].eq(shsm_b[:client_id])).
        select(shsm_a[:client_id], shsm_a[:date]).
        exists.not.
        to_sql.
        sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as a")

      homeless_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
        where(shsm_b[:project_type].in(GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES)).
        where(shsm_b[:date].between(3.years.ago.to_date..Date.today)).
        where(shsm_b[:client_id].in(client_ids)).
        where(non_homeless_sql).
        select(shsm_b[:client_id], shsm_b[:date]).
        to_sql.
        sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as b")

      GrdaWarehouse::ServiceHistoryServiceMaterialized.
        from("(#{homeless_sql}) as c").
        distinct.
        group(shsm_c[:client_id]).
        count('c.date')
    end
  end

  # days in ES, SO, or SH that don't overlap with TH or PH
  def all_homeless_in_last_three_years client_ids: []
    @all_homeless_in_last_three_years ||= begin
      shsm_table_name = GrdaWarehouse::ServiceHistoryServiceMaterialized.table_name
      shsm = Arel::Table.new(shsm_table_name.to_sym)
      shsm_a = shsm.alias('a')
      shsm_b = shsm.alias('b')
      shsm_c = shsm.alias('c')

      non_homeless_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
        where(shsm_a[:project_type].in(r_non_homeless)).
        where(shsm_a[:date].between(3.years.ago.to_date..Date.today)).
        where(shsm_a[:client_id].in(client_ids)).
        where(shsm_a[:date].eq(shsm_b[:date])).
        where(shsm_a[:client_id].eq(shsm_b[:client_id])).
        select(shsm_a[:client_id], shsm_a[:date]).
        exists.not.
        to_sql.
        sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as a")

      homeless_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
        where(shsm_b[:project_type].in(GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES)).
        where(shsm_b[:date].between(3.years.ago.to_date..Date.today)).
        where(shsm_b[:client_id].in(client_ids)).
        where(non_homeless_sql).
        select(shsm_b[:client_id], shsm_b[:date]).
        to_sql.
        sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as b")

      GrdaWarehouse::ServiceHistoryServiceMaterialized.
        from("(#{homeless_sql}) as c").
        distinct.
        group(shsm_c[:client_id]).
        count('c.date')
    end
  end

  def most_recent_chronic_dates client_ids: []
    @most_recent_chronic_dates ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.homeless(chronic_types_only: true).
      where(client_id: client_ids).
      group(:client_id).
      maximum(:date)
  end
  def first_chronic_dates client_ids: []
    @first_chronic_dates ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.homeless(chronic_types_only: true).
      where(client_id: client_ids).
      group(:client_id).
      minimum(:date)
  end
  def chronic_counts client_ids: []
    @chronic_counts ||= begin
      shsm_table_name = GrdaWarehouse::ServiceHistoryServiceMaterialized.table_name
      shsm = Arel::Table.new(shsm_table_name.to_sym)
      shsm_a = shsm.alias('a')
      shsm_b = shsm.alias('b')
      shsm_c = shsm.alias('c')

      non_homeless_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
        where(shsm_a[:project_type].in(r_non_homeless(chronic: true))).
        where(shsm_a[:date].between(3.years.ago.to_date..Date.today)).
        where(shsm_a[:client_id].in(client_ids)).
        where(shsm_a[:date].eq(shsm_b[:date])).
        where(shsm_a[:client_id].eq(shsm_b[:client_id])).
        select(shsm_a[:client_id], shsm_a[:date]).
        exists.not.
        to_sql.
        sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as a")

      homeless_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
        where(shsm_b[:project_type].in(GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES)).
        where(shsm_b[:date].between(3.years.ago.to_date..Date.today)).
        where(shsm_b[:client_id].in(client_ids)).
        where(non_homeless_sql).
        select(shsm_b[:client_id], shsm_b[:date]).
        to_sql.
        sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as b")

      GrdaWarehouse::ServiceHistoryServiceMaterialized.
        from("(#{homeless_sql}) as c").
        distinct.
        group(shsm_c[:client_id]).
        count('c.date')
    end
  end

  def most_recent_total_dates client_ids: []
    @most_recent_total_dates ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.
      where(client_id: client_ids).
      group(:client_id).
      maximum(:date)
  end
  def first_total_dates client_ids: []
    @first_total_dates ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.
      where(client_id: client_ids).
      group(:client_id).
      minimum(:date)
  end
  def total_counts client_ids: []
    @total_counts ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.
      where(client_id: client_ids).
      group(:client_id).
      distinct.
      count(:date)
  end

  def r_non_homeless(chronic: false)
    if chronic
      GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    else
      GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
    end
  end
end