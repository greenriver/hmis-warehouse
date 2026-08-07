###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Concerns::Restrictable
  extend ActiveSupport::Concern

  included do
    has_one :restricted_record, class_name: 'Hmis::RestrictedRecord', as: :restrictable, dependent: :destroy
  end

  def restricted?
    restricted_record.present?
  end

  # GraphQL and serializers use the `restricted` name.
  def restricted
    restricted?
  end

  def mark_as_restricted!(user:)
    Hmis::RestrictedRecord.mark!(self, user: user)
  end

  def remove_restriction!
    Hmis::RestrictedRecord.unmark!(self)
  end
end
