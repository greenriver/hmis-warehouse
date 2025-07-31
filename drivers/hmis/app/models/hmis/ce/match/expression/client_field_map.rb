# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # FieldMap implementation for GrdaWarehouse::Hud::Client fields
  # This class resolves fields that are columns on the `Client` table or one of its associations.
  class ClientFieldMap
    attr_reader :current_date

    def initialize(current_date: Date.current)
      @current_date = current_date
    end

    def client_query(clients, field)
      callback = all.dig(field.to_sym, :query)
      raise ArgumentError, "Field \"#{field}\" is not supported" unless callback

      callback.call(clients)
    end

    def arel_field(field)
      all.dig(field.to_sym, :arel_field)
    end

    def joins(field)
      all.dig(field.to_sym, :joins)
    end

    # Label for user-facing display of resolved field
    def label_for(field)
      field.humanize
    end

    # Value for user-facing display of resolved field
    def format_for_display(field, value)
      formatted = all.dig(field.to_sym, :format_for_display)&.call(value)
      return value if formatted.nil?

      formatted
    end

    protected

    def arel
      Hmis::ArelHelper
    end

    def all
      @all ||= {
        last_enrolled_days: {
          query: ->(clients) do
            client_ids = clients.pluck(:id)
            values = GrdaWarehouse::Hud::Enrollment.joins(client: :warehouse_client_source).
              left_outer_joins(:exit).
              where(warehouse_clients: { destination_id: client_ids }).
              pluck(
                arel.wc_t[:destination_id],
                arel.acase(
                  [[arel.ex_t[:id].eq(nil), 0]], # 0 days if still enrolled
                  elsewise: Arel::Nodes::Subtraction.new(
                    Arel::Nodes::Quoted.new(@current_date),
                    arel.ex_t['ExitDate'],
                  ),
                ),
              )
            result = values.index_by(&:first).transform_values(&:last)
            client_ids.each { |client_id| result[client_id] ||= nil }
            result
          end,
          joins: [{ hmis_source_clients: { enrollments: :exit } }],
          arel_field: arel.acase(
            [
              # If an enrollment exists but has no exit record, the client is still enrolled.
              # In this case, the number of days since last enrollment is 0.
              [arel.ex_t[:id].eq(nil).and(arel.e_t[:id].not_eq(nil)), 0],
            ],
            elsewise: Arel::Nodes::Subtraction.new(
              Arel::Nodes::Quoted.new(@current_date),
              arel.ex_t['ExitDate'],
            ),
          ),
          format_for_display: ->(days) { days.nil? ? nil : "#{days} #{'day'.pluralize(days)}" },
        },
        veteran_status: {
          query: ->(clients) { clients.pluck(:id, :veteran_status).to_h },
          format_for_display: ->(v) { HudUtility2026.veteran_status(v) },
          arel_field: arel.c_t['VeteranStatus'],
        },
        current_age: {
          query: ->(clients) do
            clients.pluck(:id, age_from(@current_date, arel.c_t['DOB'])).to_h.transform_values { |v| v&.to_i }
          end,
          arel_field: age_from(@current_date, arel.c_t['DOB']),
        },
        days_homeless: {
          query: ->(clients) {
            client_ids = clients.pluck(:id)
            # To accurately count homeless days, we must first identify any days the client was housed,
            # as these will be excluded from the count. A client can have both homeless and housed
            # service history records on the same day, with "housed" taking precedence.
            housed_dates = GrdaWarehouse::ServiceHistoryService.non_homeless.
              where(client_id: client_ids).
              distinct.
              pluck(:client_id, :date)
            housed_dates_by_client = housed_dates.group_by(&:first).transform_values { |dates| dates.map(&:last) }

            # Next, gather all unique days where the client had a homeless status service recorded.
            homeless_dates = GrdaWarehouse::ServiceHistoryService.where(client_id: client_ids).
              homeless.
              where(arel.shs_t[:date].lteq(@current_date)).
              pluck(:client_id, :date)

            # Finally, for each client, count the number of unique homeless days,
            # ensuring any days they were housed are not included in the final count.
            result = homeless_dates.group_by(&:first).transform_values do |dates|
              client_id = dates.first&.first
              housed_for_client = housed_dates_by_client[client_id] || []
              unique_homeless_dates = dates.map(&:last).uniq
              (unique_homeless_dates - housed_for_client).count
            end
            client_ids.each { |client_id| result[client_id] ||= nil }
            result
          },
          format_for_display: ->(days) { days.nil? ? nil : "#{days} #{'day'.pluralize(days)}" },
        },
        # Array of Project Types at which the Client has an open Enrollment, including WIP enrollments.
        open_enrollment_project_types: {
          query: ->(clients) {
            client_ids = clients.pluck(:id)
            values = Hmis::Hud::Enrollment.joins(client: :warehouse_client_source).
              where(warehouse_clients: { destination_id: client_ids }).
              open_including_wip.
              joins(:project).
              distinct.
              pluck(arel.wc_t[:destination_id], arel.p_t['ProjectType'])
            result = values.group_by(&:first).transform_values { |rows| rows.map(&:last) }
            client_ids.each { |client_id| result[client_id] ||= [] }
            result
          },
          format_for_display: method(:map_project_types),
        },
        # Array of Project Types at which the Client has an open Enrollment, excluding WIP enrollments.
        open_enrollment_project_types_excluding_incomplete: {
          query: ->(clients) {
            client_ids = clients.pluck(:id)
            values = Hmis::Hud::Enrollment.joins(client: :warehouse_client_source).
              where(warehouse_clients: { destination_id: client_ids }).
              open_excluding_wip.
              joins(:project).
              distinct.
              pluck(arel.wc_t[:destination_id], arel.p_t['ProjectType'])
            result = values.group_by(&:first).transform_values { |rows| rows.map(&:last) }
            client_ids.each { |client_id| result[client_id] ||= [] }
            result
          },
          format_for_display: method(:map_project_types),
        },
        # Array of Project Types at which the Client has an active Referral (e.g. not yet declined or accepted)
        open_referral_project_types: {
          query: ->(clients) {
            client_ids = clients.pluck(:id)
            values = Hmis::Ce::Referral.joins(client: :warehouse_client_source).
              where(warehouse_clients: { destination_id: client_ids }).
              active.
              joins(:target_project).
              distinct.
              pluck(arel.wc_t[:destination_id], arel.p_t['ProjectType'])
            result = values.group_by(&:first).transform_values { |rows| rows.map(&:last) }
            client_ids.each { |client_id| result[client_id] ||= [] }
            result
          },
          format_for_display: method(:map_project_types),
        },
      }
    end

    #  DATE_PART(AGE('2024-12-26', "Client"."DOB"))
    def age_from(date, dob_field)
      Arel::Nodes::NamedFunction.new(
        'DATE_PART',
        [
          Arel::Nodes::Quoted.new('year'),
          Arel::Nodes::NamedFunction.new('AGE', [Arel::Nodes::Quoted.new(date), dob_field]),
        ],
      )
    end

    def map_project_types(project_type_ids)
      project_type_ids.uniq.map { |t| HudUtility2026.project_type(t) }
    end
  end
end
