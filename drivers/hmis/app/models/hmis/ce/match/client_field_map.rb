# frozen_string_literal: true

# resolve fields from the client table
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
        aha_score: {
          instance_value: ->(_) { 20 }, # TODO(#7164) this is just a mocked value to see how things look on the Opportunity page
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
