class Filters::Criteria::ClientAge < Filters::Criteria::Base
  LEVEL = :client

  attribute :age_ranges, :array

  def apply(scope)
    ages = age_ranges.flat_map do |age_range|
      Filters::FilterBase.age_range(age_range).to_a
    end
    scope.joins(join_clients_method).in_age_ranges(ages)
    raise 'age range needs work'
  end
end
