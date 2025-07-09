# frozen_string_literal: true

# resolve fields from the client (and associated enrollments)
module Hmis::Ce::Match
  class ClientFieldMap
    def instance_value(client, field)
      callback = all.dig(field.to_sym, :instance_value)
      raise ArgumentError, "Field \"#{field}\" is not supported" unless callback

      callback.call(client)
    end

    def arel_field(field)
      all.dig(field.to_sym, :arel_field)
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
        veteran_status: {
          instance_value: lambda(&:veteran_status),
          arel_field: arel.c_t['VeteranStatus'],
          format_for_display: ->(v) { HudUtility2026.veteran_status(v) },
        },
        current_age: {
          instance_value: ->(c) { c.age(current_date) },
          arel_field: age_from(current_date, arel.c_t['DOB']),
        },
        days_homeless: {
          instance_value: ->(c) do
            GrdaWarehouse::Hud::Client.days_homeless(client_id: c.id)
          end,
          format_for_display: ->(days) { days.nil? ? nil : "#{days} #{'day'.pluralize(days)}" },
        },
        # Array of Project Types at which the Client has an open Enrollment, including WIP enrollments.
        open_enrollment_project_types: {
          instance_value: ->(c) do
            Hmis::Hud::Enrollment.joins(client: :warehouse_client_source).
              where(warehouse_clients: { destination_id: c.id }).
              open_including_wip.
              joins(:project).
              distinct.
              pluck(arel.p_t['ProjectType'])
          end,
          format_for_display: method(:map_project_types),
        },
        # Array of Project Types at which the Client has an open Enrollment, excluding WIP enrollments.
        open_enrollment_project_types_excluding_incomplete: {
          instance_value: ->(c) do
            Hmis::Hud::Enrollment.joins(client: :warehouse_client_source).
              where(warehouse_clients: { destination_id: c.id }).
              open_excluding_wip.
              joins(:project).
              distinct.
              pluck(arel.p_t['ProjectType'])
          end,
          format_for_display: method(:map_project_types),
        },
        # Array of Project Types at which the Client has an active Referral (e.g. not yet declined or accepted)
        open_referral_project_types: {
          instance_value: ->(c) do
            Hmis::Ce::Referral.joins(client: :warehouse_client_source).
              where(warehouse_clients: { destination_id: c.id }).
              active.
              joins(:target_project).
              distinct.
              pluck(arel.p_t['ProjectType'])
          end,
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

    def current_date
      @current_date ||= Date.current
    end

    def map_project_types(project_type_ids)
      project_type_ids.uniq.map { |t| HudUtility2026.project_type(t) }
    end
  end
end
