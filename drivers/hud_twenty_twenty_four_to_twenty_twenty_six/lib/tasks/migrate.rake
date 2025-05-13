namespace :migrate do
  desc 'Migrate HUD 2024 to HUD 2026 data'
  task up: [:environment, 'log:info_to_stdout'] do
    HudTwentyTwentyFourToTwentyTwentySix::DbTransformer.up
  end
end
