module HealthCareplan
  extend ActiveSupport::Concern

  included do
    def set_careplan
      careplan_id = params[:careplan_id].presence || params[:id]
      @careplan = careplan_source.find(careplan_id.to_i)
    end

    def set_medications
      @medications = @patient.medications.order(start_date: :desc, ordered_date: :desc)
    end

    def set_problems
      @problems = @patient.problems.order(onset_date: :desc)
    end

    def careplan_source
      Health::Careplan
    end

    # The logic for creating the CarePlan PDF is fairly complicated and needs to be used in both the careplan controllers and the signable document controllers
    def careplan_combine_pdf_object
      @goal = Health::Goal::Base.new
      @readonly = false
      file_name = 'care_plan'
      # make sure we have the most recent-services, DME, team members, and goals if
      # the plan is editable
      if @careplan.editable?
        @careplan.archive_services
        @careplan.archive_equipment
        @careplan.archive_goals
        @careplan.archive_team_members
        @careplan.save
      end

      # Include most-recent SSM & CHA
      # @form = @patient.self_sufficiency_matrix_forms.recent.first
      @form = @patient.ssms.last
      if @form.is_a? Health::SelfSufficiencyMatrixForm
        @ssm_partial = 'window/health/self_sufficiency_matrix_forms/show'
      elsif @form.is_a? GrdaWarehouse::HmisForm
        @ssm_partial = 'clients/assessment_form'
      end
      @cha = @patient.comprehensive_health_assessments.recent.first
      # debugging
      # render layout: false

      # render(
      #   pdf: file_name,
      #   layout: false,
      #   encoding: "UTF-8",
      #   page_size: 'Letter',
      #   header: { html: { template: 'window/health/careplans/_pdf_header' }, spacing: 1 },
      #   footer: { html: { template: 'window/health/careplans/_pdf_footer'}, spacing: 5 },
      #   # Show table of contents by providing the 'toc' property
      #   # toc: {}
      # )

      pctp = render_to_string(
        pdf: file_name,
        template: 'window/health/careplans/show',
        layout: false,
        encoding: "UTF-8",
        page_size: 'Letter',
        header: { html: { template: 'window/health/careplans/_pdf_header' }, spacing: 1 },
        footer: { html: { template: 'window/health/careplans/_pdf_footer'}, spacing: 5 },
        # Show table of contents by providing the 'toc' property
        # toc: {}
      )
      pdf = CombinePDF.parse(pctp)

      if @careplan.health_file.present?
        pdf << CombinePDF.parse(@careplan.health_file.content)
      end
      if @form.present? && @form.is_a?(Health::SelfSufficiencyMatrixForm) && @form.health_file.present?
        pdf << CombinePDF.parse(@form.health_file.content)
      end
      if @cha.present? && @cha.health_file.present? && @cha.health_file.content_type == 'application/pdf'
        pdf << CombinePDF.parse(@cha.health_file.content)
      end
      return pdf
    end
  end
end
