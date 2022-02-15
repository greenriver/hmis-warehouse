###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Phi
  class Category
    def self.as_json
      name
    end
  end

  # blog or attachment contains serialzied bulk PHI
  class Bulk < Category;
  end

  # Safe Harbor Identifiers
  class Name < Category; end
  class Location < Category; end
  class Date < Category; end
  class Telephone < Category; end
  class Fax < Category; end
  class Email < Category; end
  class Ssn < Category; end
  class MedicalRecordNumber < Category; end
  class HealthPlan < Category; end
  class AccountNumber < Category; end
  class LicenceNumber < Category; end
  class VehicleId < Category; end
  class DeviceId < Category; end
  class IpAddress < Category; end
  class BiometricId < Category; end
  class PhotoIdentity < Category; end
  class OtherIdentifier < Category; end

  # Labels for attributes that need
  # careful review:
  class NeedsReview < Category; end

  # This free text might contain PHI
  class FreeText < NeedsReview; end

  # This categorical field might result in
  # small populations that can be corrilated
  # with public data to re-identify the user
  class SmallPopulation < NeedsReview; end

  Attribute = Struct.new(:class, :name, :category, :description)
end
