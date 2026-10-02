###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Client ids whose PII is hidden warehouse-wide: every member of a warehouse identity touched by
# an HMIS restriction, plus every member of an identity with a retention mark
# (GrdaWarehouse::ClientRetentionMark, one row per source client). Both sets are defined here, in the
# three shapes below, which a spec pins equal; analytics.client_piis (db/views) repeats them and
# must stay in step.
#
# The definition is written in three shapes because Postgres plans them differently:
# - #restricted_subset / #inactive_subset: a page of ids, indexed lookups on the page's identities.
# - #hidden_ids_in: a whole scope, so the sets are materialized once as IN (subquery) hashes.
# - #not_hidden: a row predicate, as correlated NOT EXISTS probes. Postgres does not push the
#   correlated column into a UNION, so the predicate can't be built from the unions below.
module GrdaWarehouse::HiddenClients
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

  # The members of +client_ids+ (source or destination ids) whose warehouse identity holds an
  # HMIS restriction. Reads only the identities of the given ids, so the cost follows the page
  # size and not the restricted population.
  # @param client_ids [Enumerable<Integer>]
  # @param links [Array<Array(Integer, Integer)>, nil] identity_links(client_ids), when the caller already has them
  # @return [Set<Integer>]
  def self.restricted_subset(client_ids, links: nil)
    ids = client_ids.to_a.compact.uniq
    return Set.new if ids.empty?

    links ||= identity_links(ids)
    direct = Hmis::RestrictedRecord.for_clients.where(restrictable_id: (ids + links.flatten).uniq).pluck(:restrictable_id).to_set
    return Set.new if direct.empty?

    restricted_destinations = links.select { |source_id, destination_id| direct.include?(source_id) || direct.include?(destination_id) }.map(&:last).to_set
    hidden = direct + links.select { |_, destination_id| restricted_destinations.include?(destination_id) }.flatten
    ids.select { |id| hidden.include?(id) }.to_set
  end

  # [source_id, destination_id] for every live warehouse_clients row in the identities of +ids+.
  # @param ids [Array<Integer>]
  # @return [Array<Array(Integer, Integer)>]
  def self.identity_links(ids)
    # WarehouseClient doesn't use acts as paranoid
    live_links = GrdaWarehouse::WarehouseClient.where(deleted_at: nil)
    wc_t = GrdaWarehouse::WarehouseClient.arel_table
    destination_ids = live_links.
      where(wc_t[:source_id].in(ids).or(wc_t[:destination_id].in(ids))).
      select(:destination_id)
    live_links.where(destination_id: destination_ids).pluck(:source_id, :destination_id)
  end

  # Ids in +scope+ that are restricted or inactive, in one query. For batch jobs that walk a
  # large client scope row by row.
  # @param scope [ActiveRecord::Relation<GrdaWarehouse::Hud::Client>]
  # @return [Set<Integer>]
  def self.hidden_ids_in(scope)
    id = scope.arel_table[:id]
    hidden = id.in(Arel::Nodes::Grouping.new(restricted_ids_union)).or(id.in(Arel::Nodes::Grouping.new(inactive_ids_union)))
    scope.where(hidden).pluck(:id).to_set
  end

  # Predicate that is true when +column+ is not a hidden client id. Every branch is a correlated
  # NOT EXISTS over an indexed column, so Postgres plans each as an anti-join probe per candidate
  # row, and a NULL column is kept.
  # @param column [Arel::Attributes::Attribute, Arel::Nodes::Node]
  # @return [Arel::Nodes::Node]
  def self.not_hidden(column)
    rr_t = Hmis::RestrictedRecord.arel_table
    marks_t = GrdaWarehouse::ClientRetentionMark.arel_table
    me = GrdaWarehouse::WarehouseClient.arel_table.alias(:hidden_me)
    sib = GrdaWarehouse::WarehouseClient.arel_table.alias(:hidden_sib)
    active_restriction = rr_t[:restrictable_type].eq(Hmis::RestrictedRecord::CLIENT_RESTRICTABLE_TYPE).and(rr_t[:deleted_at].eq(nil))

    directly_restricted = rr_t.project(Arel.sql('1')).where(active_restriction.and(rr_t[:restrictable_id].eq(column)))
    # column is a source whose destination has another restricted source
    sibling_restricted = Arel::SelectManager.new.from(me).project(Arel.sql('1')).
      join(sib).on(sib[:destination_id].eq(me[:destination_id]).and(sib[:deleted_at].eq(nil))).
      join(rr_t).on(active_restriction.and(rr_t[:restrictable_id].eq(sib[:source_id]))).
      where(me[:deleted_at].eq(nil).and(me[:source_id].eq(column)))
    # column is a destination with a restricted source
    source_restricted = Arel::SelectManager.new.from(sib).project(Arel.sql('1')).
      join(rr_t).on(active_restriction.and(rr_t[:restrictable_id].eq(sib[:source_id]))).
      where(sib[:deleted_at].eq(nil).and(sib[:destination_id].eq(column)))
    # column is a source whose destination is itself restricted
    destination_restricted = Arel::SelectManager.new.from(me).project(Arel.sql('1')).
      join(rr_t).on(active_restriction.and(rr_t[:restrictable_id].eq(me[:destination_id]))).
      where(me[:deleted_at].eq(nil).and(me[:source_id].eq(column)))

    directly_marked = marks_t.project(Arel.sql('1')).where(marks_t[:client_id].eq(column))
    # column is a destination with a marked source
    source_marked = Arel::SelectManager.new.from(me).project(Arel.sql('1')).
      join(marks_t).on(marks_t[:client_id].eq(me[:source_id])).
      where(me[:deleted_at].eq(nil).and(me[:destination_id].eq(column)))

    [directly_restricted, sibling_restricted, source_restricted, destination_restricted, directly_marked, source_marked].
      map { |subquery| subquery.exists.not }.
      inject(:and)
  end

  # UNION of the directly restricted client ids, the destinations they merge into, and every
  # source merged into those destinations, as a single client_id column.
  # @return [Arel::Nodes::Union]
  def self.restricted_ids_union
    rr_t = Hmis::RestrictedRecord.arel_table
    wc_t = GrdaWarehouse::WarehouseClient.arel_table

    # Pure Arel rather than Hmis::RestrictedRecord.for_clients.arel: a relation's arel carries bind
    # parameters, which cannot be rendered by to_sql.
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
    marks_t = GrdaWarehouse::ClientRetentionMark.arel_table
    wc_t = GrdaWarehouse::WarehouseClient.arel_table

    sources = marks_t.project(marks_t[:client_id])
    destinations = wc_t.
      project(wc_t[:destination_id]).
      join(marks_t).on(marks_t[:client_id].eq(wc_t[:source_id])).
      where(wc_t[:deleted_at].eq(nil))
    Arel::Nodes::Union.new(sources, destinations)
  end
  private_class_method :restricted_ids_union, :inactive_ids_union
end
