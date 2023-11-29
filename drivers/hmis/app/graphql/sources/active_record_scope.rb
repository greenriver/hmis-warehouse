###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Sources::ActiveRecordScope < ::GraphQL::Dataloader::Source
  def initialize(scope)
    @scope = scope
  end

  def fetch(ids)
    ids = ids.map { |i| i&.to_i } # ensure ids are integers so we can use the short-hand below

    # Load records by the provided IDs and return them in the same order
    @scope.where(id: ids).index_by(&:id).values_at(*ids)
  end

  def self.batch_key_for(*batch_args, **batch_kwargs)
    [*batch_args.map { |arg| arg.try(:to_sql) || arg }, **batch_kwargs]
  end
end
