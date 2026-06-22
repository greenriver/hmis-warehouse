###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Filter::CeMatchRuleFilter < Hmis::Filter::BaseFilter
  GLOBAL_OWNER_TYPE = 'GrdaWarehouse::DataSource'

  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:with_owner))
  end

  protected

  def with_owner(scope)
    if owner_id_filter_present? && !owner_type_filter_present?
      return unsupported_filter(
        scope,
        'CE match rule filtering by ownerId without ownerType is not supported. Skipping owner filter.',
      )
    end

    return scope unless owner_type_filter_present?
    return scope.where(owner_type: input.owner_type) if input.owner_type == GLOBAL_OWNER_TYPE

    unsupported_filter(
      scope,
      "CE match rule filtering by owner type #{input.owner_type.inspect} is not implemented. Skipping owner filter.",
    )
  end

  def owner_type_filter_present?
    input.respond_to?(:owner_type) && input.owner_type.present?
  end

  def owner_id_filter_present?
    input.respond_to?(:owner_id) && input.owner_id.present?
  end

  def unsupported_filter(scope, message)
    raise ArgumentError, message if Rails.env.development? || Rails.env.test?

    Sentry.capture_message(
      message,
      level: :warning,
      extra: {
        owner_type: input.owner_type,
        owner_id: input.owner_id,
      },
    )
    scope
  end
end
