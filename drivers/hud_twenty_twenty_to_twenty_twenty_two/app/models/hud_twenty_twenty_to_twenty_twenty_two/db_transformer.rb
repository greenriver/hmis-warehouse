###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo
  class DbTransformer
    def self.up
      [
        HudTwentyTwentyToTwentyTwentyTwo::Client::Db,
        # HudTwentyTwentyToTwentyTwentyTwo::Disability::Db, # Only adds nils, so processing not required
        HudTwentyTwentyToTwentyTwentyTwo::Enrollment::Db,
        HudTwentyTwentyToTwentyTwentyTwo::Export::Db,
        # HudTwentyTwentyToTwentyTwentyTwo::HealthAndDv::Db,  # Only adds nils, so processing not required
        # HudTwentyTwentyToTwentyTwentyTwo::IncomeBenefit::Db,  # Only adds nils, so processing not required
        HudTwentyTwentyToTwentyTwentyTwo::Organization::Db,
        # HudTwentyTwentyToTwentyTwentyTwo::Project::Db,  # Only adds nils, so processing not required
        # HudTwentyTwentyToTwentyTwentyTwo::Service::Db,  # Only adds nils, so processing not required
      ].each do |klass|
        puts klass
        ::Kiba.run(klass.up)
      end
    end
  end
end
