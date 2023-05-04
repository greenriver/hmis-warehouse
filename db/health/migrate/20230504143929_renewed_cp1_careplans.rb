class RenewedCp1Careplans < ActiveRecord::Migration[6.1]
  def up
    cp2_date = (Health::PatientReferral::CP_2_REFERRAL_DATE ..)

    # Only careplans touched after the CP2 date can have been renewed...
    careplans = Health::Careplan.where(updated_at: cp2_date ..).
      # they must have been completed in the 12 months previously...
      where(provider_signed_on: cp2_date - 12.months .. cp2_date).
      # and, the NCM must have reviewed it after 4/1
      where(ncm_approved_on: cp2_date ..)

    careplans.each do |careplan|
      user = careplan.approving_ncm
      qa = Health::QualifyingActivity.new(
        source_type: @careplan.class.name,
        user_id: user.id,
        user_full_name: user.name_with_email,
        activity: :care_planning,
        date_of_activity: @careplan.ncm_approved_on,
        mode_of_contact: :in_person,
        reached_client: :yes,
        follow_up: 'This writer completed Care Plan with patient. Patient agreed to care plan.',
        patient_id: @careplan.patient_id,
      )
    end
  end
end
