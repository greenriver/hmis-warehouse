###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# matriculation to new platform
# creates CustomService and CustomDataElements
module HmisExternalApis::AcHmis::Importers::Loaders
  class EmergencyShelterAllowanceGrantLoader < BaseLoader
    def perform(rows:)
      owner_id_by_enrollment_id = Hmis::Hud::Enrollment
        .where(data_source: data_source)
        .pluck(:enrollment_id, :id)
        .to_h
      records = rows.flat_map do |row|
        enrollment_id = row_value(row, field: 'EnrollmentID')
        owner_id = owner_id_by_enrollment_id.fetch(enrollment_id)
        [
          new_record(
            value: row_value(row, field: 'ReferredToAllowanceGrant'),
            definition: esg_referred_cde_def,
          ),
          new_record(
            value: row_value(row, field: 'ReceivedFunding'),
            definition: esg_received_funding_cde_def,
          ),
          new_record(
            value: row_value(row, field: 'AmountReceived'),
            definition: esg_amount_received_cde_def,
          ),
          new_record(
            value: row_value(row, field: 'ReasonNotReferred'),
            definition: esg_reason_not_referred_cde_def,
          ),
        ].compact_blank.each do |record|
          record.owner_type = model_class.name
          record.owner_id = owner_id
        end
      end

      # destroy existing records and re-import
      model_class
        .where(data_source: data_source)
        .where(owner_type: owner_class.name)
        .destroy_all
      model_class.import(
        records,
        validate: false,
        batch_size: 1_000,
      )
    end

    protected

     def new_record(value:, definition:)
      return unless value

      attrs = {
        owner_type: model_class.class_name,
        value_string: value, # FIXME - base on definition.field_type
        data_element_definition_id: definition.id,
        DateCreated: row_value(row, field: 'DateCreated') || Date.current,
        DateUpdated: row_value(row, field: 'DateUpdated') || Date.current,
      }.merge(default_attrs)
      model_class.new(attrs)
    end

    def owner_class
      Hmis::Hud::Enrollment
    end

    def model_class
      Hmis::Hud::CustomDataElement
    end

    def find_or_create_cde_definition(field_type:, key:, label:)
      Hmis::Hud::CustomDataElementDefinition.first_or_create!(
        data_source_id: data_source_id,
        owner_type: owner_class.name,
        key: key,
        field_type: field_type
      ) do |record|
        record.label = label
        record.user_id = system_user_id
      end
    end

    def esg_amount_received_cde_def
      @esg_amount_received_cde_def ||= find_or_create_cde_definition(
        field_type: :float,
        key: :esg_allowance_grant_received_amount,
        label: 'ESG Allowance Grant Received Amount'
      )
    end
  end
end
