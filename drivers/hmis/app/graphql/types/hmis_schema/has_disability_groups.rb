###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasDisabilityGroups
      extend ActiveSupport::Concern
      include ArelHelper

      class_methods do
        def disability_groups_field(name = :disability_groups, description = nil, **override_options, &block)
          default_field_options = { type: [Types::HmisSchema::DisabilityGroup], null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end
        end
      end

      # Resolve disabilities list into an array of OpenStructs.
      # Each struct represents a group of disability records that were collected
      # on the same Information Date / Data Collection Stage / Enrollment.
      # Each struct contains a `disabilities` array field, which has
      # information about all six disability types.
      def resolve_disability_groups(scope = object.disabilities, **_args)
        # FIXME: we should key by SOURCE ASSESSMENT if possible, since there can be 2 update assessments on the same day.
        key_fields = [
          :enrollment_id, # Don't move! below code depends on item being first in array
          :user_id,       # Don't move! below code depends on item being second in array
          :information_date,
          :data_collection_stage,
        ]
        result_fields = [
          :disability_type,
          :disability_response,
          :indefinite_and_impairs,
          :id,
          :date_updated,
          :date_created,
        ]
        result_aggregations = result_fields.map { |f| nf('json_agg', [d_t[f]]).to_sql }

        disability_groups = scope.viewable_by(current_user).
          order(information_date: :desc, data_collection_stage: :desc).
          limit(150). # No pagination, so LIMIT to 25 most recent groups (6*25 = 150 records)
          group(*key_fields).
          pluck(*key_fields, *result_aggregations)

        enrollment_ids = disability_groups.map(&:first).uniq
        user_ids = disability_groups.map(&:second).uniq
        enrollments_by_id = Hmis::Hud::Enrollment.where(enrollment_id: enrollment_ids).index_by(&:enrollment_id)
        users_by_id = Hmis::Hud::User.where(user_id: user_ids).index_by(&:user_id)

        groups = disability_groups.map do |group|
          key_values = group[0..key_fields.length - 1]
          result_values = group[key_fields.length..]

          obj = OpenStruct.new(key_fields.zip(key_values).to_h)
          # Add enrollment and user records directly so we don't have n+1 looking them up in the type
          obj.enrollment = enrollments_by_id[obj.enrollment_id]
          obj.user = users_by_id[obj.user_id]
          obj.disabilities = result_values.transpose.map do |arr|
            OpenStruct.new(result_fields.zip(arr).to_h)
          end

          # Concatenate disability IDs to create a unique "ID" for the DisabilityGroup
          obj.id = obj.disabilities.map(&:id).join(':')
          obj.date_updated = obj.disabilities.map(&:date_updated).map(&:to_datetime).max
          obj.date_created = obj.disabilities.map(&:date_created).map(&:to_datetime).max
          obj
        end

        groups.sort_by(&:date_updated).reverse!
      end
    end
  end
end
