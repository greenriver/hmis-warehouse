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
        def disability_groups_field(name = :events, description = nil, **override_options, &block)
          default_field_options = { type: [Types::HmisSchema::DisabilityGroup], null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end
        end
      end

      # Resolve disabilities list into an array of hashes with this shape:
      # { :enrollment_id=>\"1370143\",
      #   :information_date=>Mon, 21 Feb 2022,
      #   :data_collection_stage=>5,
      #   :user_id=>\"hillary\",
      #   :disabilities=>
      #    [{:disability_type=>7, :disability_response=>1, :indefinite_and_impairs=>0},
      #     {:disability_type=>9, :disability_response=>1, :indefinite_and_impairs=>1},
      #     {:disability_type=>8, :disability_response=>0, :indefinite_and_impairs=>nil}]
      # }
      def resolve_disability_groups(scope = object.disabilities, **_args)
        key_fields = [
          :enrollment_id,
          :user_id,
          :information_date,
          :data_collection_stage,
        ]
        result_fields = [
          :disability_type,
          :disability_response,
          :indefinite_and_impairs,
          :id,
        ]
        result_aggregations = result_fields.map { |f| array_agg(d_t[f]).to_sql }

        disability_groups = scope.viewable_by(current_user).
          order(information_date: :desc, data_collection_stage: :desc).
          limit(150). # No pagination, so LIMIT to 25 most recent groups (6*25 = 150 records)
          group(*key_fields).
          pluck(*key_fields, *result_aggregations)

        enrollment_ids = disability_groups.map(&:first).uniq
        user_ids = disability_groups.map(&:second).uniq
        enrollments_by_id = Hmis::Hud::Enrollment.where(enrollment_id: enrollment_ids).index_by(&:enrollment_id)
        users_by_id = Hmis::Hud::User.where(user_id: user_ids).index_by(&:user_id)

        disability_groups.map do |group|
          key_values = group[0..key_fields.length - 1]
          result_values = group[key_fields.length..]

          obj = OpenStruct.new(key_fields.zip(key_values).to_h)
          # Add enrollment and user records directly so we don't have n+1 looking them up in the type
          obj.enrollment = enrollments_by_id[obj.enrollment_id]
          obj.user = users_by_id[obj.user_id]
          obj.disabilities = result_values.transpose.map do |arr|
            OpenStruct.new(result_fields.zip(arr).to_h)
          end
          obj.id = obj.disabilities.map(&:id).join(':')
          obj
        end
      end
    end
  end
end
