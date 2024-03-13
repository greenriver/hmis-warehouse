###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# https://gist.github.com/itkrt2y/1e1a947c71772044f5d67f358b4772fc

class Sources::ActiveRecordAssociation < ::GraphQL::Dataloader::Source
  def initialize(association_name, scope = nil)
    @association_name = association_name
    @scope = scope
  end

  def fetch(records)
    # in rails 7, this should be:
    # ::ActiveRecord::Associations::Preloader.new(records: records, associations: @association_name, scope: @scope).call

    ::ActiveRecord::Associations::Preloader.new.preload(records, @association_name, @scope)
    records.map { |record| record.public_send(@association_name) }
  end

  def self.batch_key_for(*batch_args, **batch_kwargs)
    [*batch_args.map { |arg| arg.try(:to_sql) || arg }, **batch_kwargs]
  end
end
