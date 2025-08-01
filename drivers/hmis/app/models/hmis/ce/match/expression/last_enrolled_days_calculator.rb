# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # Calculates the number of days since a client's last enrollment ended.
  # Returns 0 if the client is still enrolled (no exit date).
  class LastEnrolledDaysCalculator
    def initialize(current_date)
      @current_date = current_date
    end

    def call(clients)
      client_ids = clients.pluck(:id)
      values = GrdaWarehouse::Hud::Enrollment.joins(client: :warehouse_client_source).
        left_outer_joins(:exit).
        where(warehouse_clients: { destination_id: client_ids }).
        pluck(
          arel.wc_t[:destination_id],
          arel_expression,
        )

      result = values.index_by(&:first).transform_values(&:last)
      client_ids.each { |client_id| result[client_id] ||= nil }
      result
    end

    # Arel expression for calculating days since last enrollment.
    # Used when building SQL queries that need this calculation inline.
    def arel_expression
      arel.acase(
        [
          # If an enrollment exists but has no exit record, the client is still enrolled (0 days)
          [arel.ex_t[:id].eq(nil).and(arel.e_t[:id].not_eq(nil)), 0],
        ],
        elsewise: Arel::Nodes::Subtraction.new(
          Arel::Nodes::Quoted.new(@current_date),
          arel.ex_t['ExitDate'],
        ),
      )
    end

    private

    def arel
      Hmis::ArelHelper
    end
  end
end
