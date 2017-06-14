class Health::HealthVersion < PaperTrail::Version
  establish_connection DB_HEALTH
end