# ### HIPPA Risk Assessment
# Risk: Audit-log containing PHI
class Health::HealthVersion < PaperTrail::Version
  establish_connection DB_HEALTH
end