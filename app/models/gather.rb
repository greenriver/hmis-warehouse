###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Gather < OpenStruct
  # Accepts a hash of buckets with either lambdas or where clauses or both to determine inclusion of items from the scope
  #  {
  #     'Title' => {
  #       lambda: -> { }, accepts an item of type column to pluck
  #       where_clause: that returns same set from active record,
  #     }
  #   }
  # @param buckets [Hash]
  # @param scope [GrdaWarehouse::ServiceHistoryEnrollment relation]
  # @param id_column [Symbol or Arel column equivalent] used to determine uniqueness
  # @param calculation_column [Symbol or Arel column equivalent] used to determine bucket
  def initialize(buckets:, scope:, id_column: :id, calculation_column:)
  end

  private def cache_key
    @cache_key ||= Digest::MD5.hexdigest(buckets.to_s + scope.to_sql + id_column.to_ + calculation_column.to_s)
  end

  # Returns a hash of ids keyed on titles
  def ids
    @ids ||= {}.tap do |gathered|
      data = scope.distinct.pluck(id_column, calculation_column)
      buckets.each do |title, calcs|
        gathered[title] = data.select do |_, column|
          calcs[:lambda].call(column)
        end.map(&:first)
      end
    end
  end

  # Returns a hash of scopes keyed on titles
  def scopes
    @scopes ||= {}.tap do |gathered|
      buckets.each do |title, calcs|
        gathered[title] = scope.distinct.pluck(id_column, calculation_column).where(calcs[:where_clause])
      end
    end
  end
end
