# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # Calculates client age based on date of birth and a reference date.
  class AgeCalculator
    def initialize(current_date)
      @current_date = current_date
    end

    def call(clients)
      clients.pluck(:id, arel_expression).to_h.transform_values { |v| v&.to_i }
    end

    # Arel expression for calculating age using PostgreSQL's DATE_PART and AGE functions.
    # Returns the number of years between the DOB and the reference date.
    def arel_expression
      Arel::Nodes::NamedFunction.new(
        'DATE_PART',
        [
          Arel::Nodes::Quoted.new('year'),
          Arel::Nodes::NamedFunction.new('AGE', [Arel::Nodes::Quoted.new(@current_date), arel.c_t['DOB']]),
        ],
      )
    end

    private

    def arel
      Hmis::ArelHelper
    end
  end
end
