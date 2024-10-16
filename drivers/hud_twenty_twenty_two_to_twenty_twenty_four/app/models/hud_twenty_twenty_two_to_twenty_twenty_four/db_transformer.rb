###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour
  class DbTransformer
    def self.up
      classes = {
        HudTwentyTwentyTwoToTwentyTwentyFour::HmisParticipation::Db => {
          project: {
            model: GrdaWarehouse::Hud::Project,
          },
          organization: {
            model: GrdaWarehouse::Hud::Organization,
          },
        },
        HudTwentyTwentyTwoToTwentyTwentyFour::CeParticipation::Db => {
          project: {
            model: GrdaWarehouse::Hud::Project,
          },
        },
        HudTwentyTwentyTwoToTwentyTwentyFour::Export::Db => {},
        HudTwentyTwentyTwoToTwentyTwentyFour::Client::Db => {},
        HudTwentyTwentyTwoToTwentyTwentyFour::CurrentLivingSituation::Db => {},
        HudTwentyTwentyTwoToTwentyTwentyFour::Enrollment::Db => {
          enrollment_coc: {
            model: GrdaWarehouse::Hud::EnrollmentCoc,
          },
        },
        HudTwentyTwentyTwoToTwentyTwentyFour::Exit::Db => {},
        HudTwentyTwentyTwoToTwentyTwentyFour::HealthAndDv::Db => {},
        HudTwentyTwentyTwoToTwentyTwentyFour::IncomeBenefit::Db => {},
        HudTwentyTwentyTwoToTwentyTwentyFour::Project::Db => {},
        # HudTwentyTwentyTwoToTwentyTwentyFour::Service::Db, # Only adds nils, so processing not required
      }

      if RailsDrivers.loaded.include?(:hmis_csv_importer)
        classes.merge!(
          {
            HudTwentyTwentyTwoToTwentyTwentyFour::AggregatedEnrollment::Db => {
              enrollment_coc: {
                model: GrdaWarehouse::Hud::EnrollmentCoc,
              },
            },
            HudTwentyTwentyTwoToTwentyTwentyFour::AggregatedExit::Db => {},
          },
        )
      end

      classes.each do |klass, references|
        puts klass
        ::Kiba.run(klass.up(references))
      end
    end
  end
end
