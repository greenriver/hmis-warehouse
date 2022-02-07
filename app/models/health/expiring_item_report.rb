###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Health::ExpiringItemReport

  def tabs
    {
      # participation_forms: 'Participation Forms',
      # release_forms: 'Release Forms',
      ssms: 'SSMs',
      chas: 'CHAs',
      pctps: 'Careplans',
    }
  end

  # Participation Forms
  def expired_participation_forms
    patient_source.joins(:recent_participation_form).merge(
      participation_forms_source.expired.
        where.not(patient_id: active_participation_forms.select(:patient_id))
    ).distinct.
    preload(:recent_participation_form)
  end

  def expiring_participation_forms
    patient_source.joins(:recent_participation_form).merge(
      participation_forms_source.expiring_soon.
        where.not(patient_id: recently_completed_participation_forms.select(:patient_id))
    ).distinct.
    preload(:recent_participation_form)
  end

  private def active_participation_forms
   patient_source.joins(:participation_forms).merge(participation_forms_source.active)
  end

  private def recently_completed_participation_forms
   patient_source.joins(:participation_forms).merge(participation_forms_source.active.recently_signed)
  end

  private def participation_forms_source
    Health::ParticipationForm
  end

  # Release forms
  def expired_release_forms
    patient_source.joins(:recent_release_form).merge(
      release_forms_source.expired.
        where.not(patient_id: active_release_forms.select(:patient_id))
    ).distinct.
    preload(:recent_release_form)
  end

  def expiring_release_forms
    patient_source.joins(:recent_release_form).merge(
      release_forms_source.expiring_soon.
        where.not(patient_id: recently_completed_release_forms.select(:patient_id))
    ).distinct.
    preload(:recent_release_form)
  end

  private def active_release_forms
   patient_source.joins(:release_forms).merge(release_forms_source.active)
  end

  private def recently_completed_release_forms
   patient_source.joins(:release_forms).merge(release_forms_source.active.recently_signed)
  end

  private def release_forms_source
    Health::ReleaseForm
  end

  # SSM forms
  def expired_ssm_forms
    patient_source.joins(:recent_ssm_form).merge(
      ssm_forms_source.expired.
        where.not(patient_id: active_ssm_forms.select(:patient_id))
    ).distinct.
    preload(:recent_ssm_form)
  end

  def expiring_ssm_forms
    patient_source.joins(:recent_ssm_form).merge(
      ssm_forms_source.expiring_soon.
        where.not(patient_id: recently_completed_ssm_forms.select(:patient_id))
    ).distinct.
    preload(:recent_ssm_form)
  end

  private def active_ssm_forms
   patient_source.joins(:self_sufficiency_matrix_forms).merge(ssm_forms_source.active)
  end

  private def recently_completed_ssm_forms
   patient_source.joins(:self_sufficiency_matrix_forms).merge(ssm_forms_source.active.recently_signed)
  end

  private def ssm_forms_source
    Health::SelfSufficiencyMatrixForm
  end

  # CHA forms
  def expired_cha_forms
    patient_source.joins(:recent_cha_form).merge(
      cha_forms_source.expired.
        where.not(patient_id: active_cha_forms.select(:patient_id))
    ).distinct.
    preload(:recent_cha_form)
  end

  def expiring_cha_forms
    patient_source.joins(:recent_cha_form).merge(
      cha_forms_source.expiring_soon.
        where.not(patient_id: recently_completed_cha_forms.select(:patient_id))
    ).distinct.
    preload(:recent_cha_form)
  end

  private def active_cha_forms
   patient_source.joins(:comprehensive_health_assessments).merge(cha_forms_source.active)
  end

  private def recently_completed_cha_forms
   patient_source.joins(:comprehensive_health_assessments).merge(cha_forms_source.active.recently_signed)
  end

  private def cha_forms_source
    Health::ComprehensiveHealthAssessment
  end

  # PCTP forms
  def expired_pctp_forms
    patient_source.joins(:recent_pctp_form).merge(
      pctp_forms_source.expired.
        where.not(patient_id: active_pctp_forms.select(:patient_id))
    ).distinct.
    preload(:recent_pctp_form)
  end

  def expiring_pctp_forms
    patient_source.joins(:recent_pctp_form).merge(
      pctp_forms_source.expiring_soon.
        where.not(patient_id: recently_completed_pctp_forms.select(:patient_id))
    ).distinct.
    preload(:recent_pctp_form)
  end

  private def active_pctp_forms
   patient_source.joins(:careplans).merge(pctp_forms_source.active)
  end

  private def recently_completed_pctp_forms
   patient_source.joins(:careplans).merge(pctp_forms_source.active.recently_signed)
  end

  private def pctp_forms_source
    Health::Careplan
  end

  # Patient
  private def patient_source
    Health::Patient
  end
end
