###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Thin graphql dataloader wrapper around access loaders (Hmis::BaseAccessLoader)
class Sources::UserEntityAccessSource < GraphQL::Dataloader::Source
  attr_accessor :loader
  def initialize(loader)
    self.loader = loader
  end

  def fetch(items)
    loader.fetch(items)
  end

  def self.batch_key_for(*batch_args, **batch_kwargs)
    [*batch_args.map { |arg| arg.try(:batch_loader_id) || arg }, **batch_kwargs]
  end
end
