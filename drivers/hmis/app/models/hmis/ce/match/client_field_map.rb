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

    protected

    def arel
      Hmis::ArelHelper
    end

    def all
      @all ||= {
        veteran_status: {
          instance_value: lambda(&:veteran_status),
          arel_field: arel.c_t['VeteranStatus'],
        },
        current_age: {
          instance_value: ->(c) { c.age(current_date) },
          arel_field: age_from(current_date, arel.c_t['DOB']),
        },
        days_homeless: {
          instance_value: ->(c) do
            GrdaWarehouse::Hud::Client.days_homeless(client_id: c.id)
          end,
        },
        # Resolves an array of project types at which the Client has an open Enrollment (excluding WIP enrollments)
        # Note: this does not include WIP enrollments. We may need to support that in the future, in which case we could
        # introduce another field like `open_and_incomplete_enrollment_project_types` (or maybe it should be the default for this? discuss)
        open_enrollment_project_types: {
          instance_value: ->(c) do
            c.source_enrollments.ongoing.joins(:project).pluck(arel.p_t['ProjectType'])
          end,
        },
        # Resolves an array of project types at which the Client has an active Referral (a.k.a. not yet declined or accepted)
        open_referral_project_types: {
          instance_value: ->(c) do
            Hmis::Ce::Referral.joins(client: :warehouse_client_source).
              where(warehouse_clients: { destination_id: c.id }).
              active.
              joins(:target_project).
              pluck(arel.p_t['ProjectType'])
          end,
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
  end
end
