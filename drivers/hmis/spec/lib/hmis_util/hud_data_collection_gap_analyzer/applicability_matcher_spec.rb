###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisUtil::HudDataCollectionGapAnalyzer::ApplicabilityMatcher do
  let(:hud) { HudHelper.util(HmisUtil::HudDataCollectionGapAnalyzer::HUD_VERSION) }
  # ES - Night-by-Night: the one project type HUD requires Bed Night collection for,
  # regardless of funder.
  let(:es_nbn_project_type) { 1 }
  let(:coc_sso_funder) { hud.funding_source('HUD: CoC - Supportive Services Only', true, raise_on_missing: true) }
  let(:path_funder) do
    hud.funding_source('HHS: PATH - Street Outreach & Supportive Services Only', true, raise_on_missing: true)
  end
  let(:bed_night_record_type) { hud.record_type('Bed Night', true, raise_on_missing: true) }
  let(:path_service_record_type) { hud.record_type('PATH Service', true, raise_on_missing: true) }

  def matcher_for(project_type:, funder_codes:)
    project = build(:hud_project, ProjectType: project_type)
    described_class.new(project: project, funder_codes: funder_codes)
  end

  describe '#current_living_situation_required?' do
    it 'is true for a funder-only rule regardless of project type' do
      # HUD: CoC - SSO has no project_type key, so it applies at every project type.
      # Project type 2 (ES Entry/Exit) is deliberately not one CLS rules name.
      matcher = matcher_for(project_type: 2, funder_codes: [coc_sso_funder])

      expect(matcher.current_living_situation_required?).to be(true)
    end

    it 'is false for a funder that appears in no CLS applicability entry' do
      coc_psh_funder = hud.funding_source('HUD: CoC - Permanent Supportive Housing', true, raise_on_missing: true)
      matcher = matcher_for(project_type: 2, funder_codes: [coc_psh_funder])

      expect(matcher.current_living_situation_required?).to be(false)
    end

    it 'is false when the project type does not match a rule that names one' do
      esg_es_funder = hud.funding_source(
        'HUD: ESG - Emergency Shelter (operating and/or essential services)',
        true,
        raise_on_missing: true,
      )
      # This funder's rule is scoped to ES NbN (1); at ES Entry/Exit (2) it must not match.
      matcher = matcher_for(project_type: 2, funder_codes: [esg_es_funder])

      expect(matcher.current_living_situation_required?).to be(false)
    end
  end

  describe '#required_service_record_types' do
    it 'includes Bed Night for an ES NbN project with no funders at all' do
      # The Bed Night rule is project-type-only, so it must match with an empty funder list.
      matcher = matcher_for(project_type: es_nbn_project_type, funder_codes: [])

      expect(matcher.required_service_record_types).to include(bed_night_record_type)
    end

    it 'includes PATH Service for a PATH-funded project at an unrelated project type' do
      matcher = matcher_for(project_type: 2, funder_codes: [path_funder])

      expect(matcher.required_service_record_types).to include(path_service_record_type)
    end

    it 'excludes PATH Service for a project that is not PATH funded' do
      matcher = matcher_for(project_type: 2, funder_codes: [coc_sso_funder])

      expect(matcher.required_service_record_types).not_to include(path_service_record_type)
    end

    it 'excludes Bed Night for a project that is not ES NbN' do
      matcher = matcher_for(project_type: 2, funder_codes: [path_funder])

      expect(matcher.required_service_record_types).not_to include(bed_night_record_type)
    end
  end
end
