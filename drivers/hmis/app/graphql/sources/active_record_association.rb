###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# https://gist.github.com/itkrt2y/1e1a947c71772044f5d67f358b4772fc

class Sources::ActiveRecordAssociation < ::GraphQL::Dataloader::Source
  def initialize(association_name, scope = nil)
    raise "association must be symbol #{association_name.inspect}" unless association_name.is_a?(Symbol)

    @association_name = association_name
    @scope = scope
  end

  def fetch(records)
    ::ActiveRecord::Associations::Preloader.new(records: records, associations: [@association_name], scope: @scope).call
    results = records.map { |record| record.public_send(@association_name) }
    # Rails.logger.info("preloading complete #{records.first.class.name}.#{@association_name}") if records.any?
    results
  end

  def self.batch_key_for(*batch_args, **batch_kwargs)
    [*batch_args.map { |arg| arg.try(:to_sql) || arg }, **batch_kwargs]
  end
end
