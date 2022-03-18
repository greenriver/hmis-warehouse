###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Gather < OpenStruct
  # Accepts a hash of buckets with either lambdas or where clauses or both to determine inclusion of items from the scope
  #  {
  #    'Title' =>  -> { }, accepts an item of type column to pluck
  #  }
  # @param buckets [Hash]
  # @param scope [GrdaWarehouse::ServiceHistoryEnrollment relation]
  # @param id_column [Symbol or Arel column equivalent] used to determine uniqueness
  # @param calculation_column [Symbol or Arel column equivalent] used to determine bucket
  def initialize(buckets:, scope:, id_column: :id, calculation_column:)
  end

  private def cache_key
    @cache_key ||= Digest::MD5.hexdigest(buckets.to_s + scope.to_sql + id_column.to_ + calculation_column.to_s)
  end

  private def expires_in
    return 30.seconds if Rails.env.development?

    30.minutes
  end

  # Returns a hash of ids keyed on titles
  def ids
    @ids ||= {}.tap do |gathered|
      Rails.cache.fetch([cache_key, 'ids'], expires_in: expires_in) do
        # Fetch all matching data, ordered by entry date, so we get the most-recent enrollment
        # pluck the differentiator and the calculation that can be compared in the lambda
        data = scope.distinct.order(first_date_in_program: :desc).pluck(id_column, calculation_column)
        counted = Set.new
        buckets.each do |title, calcs|
          gathered[title] = data.select do |id, column|
            next if id.in?(counted)

            in_bucket = calcs[:lambda].call(column)
            count << id if in_bucket
            in_bucket
          end.map(&:first).to_set
        end
      end
    end
  end

  def bucket(title:)
    ids[title]
  end
end
