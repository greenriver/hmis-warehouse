###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Validators::CustomServiceTypeValidator < Hmis::Hud::Validators::BaseValidator
  def validate(record)
    super(record) do
      record.errors.add :hud_record_type, :required if record.hud_type_provided.present? && !record.hud_record_type.present?

      if record.hud_record_type.present?
        Hmis::Hud::Validators::ServiceValidator.validate_service_type(
          record,
          record_type_field: :hud_record_type,
          type_provided_field: :hud_type_provided,
        )
      end
    end
  end
end
