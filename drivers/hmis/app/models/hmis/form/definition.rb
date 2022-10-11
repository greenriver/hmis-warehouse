###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::Definition < ApplicationRecord
  self.table_name = :hmis_form_definitions

  has_many :instances, foreign_key: :identifier, primary_key: :form_definition_identifier
  has_many :assessment_details
end
