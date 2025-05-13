###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix
  class DbTransformer
    def self.up
      classes = {
        HudTwentyTwentyFourToTwentyTwentySix::HmisParticipation::Db => {
          project: {
            model: GrdaWarehouse::Hud::Project,
          },
          organization: {
            model: GrdaWarehouse::Hud::Organization,
          },
        },
        HudTwentyTwentyFourToTwentyTwentySix::CeParticipation::Db => {
          project: {
            model: GrdaWarehouse::Hud::Project,
          },
        },
        HudTwentyTwentyFourToTwentyTwentySix::Export::Db => {},
        HudTwentyTwentyFourToTwentyTwentySix::Client::Db => {},
        HudTwentyTwentyFourToTwentyTwentySix::CurrentLivingSituation::Db => {},
        HudTwentyTwentyFourToTwentyTwentySix::Enrollment::Db => {
          enrollment_coc: {
            model: GrdaWarehouse::Hud::EnrollmentCoc,
          },
        },
        HudTwentyTwentyFourToTwentyTwentySix::Exit::Db => {},
        HudTwentyTwentyFourToTwentyTwentySix::HealthAndDv::Db => {},
        HudTwentyTwentyFourToTwentyTwentySix::IncomeBenefit::Db => {},
        HudTwentyTwentyFourToTwentyTwentySix::Project::Db => {},
        # HudTwentyTwentyFourToTwentyTwentySix::Service::Db, # Only adds nils, so processing not required
      }

      if RailsDrivers.loaded.include?(:hmis_csv_importer)
        classes.merge!(
          {
            HudTwentyTwentyFourToTwentyTwentySix::AggregatedEnrollment::Db => {
              enrollment_coc: {
                model: GrdaWarehouse::Hud::EnrollmentCoc,
              },
            },
            HudTwentyTwentyFourToTwentyTwentySix::AggregatedExit::Db => {},
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
