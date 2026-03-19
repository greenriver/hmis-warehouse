###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.configure do |config|
  # When a spec group is marked with :manages_hmis_form_state, we ensure that the default
  # HMIS form state (instances and definitions) is restored after the group completes.
  #
  # Usage:
  #    RSpec.describe MyClass, :manages_hmis_form_state do ... end
  config.after(:all, :manages_hmis_form_state) do
    Hmis::Form::Instance.delete_all
    Hmis::Form::Definition.delete_all
    HmisUtil::JsonForms.seed_all
  end
end
