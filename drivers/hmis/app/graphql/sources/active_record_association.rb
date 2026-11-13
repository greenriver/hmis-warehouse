###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# https://gist.github.com/itkrt2y/1e1a947c71772044f5d67f358b4772fc

class Sources::ActiveRecordAssociation < ::GraphQL::Dataloader::Source
  def initialize(association_name, onload: nil)
    raise "association must be symbol #{association_name.inspect}" unless association_name.is_a?(Symbol)

    @association_name = association_name
    @onload = onload
  end

  def fetch(records)
    ::ActiveRecord::Associations::Preloader.new(records: records, associations: [@association_name]).call
    results = records.map { |record| record.public_send(@association_name) }
    @onload&.call(results)

    # Rails.logger.info("preloading complete #{records.first.class.name}.#{@association_name}") if records.any?
    results
  end

  def self.batch_key_for(*batch_args, **batch_kwargs)
    [*batch_args.map { |arg| arg.try(:to_sql) || arg }, **batch_kwargs]
  end
end
