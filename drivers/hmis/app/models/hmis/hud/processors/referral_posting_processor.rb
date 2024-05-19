###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class ReferralPostingProcessor < Base
    def factory_name
      :owner_factory
    end

    def schema
      Types::HmisSchema::ReferralPosting
    end

    def information_date(_)
    end

    def assign_metadata
      record = @processor.send(factory_name)
      return if record.persisted?

      # record.assign_attributes(
      #   requested_by: @processor.current_user,
      #   requested_on: Time.current,
      # )
    end

    # FIXME: implement unit type validation?
    # maybe move this to model and validate on form submission context for new records
    def validate_unit_type(project, input)
      errors = HmisErrors::Errors.new
      valid_by_id = project.units.unoccupied_on.preload(:unit_type).index_by(&:unit_type_id)
      unless valid_by_id.key?(input.unit_type_id.to_i)
        valid_types = valid_by_id.values.map { |u| u.unit_type.description }.sort
        if valid_types.any?
          message = "not valid for the selected project. Valid types are #{valid_types.join(', ')}"
          errors.add(:unit_type, :invalid, message: message)
        else
          errors.add(:project_id, :invalid, message: 'does not have any available units')
        end
      end
      errors
    end
  end
end
