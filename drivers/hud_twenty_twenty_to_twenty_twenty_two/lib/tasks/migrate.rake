namespace :migrate do
  desc 'Migrate HUD 2020 to HUD 2022 data'
  task up: [:environment, 'log:info_to_stdout'] do
    HudTwentyTwentyToTwentyTwentyTwo::DbTransformer.up
  end
end