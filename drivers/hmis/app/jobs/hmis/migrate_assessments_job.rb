###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  class MigrateAssessmentsJob < ApplicationJob
    include Hmis::Concerns::HmisArelHelper
    def perform(data_source_id:)
      system_user = Hmis::Hud::User.system_user(data_source_id: data_source_id)
      scope = Hmis::Hud::Enrollment.where(data_source_id: data_source_id)
      scope.in_batches(of: 1_000) do |enrollment_batch|
        key_fields = [
          :enrollment_id,
          :personal_id,
          :data_collection_stage,
          :information_date,
        ]
        result_fields = [
          :id,
          :user_id,
        ]
        en_hash = {}
        [
          Hmis::Hud::IncomeBenefit,
          Hmis::Hud::HealthAndDv,
          # TODO disability, which has id split out on type
        ].each do |klass|
          result_aggregations = result_fields.map { |f| nf('json_agg', [klass.arel_table[f]]).to_sql }
          id_key = "#{klass.name.demodulize.underscore}_id".to_sym

          klass.joins(:enrollment).merge(enrollment_batch).
            group(*key_fields).
            pluck(*key_fields, *result_aggregations).
            each do |arr|
              hash_key = arr[0..key_fields.length - 1]
              values = result_fields.zip(arr[key_fields.length..]).to_h
              puts "WARNING: more than 1 #{klass.name} for key. IDs: #{values[:id]}" if values[:id].size > 1
              hash_value = {
                id_key => values[:id].last,
                user_id: values[:user_id].last,
              }
              en_hash.deep_merge!({ hash_key => hash_value })
            end
        end

        # for each grouping of enrollment + informationdate + dcs + [a bunch of record IDs]
        # create a CustomAssessment and a FormProcessor
        en_hash.each do |hash_key, value|
          key = key_fields.zip(hash_key).to_h
          assessment = Hmis::Hud::CustomAssessment.where(
            data_source_id: data_source_id,
            assessment_date: key[:information_date],
            **key.slice(:enrollment_id, :personal_id, :data_collection_stage),
          ).first_or_initialize(user_id: value[:user_id] || system_user.user_id)
          next if assessment.persisted? && assessment.form_processor.present?

          assessment.build_form_processor(**value.except(:user_id))
          assessment.save!
        end
      end
    end
  end
end
