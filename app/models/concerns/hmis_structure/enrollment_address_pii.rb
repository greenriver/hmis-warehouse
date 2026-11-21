###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# LastPermanent* address columns exist on enrollment tables through HMIS CSV 2022, so this
# is included per model instead of through HmisStructure::Enrollment, which is shared with later years.
module HmisStructure::EnrollmentAddressPii
  extend ActiveSupport::Concern

  include HasPiiAttributes

  included do
    pii_attr :LastPermanentStreet, as: :geo_street
    pii_attr :LastPermanentZIP, as: :geo_postal_code
    pii_attr :LastPermanentCity, as: :geo_locality
  end
end
