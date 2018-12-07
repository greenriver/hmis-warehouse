# PHI-fere
- [x] accountable_care_organizations
- [x] agencies
- [x] agency_users
- [x] data_sources
- [x] equipment
- [x] services

# PHI referred to - patient not IDed directly
- [x] agency_patient_referrals
- [x] user_care_coordinators

# PHI annotated
- [x] patients
- [x] appointments (belong_to patient)
- [x] careplans (belong_to patient)
- [x] epic_goals (belong_to patient)
- [x] epic_patients (belong_to patient)
- [x] health_goals (belong_to patient) - STI modal
- [x] medications (belong_to patient)
- [x] problems (belong_to patient)
- [x] teams (belong_to patient)
- [x] team_members (belong_to patient)
- [x] visits (belong_to patient)
- [x] comprehensive_health_assessments
- [x] health_files
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

- [ ] epic_careplans
- [ ] epic_case_note_qualifying_activities
- [ ] epic_case_notes
- [ ] epic_chas
- [ ] epic_goals
- [ ] epic_patients
- [ ] epic_qualifying_activities
- [ ] epic_ssms
- [ ] epic_team_members

- [ ] member_status_report_patients
- [ ] member_status_reports
- [ ] participation_forms
- [ ] patient_referral_imports
- [ ] patient_referrals
- [ ] qualifying_activities
- [ ] release_forms
- [ ] sdh_case_management_notes
- [ ] self_sufficiency_matrix_forms

- [ ] signable_documents
- [ ] signature_requests