namespace :migrate do
  desc 'Migrate HUD 2022 to HUD 2024 data'
  task up: [:environment, 'log:info_to_stdout'] do
    HudTwentyTwentyTwoToTwentyTwentyFour::DbTransformer.up
  end
end