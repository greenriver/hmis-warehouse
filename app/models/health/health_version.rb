# ### HIPPA Risk Assessment
# Risk: Audit-log containing PHI
class Health::HealthVersion < PaperTrail::Version
  establish_connection DB_HEALTH

  # phi_attr :object, Phi::Bulk # contains serialize model data that depends on the model
  # phi_attr :object_changes, Phi::Bulk # contains serialize model data that depends on the model
end