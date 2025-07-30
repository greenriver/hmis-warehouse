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
    def instance_value_for_display(client, field)
      resolved_value = instance_value(client, field)
      all.dig(field.to_sym, :format_for_display)&.call(resolved_value) || resolved_value
    end

    protected

    def arel
      Hmis::ArelHelper
    end

    def all
      @all ||= {
        last_enrolled_at: {
          query: ->(clients) do
            # FIXME should take be max exit
            values = GrdaWarehouse::Hud::Enrollment.joins(client: :warehouse_client_source ).
              left_outer_joins(:exit).
              where(warehouse_clients: { destination_id: clients.select(:id) }).
              pluck(
                arel.wc_t[:destination_id],
                arel.acase(
                  [[arel.ex_t[:id].eq(nil), @current_date],],
                  elsewise: arel.ex_t['ExitDate'],
                )
              )
            values.index_by(&:first).transform_values(&:last)
          end,
          joins: [{ hmis_source_clients: { enrollments: :exit } }],
          arel_field: arel.acase(
            [
              # if there's no exit, but there is an enrollment, use today
              [arel.ex_t[:id].eq(nil).and(arel.e_t[:id].not_eq(nil)), @current_date],
            ],
            elsewise: arel.ex_t['ExitDate'],
          ),
        },
        veteran_status: {
          query: ->(clients) { clients.pluck(:id, :veteran_status).to_h },
          format_for_display: ->(v) { HudUtility2026.veteran_status(v) },
          arel_field: arel.c_t['VeteranStatus'],
        },
        current_age: {
          query: ->(clients) { clients.pluck(:id, age_from(@current_date, arel.c_t['DOB'])).to_h },
          arel_field: age_from(@current_date, arel.c_t['DOB']),
        },
        days_homeless: {
          query: ->(clients) {
            # Get housed dates for all clients to exclude from homeless dates
            housed_dates = GrdaWarehouse::ServiceHistoryService.non_homeless.
              where(client_id: clients.select(:id)).
              pluck(:client_id, :date)
            housed_dates_by_client = housed_dates.group_by(&:first).transform_values { |dates| dates.map(&:last) }

            # Get homeless dates for all clients
            homeless_dates = GrdaWarehouse::ServiceHistoryService.where(client_id: clients.select(:id)).
              homeless.
              where(arel.shs_t[:date].lteq(@current_date)).
              pluck(:client_id, :date)

            # Count unique homeless dates per client, excluding housed dates
            homeless_dates.group_by(&:first).transform_values do |dates|
              client_id = dates.first&.first
              housed_for_client = housed_dates_by_client[client_id] || []
              unique_homeless_dates = dates.map(&:last).uniq
              (unique_homeless_dates - housed_for_client).count
            end
          },
          format_for_display: ->(days) { days.nil? ? nil : "#{days} #{'day'.pluralize(days)}" },
        },
        # Array of Project Types at which the Client has an open Enrollment, including WIP enrollments.
        open_enrollment_project_types: {
          query: ->(clients) {
            values = Hmis::Hud::Enrollment.joins(client: :warehouse_client_source).
              where(warehouse_clients: { destination_id: clients.select(:id) }).
              open_including_wip.
              joins(:project).
              distinct.
              pluck(arel.wc_t[:destination_id], arel.p_t['ProjectType'])
            values.group_by(&:first).transform_values { |rows| rows.map(&:last) }
          },
          format_for_display: method(:map_project_types),
        },
        # Array of Project Types at which the Client has an open Enrollment, excluding WIP enrollments.
        open_enrollment_project_types_excluding_incomplete: {
          query: ->(clients) {
            values = Hmis::Hud::Enrollment.joins(client: :warehouse_client_source).
              where(warehouse_clients: { destination_id: clients.select(:id) }).
              open_excluding_wip.
              joins(:project).
              distinct.
              pluck(arel.wc_t[:destination_id], arel.p_t['ProjectType'])
            values.group_by(&:first).transform_values { |rows| rows.map(&:last) }
          },
          format_for_display: method(:map_project_types),
        },
        # Array of Project Types at which the Client has an active Referral (e.g. not yet declined or accepted)
        open_referral_project_types: {
          query: ->(clients) {
            values = Hmis::Ce::Referral.joins(client: :warehouse_client_source).
              where(warehouse_clients: { destination_id: clients.select(:id) }).
              active.
              joins(:target_project).
              distinct.
              pluck(arel.wc_t[:destination_id], arel.p_t['ProjectType'])
            values.group_by(&:first).transform_values { |rows| rows.map(&:last) }
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

    def last_enrollment_date(client)
      enrollments = client.hmis_source_clients.joins(:enrollments)
      return @current_date if enrollments.where.missing(:exit).exists?

      enrollments.joins(:exit).maximum(arel.ex_t['ExitDate'])&.to_date
    end
  end
end
