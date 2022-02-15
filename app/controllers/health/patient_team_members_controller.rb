###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class PatientTeamMembersController < IndividualPatientController
    include AjaxModalRails::Controller
    include ClientPathGenerator
    include HealthTeamMember

    before_action :set_client

    def index
      @team_members = @client.patient.team_members
    end

    def after_path
      polymorphic_path(team_members_path_generator)
    end

    def team_member_form_path
      if @member.new_record?
        polymorphic_path(team_members_path_generator)
      else
        polymorphic_path(team_member_path_generator, id: @member.id)
      end
    end
    helper_method :team_member_form_path

    protected def title_for_show
      "#{@client.name} - Health - Team"
    end
  end
end
