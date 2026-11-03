###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'memery'
# Demographic breakdown rows for the who section, by household type, gender
# and race, plus the household-type counts the household-type donut shows.
# Each period is counted in Postgres from two temp tables, so the query count
# and memory use don't grow with the number of enrollments or rows.
class PublicReports::StateDashboard::Breakdowns
  include ArelHelper
  include Memery

  ENROLLMENTS_TABLE = 'state_dashboard_period_enrollments'
  HOUSEHOLDS_TABLE = 'state_dashboard_period_households'
  # In household-type section order.
  HOUSEHOLD_TYPES = ['adult_only', 'adult_and_child', 'child_only'].freeze

  def initialize(report)
    @report = report
  end

  # rowId => { totals:, chronic:, sheltered:, unsheltered: }, one array entry per iteration_dates period.
  def rows
    dates = @report.iteration_dates
    num_periods = dates.size
    rows = {}

    dates.each_with_index do |date, date_index|
      sections = period_counts(@report.beginning_iteration(date), @report.end_iteration(date))[:sections]
      sections.each do |(grouping, section_index), row_counts|
        record_rows(
          rows: rows,
          grouping: grouping,
          section_index: section_index,
          row_counts: row_counts,
          date_index: date_index,
          num_periods: num_periods,
          # NOTE: for adults with children we sum all categories together
          combine_rows: grouping == 'household_type' && section_index == 1,
        )
      end
    end

    rows.each_value { |row| row[:sheltered] = nil if row[:sheltered].all?(&:nil?) }
    rows
  end

  def groupings
    {
      household_type: {
        label: 'Household Type',
        sections: household_type_setups.values.map { |section| { heading: section[:heading], rows: section[:rows].keys } },
      },
      gender: {
        label: 'Gender',
        sections: gender_setups.values.map { |section| { heading: section[:heading], rows: section[:rows].keys } },
      },
      race: {
        label: 'Race',
        sections: race_setups.values.map { |section| { heading: section[:heading], rows: section[:rows].keys } },
      },
    }
  end

  # HOUSEHOLD_TYPES entry => households served in the period. A head of household with several
  # households counts once; a household with no flagged head counts on its own.
  def household_type_counts(start_date, end_date)
    period_counts(start_date, end_date)[:household_types]
  end

  # Published row totals for one section and period, nil where hidden. A single hidden row could be
  # estimated from the period total and the other rows, so the smallest published non-zero row is hidden too.
  def published_row_totals(totals)
    published = totals.map { |total| @report.published_total(total) }
    return published unless published.count(&:nil?) == 1

    smallest = published.each_index.select { |i| published[i]&.positive? }.min_by { |i| published[i] }
    published[smallest] = nil if smallest
    published
  end

  # { sections: { [grouping, section_index] => row counts }, household_types: }
  private def period_counts(start_date, end_date)
    with_period_tables(start_date, end_date) do
      sections = {}
      household_type_setups.each do |section_index, section|
        sections[['household_type', section_index]] = section_counts(section[:rows].values, household_type: HOUSEHOLD_TYPES[section_index])
      end
      demographic_setups.each do |grouping, setups|
        setups.each do |section_index, section|
          columns = section[:rows].keys.each_index.map { |row_index| demographic_column(grouping, section_index, row_index) }
          sections[[grouping, section_index]] = section_counts(columns)
        end
      end
      { sections: sections, household_types: count_household_types }
    end
  end
  memoize :period_counts

  # row_counts: one { total:, chronic:, sheltered:, unsheltered: } per row, in setup order.
  private def record_rows(rows:, grouping:, section_index:, row_counts:, date_index:, num_periods:, combine_rows:)
    combined_chronic_count = row_counts.sum { |counts| counts[:chronic] }
    combined_total_count = row_counts.sum { |counts| counts[:total] }
    row_totals = published_row_totals(row_counts.map { |counts| counts[:total] })

    row_counts.each_with_index do |counts, row_index|
      row_id = "#{grouping}__#{section_index}__#{row_index}"
      rows[row_id] ||= {
        totals: Array.new(num_periods),
        chronic: Array.new(num_periods),
        sheltered: Array.new(num_periods),
        unsheltered: Array.new(num_periods),
      }

      chronic_count = combine_rows ? combined_chronic_count : counts[:chronic]
      row_total = row_totals[row_index]
      rows[row_id][:totals][date_index] = row_total
      rows[row_id][:chronic][date_index] = row_total && @report.enforce_min_threshold([chronic_count, combine_rows ? combined_total_count : counts[:total]], 'chronic_percents')

      # A suppressed total would be recoverable as sheltered + unsheltered.
      if row_total.nil? || counts[:sheltered] < PublicReports::StateDashboard::MIN_THRESHOLD || counts[:unsheltered] < PublicReports::StateDashboard::MIN_THRESHOLD
        rows[row_id][:sheltered][date_index] = nil
        rows[row_id][:unsheltered][date_index] = nil
      else
        rows[row_id][:sheltered][date_index] = counts[:sheltered]
        rows[row_id][:unsheltered][date_index] = counts[:unsheltered]
      end
    end
  end

  # Builds the period's enrollment and household temp tables, yields, then drops them. One
  # transaction keeps every statement on the session that owns the tables, even behind a
  # transaction-mode pooler. On an error the rollback removes the tables.
  private def with_period_tables(start_date, end_date)
    conn = GrdaWarehouseBase.connection
    GrdaWarehouseBase.transaction do
      conn.create_table(ENROLLMENTS_TABLE, temporary: true, id: false, force: true, as: period_enrollments(start_date, end_date))
      conn.create_table(HOUSEHOLDS_TABLE, temporary: true, id: false, force: true, as: period_households)
      # Autovacuum never analyzes temp tables.
      conn.execute("ANALYZE #{ENROLLMENTS_TABLE}")
      conn.execute("ANALYZE #{HOUSEHOLDS_TABLE}")
      result = yield
      conn.drop_table(HOUSEHOLDS_TABLE)
      conn.drop_table(ENROLLMENTS_TABLE)
      result
    end
  end

  # One row per enrollment served in the period: age-band, chronic and demographic flags, plus
  # the minimum known age and latest head-of-household service date that classify its household.
  private def period_enrollments(start_date, end_date)
    shs_scope = GrdaWarehouse::ServiceHistoryService.where(date: start_date..end_date)
    scope = @report.homeless_scope.with_service_between(
      start_date: start_date,
      end_date: end_date,
      service_scope: shs_scope,
    )
    chronic_enrollment_ids = scope.joins(enrollment: :ch_enrollment).
      merge(GrdaWarehouse::ChEnrollment.chronically_homeless).
      select(:id)
    age = shs_t[:age]
    scope.joins(:client).
      joins(:service_history_services).
      merge(shs_scope).
      group(she_t[:id], c_t[:id]).
      select(
        she_t[:client_id],
        she_t[:project_type],
        named(household_key, 'household_key'),
        named(she_t[:id].in(chronic_enrollment_ids.arel), 'chronic'),
        # A client who crosses an age boundary within the period is flagged in both bands, so
        # the age rows are not disjoint and can sum above the section total.
        named(nf('BOOL_OR', [age.between(0..17)]), 'age_0_17'),
        named(nf('BOOL_OR', [age.between(18..24)]), 'age_18_24'),
        named(nf('BOOL_OR', [age.between(25..104)]), 'age_25_104'),
        named(nf('BOOL_OR', [age.eq(nil).or(age.gteq(105)).or(age.lt(0))]), 'age_unknown'),
        named(age.minimum.filter(age.gteq(0)), 'min_known_age'),
        named(shs_t[:date].maximum.filter(she_t[:head_of_household].eq(true)), 'hoh_date'),
        *demographic_flags,
      )
  end

  # One row per household: its type and the head of household it counts under. A member's age
  # is their minimum known age in the period. There is no unknown-age household type: a child
  # plus any other member (adult or unknown age) is adult-and-child, only children is child-only,
  # and anything else, including a household with no known ages, is adult-only.
  private def period_households
    e_t = Arel::Table.new(ENROLLMENTS_TABLE)
    m_t = Arel::Table.new('members')
    members = e_t.project(
      e_t[:household_key],
      e_t[:client_id],
      e_t[:min_known_age].minimum.as('age'),
      e_t[:hoh_date].maximum.as('hoh_date'),
    ).group(e_t[:household_key], e_t[:client_id])
    child_present = nf('BOOL_OR', [m_t[:age].lt(18)])
    adult_present = nf('BOOL_OR', [m_t[:age].gteq(18).or(m_t[:age].eq(nil))])
    Arel::SelectManager.new(members.as('members')).
      project(
        m_t[:household_key],
        acase([[Arel::Nodes::And.new([child_present, adult_present]), 'adult_and_child'], [child_present, 'child_only']], elsewise: 'adult_only').as('household_type'),
        # Arel can't express an aggregate with ORDER BY. The head is the flagged member served last.
        Arel.sql('(ARRAY_AGG("members"."client_id" ORDER BY "members"."hoh_date" DESC, "members"."client_id") FILTER (WHERE "members"."hoh_date" IS NOT NULL))[1] AS hoh_client_id'),
      ).
      group(m_t[:household_key])
  end

  # One { total:, chronic:, sheltered:, unsheltered: } per flag column, from one query. A client
  # is chronic in a row when any of their enrollments in the section is chronic.
  private def section_counts(flag_columns, household_type: nil)
    e_t = Arel::Table.new(ENROLLMENTS_TABLE)
    h_t = Arel::Table.new(HOUSEHOLDS_TABLE)
    s_t = Arel::Table.new('section')
    enrollments = e_t.project(
      e_t[Arel.star],
      named(nf('BOOL_OR', [e_t[:chronic]]).over(Arel::Nodes::Window.new.partition(e_t[:client_id])), 'client_chronic'),
    )
    enrollments = enrollments.join(h_t).on(h_t[:household_key].eq(e_t[:household_key])).where(h_t[:household_type].eq(household_type)) if household_type

    sheltered = s_t[:project_type].in(HudHelper.util.homeless_sheltered_project_types)
    unsheltered = s_t[:project_type].in(HudHelper.util.homeless_unsheltered_project_types)
    distinct_clients = ->(condition) { Arel::Nodes::Count.new([s_t[:client_id]], true).filter(condition) }
    counts = flag_columns.flat_map do |column|
      in_row = s_t[column]
      [
        distinct_clients.call(in_row),
        distinct_clients.call(Arel::Nodes::And.new([in_row, s_t[:client_chronic]])),
        distinct_clients.call(Arel::Nodes::And.new([in_row, sheltered])),
        distinct_clients.call(Arel::Nodes::And.new([in_row, unsheltered])),
      ]
    end
    query = Arel::SelectManager.new(enrollments.as('section')).project(*counts)
    GrdaWarehouseBase.connection.select_all(query.to_sql).cast_values.first.each_slice(4).map do |total, chronic, sheltered_count, unsheltered_count|
      { total: total, chronic: chronic, sheltered: sheltered_count, unsheltered: unsheltered_count }
    end
  end

  private def count_household_types
    h_t = Arel::Table.new(HOUSEHOLDS_TABLE)
    # Neither a client id nor a household key ("<data source>:<id>") can equal the other.
    counted_as = cl(cast(h_t[:hoh_client_id], 'text'), h_t[:household_key])
    query = h_t.project(h_t[:household_type], Arel::Nodes::Count.new([counted_as], true)).group(h_t[:household_type])
    HOUSEHOLD_TYPES.index_with(0).merge(GrdaWarehouseBase.connection.select_all(query.to_sql).cast_values.to_h)
  end

  # One boolean column per gender and race row, from the row's Client scope conditions.
  private def demographic_flags
    demographic_setups.flat_map do |grouping, setups|
      setups.flat_map do |section_index, section|
        section[:rows].values.each_with_index.map do |client_scope, row_index|
          named(Arel::Nodes::And.new(client_scope.arel.constraints), demographic_column(grouping, section_index, row_index))
        end
      end
    end
  end

  private def demographic_setups
    { 'gender' => gender_setups, 'race' => race_setups }
  end

  private def demographic_column(grouping, section_index, row_index)
    "#{grouping}_#{section_index}_#{row_index}"
  end

  private def named(node, name)
    Arel::Nodes::As.new(Arel::Nodes::Grouping.new(node), Arel.sql(name))
  end

  # Row title => age-band flag column in ENROLLMENTS_TABLE.
  private def household_type_setups
    {
      0 => {
        heading: 'Persons in Households Without Children',
        rows: {
          'Persons Age 18 to 24' => :age_18_24,
          'Persons over age 24' => :age_25_104,
          'Persons of unknown age' => :age_unknown,
        },
      },
      1 => {
        heading: 'Persons in households with at least one child and one adult',
        rows: {
          'Children under 18' => :age_0_17,
          'Persons Age 18 to 24' => :age_18_24,
          'Persons over age 24' => :age_25_104,
          'Persons of unknown age' => :age_unknown,
        },
      },
      2 => {
        heading: 'Persons in Child-Only Households',
        rows: {
          'Children under 18' => :age_0_17,
        },
      },
    }
  end

  private def gender_setups
    # NOTE: only minorly updating this for now.  Since these are published publicly, we'll wait until we
    # have better direction on the scope of what's desired
    {
      0 => {
        heading: nil,
        rows: {
          'Woman' => GrdaWarehouse::Hud::Client.gender_woman,
          'Man' => GrdaWarehouse::Hud::Client.gender_man,
          'Transgender' => GrdaWarehouse::Hud::Client.gender_transgender,
          'Non-Binary' => GrdaWarehouse::Hud::Client.gender_non_binary,
          'Other or Unknown' => GrdaWarehouse::Hud::Client.gender_unknown.or(GrdaWarehouse::Hud::Client.questioning),
        },
      },
    }
  end

  private def race_setups
    # TODO: DEPRECATED_FY2024 need to revisit this since race and ethnicity have been combined.
    # We need to figure out how we'll represent that given the census data has a different shape.
    {
      0 => {
        heading: nil,
        rows: {
          'American Indian or Alaska Native' => GrdaWarehouse::Hud::Client.with_races(['AmIndAKNative']),
          'Asian' => GrdaWarehouse::Hud::Client.with_races(['Asian']),
          'Black or African American' => GrdaWarehouse::Hud::Client.with_races(['BlackAfAmerican']),
          'Native Hawaiian or Pacific Islander' => GrdaWarehouse::Hud::Client.with_races(['NativeHIPacific']),
          'White' => GrdaWarehouse::Hud::Client.with_races(['White']),
          # The census has no HispanicLatinaeo or MidEastNAfrican category, so a client with none
          # of the five census races, those two included, is Other or Unknown.
          'Other or Unknown' => GrdaWarehouse::Hud::Client.where(
            ['AmIndAKNative', 'Asian', 'BlackAfAmerican', 'NativeHIPacific', 'White'].map { |race| c_t[race].not_eq(1).or(c_t[race].eq(nil)) }.reduce(:and),
          ),
        },
      },
    }
  end

  # HouseholdID is only unique within a data source, and an enrollment without one is its own household.
  private def household_key
    nf('CONCAT', [she_t[:data_source_id], Arel::Nodes.build_quoted(':'), cl(she_t[:household_id], she_t[:enrollment_group_id])])
  end
end
