###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::Tasks
  module Downgrade
    include HudTwentyTwentyTwoToTwentyTwentyFour::LivingSituationOptions

    def self.downgrade_situations
      @processed_435 = Set.new
      {
        GrdaWarehouse::Hud::Enrollment => {
          situation: :LivingSituation,
          subsidy_type: :RentalSubsidyType,
          situation_2022: :LivingSituation2022,
        },
        GrdaWarehouse::Hud::CurrentLivingSituation => {
          situation: :CurrentLivingSituation,
          subsidy_type: :CLSSubsidyType,
          situation_2022: :CurrentLivingSituation2022,
        },
        GrdaWarehouse::Hud::Exit => {
          situation: :Destination,
          subsidy_type: :DestinationSubsidyType,
          situation_2022: :Destination2022,
        },
      }.each do |situation_class, cols|
        LIVING_SITUATIONS.each do |situation_2022, situation_2024|
          if situation_2024 == 435 && ! @processed_435.include?(cols[:situation])
            SUBSIDY_TYPES.each do |subsidy_type_2022, subsidy_type_2024|
              puts "Updating #{situation_class.name} #{cols[:situation]} #{situation_2024} and #{cols[:subsidy_type]} #{subsidy_type_2024} to #{cols[:situation]} #{subsidy_type_2022}"
              situation_class.with_deleted.where(cols[:situation] => situation_2024, cols[:subsidy_type] => subsidy_type_2024).
                update_all(
                  cols[:situation] => subsidy_type_2022,
                  # Make note of this to make the roll-back easier in the future
                  cols[:situation_2022] => subsidy_type_2022,
                )
            end
            @processed_435 << cols[:situation]
          else
            puts "Updating #{situation_class.name} #{cols[:situation]} #{situation_2024} to #{cols[:situation]} #{situation_2022}"
            situation_class.with_deleted.where(cols[:situation] => situation_2024).
              update_all(
                cols[:situation] => situation_2022,
                # Make note of this to make the roll-back easier in the future
                cols[:situation_2022] => situation_2022,
              )
          end
        end
      end
    end
  end
end
