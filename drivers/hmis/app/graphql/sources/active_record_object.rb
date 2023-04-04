###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# https://evilmartians.com/chronicles/how-to-graphql-with-ruby-rails-active-record-and-no-n-plus-one
class Sources::ActiveRecordObject < GraphQL::Dataloader::Source
  def initialize(model_class, associations: [])
    @model_class = model_class
    @associations = associations
  end

  def fetch(ids)
    scope = @model_class.where(id: ids)
    scope.preload(*@associations) if @associations.present?
    records = scope.index_by(&:id)
    records.slice(*ids).values
  end
end
