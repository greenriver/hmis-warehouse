###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::Instance < ApplicationRecord
  self.table_name = :hmis_form_instances

  belongs_to :entity, polymorphic: true, optional: true
  belongs_to :definition, foreign_key: :identifier, primary_key: :form_definition_identifier
end
