# PHI-fere
- [x] accountable_care_organizations
- [x] agencies
- [ ] AgencyPatientReferral
- [x] agency_users
- [x] data_sources




# PHI annotated
- [x] patients
- [x] appointments (belong_to patient)
- [x] careplans (belong_to patient)
- [x] epic_goals (belong_to patient)
- [x] epic_patients (belong_to patient)
- [-] health_goals (belong_to patient) - STI modal
- [-] medications (belong_to patient)
- [-] problems (belong_to patient)
- [-] teams (belong_to patient)
  - [-] team_members (belong_to team) - No direct PHI but see notes
- [-] visits (belong_to patient)
- [x] versions - PaperTrail audit log. May contain PHIs from any other Health model!
- [x] comprehensive_health_assessments

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
- [ ] equipment
- [ ] health_files
- [ ] member_status_report_patients
- [ ] member_status_reports
- [ ] participation_forms
- [ ] patient_referral_imports
- [ ] patient_referrals
- [ ] qualifying_activities
- [ ] release_forms
- [ ] sdh_case_management_notes
- [ ] self_sufficiency_matrix_forms
- [ ] services
- [ ] signable_documents
- [ ] signature_requests
- [ ] user_care_coordinators