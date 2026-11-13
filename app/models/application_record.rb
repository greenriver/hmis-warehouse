###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include CustomApplicationRecord
  primary_abstract_class
  connects_to database: { writing: :primary, reading: :primary }
end
