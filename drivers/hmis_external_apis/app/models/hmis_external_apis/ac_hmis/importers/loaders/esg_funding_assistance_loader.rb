###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# matriculation to new platform
# creates CustomService and CustomDataElements
module HmisExternalApis::AcHmis::Importers::Loaders
  class EsgFundingAssistanceLoader < BaseLoader
    def perform(rows:)
      personal_id_by_enrollment_id = Hmis::Hud::Enrollment
        .where(data_source: data_source)
        .pluck(:enrollment_id, :personal_id)
        .to_h
      records = rows.map do |row|
        record = model_class.new(default_attrs)
        record.service_type = custom_service_type
        record.CustomServiceID = Hmis::Hud::Base.generate_uuid
        columns.each do |col|
          col.assign_value(row: row, record: record)
        end
        record.personal_id = personal_id_by_enrollment_id.fetch(record.enrollment_id)
        record.user_id ||= system_user_id
        record.date_provided = Date.current # FIXME - this isn't right?
        record
      end

      # destroy existing records and re-import
      model_class.where(data_source: data_source).destroy_all
      model_class.import(
        records,
        validate: false,
        batch_size: 1_000,
        recursive: true,
      )
    end

    protected

    def custom_service_type
      @custom_service_type ||= begin
        category = Hmis::Hud::CustomServiceCategory.where(
          name: 'ESG Funding Assistance',
          data_source_id: data_source.id
        ).first_or_create!(user_id: system_user_id)
        Hmis::Hud::CustomServiceType.where(
          name: 'ESG Funding Assistance',
          custom_service_category_id: category.id,
          data_source_id: data_source.id
        ).first_or_create!(user_id: system_user_id)
      end
    end

    def model_class
      Hmis::Hud::CustomService
    end

    def columns
      [
        attr_col('EnrollmentID'),
        attr_col('PaymentStartDate', map_to: 'FAStartDate'),
        attr_col('PaymentEndDate', map_to: 'FAEndDate'),
        attr_col('Amount', map_to: 'FAAmount'),
        cde_col('FundingSource', definition: funding_source_cde_def, default_attrs: default_attrs),
        cde_col('PaymentType', definition: payment_type_cde_def, default_attrs: default_attrs),
        attr_col('DateCreated'),
        attr_col('DateUpdated'),
        attr_col('UserID'),
      ]
    end

    def funding_source_cde_def
      @funding_source_cde_def ||= Hmis::Hud::CustomDataElementDefinition.where(
        owner_type: model_class.name,
        field_type: :string,
        key: :funding_source,
        label: 'Funding Source',
        data_source_id: data_source.id
      ).first_or_create!(user_id: system_user_id)
    end

    def payment_type_cde_def
      @payment_type_cde_def ||= Hmis::Hud::CustomDataElementDefinition.where(
        owner_type: model_class.name,
        field_type: :string,
        key: :payment_type,
        label: 'Payment Type',
        data_source_id: data_source.id
      ).first_or_create!(user_id: system_user_id)
    end
    class BaseColumn
      attr_accessor :field

      def row_value(row, field:)
        row[field]&.strip&.presence
      end
    end


    # 1:1 mapping of field to record attribute
    class AttributeColumn < BaseColumn
      attr_accessor :map_to
      def initialize(field, map_to: nil)
        self.field = field
        self.map_to = map_to
      end

      # assign col from row into record
      def assign_value(row:, record:)
        case map_to
        when String, Symbol
          record[map_to] = row_value(row, field: field)
        when nil
          record[field] = row_value(row, field: field)
        else
          raise
        end
      end
    end

    # field is as related CDE on record, importing both record and related CDE recursively
    class RelatedCommonDataElementColumn < BaseColumn
      attr_accessor :definition, :default_attrs
      def initialize(field, definition:, default_attrs:)
        self.field = field
        self.definition = definition
        self.default_attrs = default_attrs
      end

      # assign col from row into record
      def assign_value(row:, record:)
        value =  row_value(row, field: 'FundingSource')
        return unless value

        cde_attrs = default_attrs.merge({
          owner_type: model_class.class_name,
          value_string: value,
          data_element_definition_id: definition.id,
          DateCreated: row_value(row, field: 'DateCreated'),
          DateUpdated: row_value(row, field: 'DateUpdated'),
        })
        record.custom_data_elements.build(cde_attrs)
      end
    end

    def attr_col(...)
      AttributeColumn.new(...)
    end

    def cde_col(...)
      RelatedCommonDataElementColumn.new(...)
    end

  end
end
