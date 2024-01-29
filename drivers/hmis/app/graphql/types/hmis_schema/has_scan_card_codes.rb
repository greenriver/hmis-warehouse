###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasScanCardCodes
      extend ActiveSupport::Concern

      class_methods do
        def scan_card_codes_field(
          name = :scan_card_codes,
          description = nil,
          **override_options,
          &block
        )
          default_field_options = {
            type: Types::HmisSchema::ScanCardCode.page_type,
            null: false,
            description: description,
          }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end

          define_method(name) do
            object.scan_card_codes.
              with_deleted.
              order(deleted_at: :desc, created_at: :desc)
          end
        end
      end
    end
  end
end
