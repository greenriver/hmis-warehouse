###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class TeamMembersController < IndividualPatientController
    include AjaxModalRails::Controller
    include ClientPathGenerator
    include HealthTeamMember

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_careplan
    before_action :set_deleted_team_member, only: [:restore]

    def after_path
      polymorphic_path([:edit] + careplan_path_generator, id: @careplan)
    end

    def team_member_form_path
      if @member.new_record?
        polymorphic_path(careplan_path_generator + [:team, :members])
      else
        polymorphic_path(careplan_path_generator + [:team, :member], id: @member.id)
      end
    end
    helper_method :team_member_form_path

    def set_careplan
      @careplan = careplan_source.find(params[:careplan_id].to_i)
    end

    def careplan_source
      Health::Careplan
    end

    def flash_interpolation_options
      { resource_name: 'Team Member' }
    end

    protected def title_for_show
      "#{@client.name} - Health - Team"
    end
  end
end
