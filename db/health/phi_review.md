# PHI-free
- [x] accountable_care_organizations
- [x] agencies
- [x] agency_users
- [x] data_sources

# PHI referred to ??? - patient not IDed directly
- [x] agency_patient_referrals
- [x] user_care_coordinators
- [x] epic_qualifying_activities
- [x] signable_documents

# PHI related models - annotated
- [x] patients
- [x] appointments (belong_to patient)
- [x] careplans (belong_to patient)
- [x] comprehensive_health_assessments (belong_to patient)
- [x] epic_careplans (belong_to patient)
- [x] epic_case_notes
- [x] epic_goals (belong_to patient)
- [x] epic_patients (belong_to patient)
- [x] epic_team_members (belong_to patient)
- [x] health_files (belong_to patient indirectly)
- [x] health_goals (belong_to patient) - STI modal
- [x] medications (belong_to patient)
- [x] problems (belong_to patient)
- [x] qualifying_activities (belong_to patient)
- [x] team_members (belong_to patient)
- [x] teams (belong_to patient)
- [x] visits (belong_to patient)
- [x] participation_forms (belong_to patient)
- [x] release_forms (belong_to patient)
- [x] self_sufficiency_matrix_forms (belong_to patient)
- [x] patient_referrals (belong_to patient)
- [x] services (belong_to patient)
- [x] equipment (belong_to patient)

# Sensitive logs
- [x] versions - PaperTrail audit log. May contain PHIs from any other Health model!

# TODO
- [ ] claims
- [ ] claims_amount_paid_location_month
- [ ] claims_claim_volume_location_month
- [ ] claims_ed_nyu_severity
- [ ] claims_roster
- [ ] claims_top_conditions
- [ ] claims_top_ip_conditions
- [ ] claims_top_providers
- [ ] cps
- [ ] epic_case_note_qualifying_activities
- [ ] epic_chas
- [ ] epic_ssms
- [ ] member_status_report_patients
- [ ] member_status_reports
- [ ] patient_referral_imports
- [ ] sdh_case_management_notes

- [ ] signature_requests