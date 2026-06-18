###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
