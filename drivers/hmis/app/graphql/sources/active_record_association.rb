###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
    # Rails.logger.info("preloading started #{records.first.class.name}.#{@association_name}") if records.any?
    TodoOrDie('test behavior after rails upgrade, see #6019', if: Rails.version !~ /\A7\.0/)
    # in rails 7.0, calling preloader more than once can cause unscoped queries, particularly with has-many-through.
    # Resetting association before preload seems to address this
    records.each do |record|
      record.class.reflect_on_all_associations.each do |assoc|
        record.association(assoc.name).reset
      end
    end

    ::ActiveRecord::Associations::Preloader.new(records: records, associations: [@association_name], scope: @scope).call
    results = records.map { |record| record.public_send(@association_name) }
    # Rails.logger.info("preloading complete #{records.first.class.name}.#{@association_name}") if records.any?
    results
  end

  def self.batch_key_for(*batch_args, **batch_kwargs)
    [*batch_args.map { |arg| arg.try(:to_sql) || arg }, **batch_kwargs]
  end
end
