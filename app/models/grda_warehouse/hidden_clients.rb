###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Client ids whose PII is hidden warehouse-wide: every member of a warehouse identity touched by
# an HMIS restriction, plus every member of an identity with a retention mark
# (GrdaWarehouse::InactiveClient, one row per source client). Both sets are defined here in SQL so
# RestrictedClientLoader and query-shaped callers share one definition; analytics.client_piis
# (db/views) repeats them and must stay in step.
module GrdaWarehouse::HiddenClients
  # @return [Set<Integer>]
  def self.restricted_ids
    GrdaWarehouseBase.connection.select_values(restricted_ids_union.to_sql).to_set
  end

  # Marked source ids plus the destinations they are linked to.
  # @return [Set<Integer>]
  def self.inactive_ids
    GrdaWarehouseBase.connection.select_values(inactive_ids_union.to_sql).to_set
  end

  # Only the destinations reached from marked sources, for callers whose rows are all
  # destination clients (the HMIS CSV export).
  # @return [Set<Integer>]
  def self.inactive_destination_ids
    GrdaWarehouseBase.connection.select_values(inactive_destinations.distinct.to_sql).to_set
  end

  # The members of +client_ids+ (source or destination ids) that are inactive, in one query.
  # @param client_ids [Enumerable<Integer>]
  # @return [Set<Integer>]
  def self.inactive_subset(client_ids)
    ids = client_ids.to_a.compact.uniq
    return Set.new if ids.empty?

    inactive = Arel::Nodes::TableAlias.new(inactive_ids_union, :inactive_ids)
    sql = Arel::SelectManager.new.from(inactive).project(inactive[:client_id]).where(inactive[:client_id].in(ids)).to_sql
    GrdaWarehouseBase.connection.select_values(sql).to_set
  end

  # Predicate that is true when +column+ is not a hidden client id. Both halves are correlated
  # NOT EXISTS, so Postgres plans an anti-join and a NULL column is kept.
  # @param column [Arel::Attributes::Attribute, Arel::Nodes::Node]
  # @return [Arel::Nodes::Node]
  def self.not_hidden(column)
    restricted = Arel::Nodes::TableAlias.new(restricted_ids_union, :restricted_clients)
    not_restricted = Arel::SelectManager.new.
      from(restricted).
      project(Arel.sql('1')).
      where(restricted[:client_id].eq(column)).
      exists.not

    inactive = Arel::Nodes::TableAlias.new(inactive_ids_union, :inactive_clients_union)
    not_inactive = Arel::SelectManager.new.
      from(inactive).
      project(Arel.sql('1')).
      where(inactive[:client_id].eq(column)).
      exists.not

    not_restricted.and(not_inactive)
  end

  # UNION of the directly restricted client ids, the destinations they merge into, and every
  # source merged into those destinations, as a single client_id column.
  # @return [Arel::Nodes::Union]
  def self.restricted_ids_union
    rr_t = Hmis::RestrictedRecord.arel_table
    wc_t = GrdaWarehouse::WarehouseClient.arel_table

    # Pure Arel rather than Hmis::RestrictedRecord.for_clients.arel: a relation's arel carries bind
    # parameters, which cannot be rendered by to_sql for restricted_ids.
    direct = rr_t.
      project(rr_t[:restrictable_id].as('client_id')).
      where(rr_t[:restrictable_type].eq(Hmis::RestrictedRecord::CLIENT_RESTRICTABLE_TYPE)).
      where(rr_t[:deleted_at].eq(nil))

    destinations = wc_t.
      project(wc_t[:destination_id]).
      where(wc_t[:deleted_at].eq(nil)).
      where(wc_t[:source_id].in(direct).or(wc_t[:destination_id].in(direct)))
    siblings = wc_t.
      project(wc_t[:source_id]).
      where(wc_t[:deleted_at].eq(nil)).
      where(wc_t[:destination_id].in(destinations))

    Arel::Nodes::Union.new(direct, Arel::Nodes::Union.new(destinations, siblings))
  end

  # UNION of the marked source ids and the destinations reachable from them through live
  # warehouse_clients rows, as a single client_id column.
  # @return [Arel::Nodes::Union]
  def self.inactive_ids_union
    sources = GrdaWarehouse::InactiveClient.arel_table.project(GrdaWarehouse::InactiveClient.arel_table[:client_id])
    Arel::Nodes::Union.new(sources, inactive_destinations)
  end

  # @return [Arel::SelectManager] destination_id of every live warehouse_clients row whose source is marked
  def self.inactive_destinations
    ic_t = GrdaWarehouse::InactiveClient.arel_table
    wc_t = GrdaWarehouse::WarehouseClient.arel_table

    wc_t.
      project(wc_t[:destination_id]).
      join(ic_t).on(ic_t[:client_id].eq(wc_t[:source_id])).
      where(wc_t[:deleted_at].eq(nil))
  end
  private_class_method :restricted_ids_union, :inactive_ids_union, :inactive_destinations
end
