###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthCareplan
  extend ActiveSupport::Concern
  include ApplicationHelper

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

    def careplan_pdf_coversheet
      file_name = 'care_plan_coversheet'
      coversheet = render_to_string(
        pdf: file_name,
        template: 'health/careplans/_pdf_coversheet',
        layout: false,
        encoding: 'UTF-8',
      )
      grover_options = {
        display_url: root_url,
        displayHeaderFooter: false,
        timeout: 50_000,
        format: 'Letter',
        emulate_media: 'print',
        style_tag_options: [{ content: inline_stylesheet_link_tag('print'), media: 'print' }],
        margin: {
          top: '.5in',
          bottom: '.5in',
          left: '.4in',
          right: '.4in',
        },
        wait_until: 'networkidle0',
        print_background: true,
      }
      coversheet = "<html><head><meta charset='UTF-8' /></head><body>#{coversheet}</body></html>"
      CombinePDF.parse(Grover.new(coversheet, grover_options).to_pdf, allow_optional_content: true)
    end

    def careplan_pdf_full
      file_name = 'care_plan'
      pctp = render_to_string(
        pdf: file_name,
        template: 'health/careplans/show',
        layout: false,
        encoding: 'UTF-8',
      )
      header = render_to_string(
        template: 'health/careplans/_pdf_header',
        layout: false,
      )
      footer = render_to_string(
        template: 'health/careplans/_pdf_footer',
        layout: false,
      )
      grover_options = {
        display_url: root_url,
        display_header_footer: true,
        header_template: header,
        footer_template: footer,
        timeout: 50_000,
        format: 'Letter',
        emulate_media: 'print',
        style_tag_options: [{ content: inline_stylesheet_link_tag('print') }],
        margin: {
          top: '1.5in',
          bottom: '1.5in',
          left: '.4in',
          right: '.4in',
        },
        wait_until: 'networkidle0',
        print_background: true,
      }
      pctp = "<html><head><meta charset='UTF-8' /></head><body>#{pctp}</body></html>"
      CombinePDF.parse(Grover.new(pctp, grover_options).to_pdf, allow_optional_content: true)
    end

    def careplan_pdf_pctp
      file_name = 'care_plan_pctp'
      pctp = render_to_string(
        pdf: file_name,
        template: 'health/careplans/pctp_only',
        layout: false,
        encoding: 'UTF-8',
      )
      header = render_to_string(
        template: 'health/careplans/_pdf_header',
        layout: false,
      )
      footer = render_to_string(
        template: 'health/careplans/_pdf_footer',
        layout: false,
      )
      grover_options = {
        display_url: root_url,
        display_header_footer: true,
        header_template: header,
        footer_template: footer,
        timeout: 50_000,
        format: 'Letter',
        emulate_media: 'print',
        style_tag_options: [{ content: inline_stylesheet_link_tag('print') }],
        margin: {
          top: '1.5in',
          bottom: '1.5in',
          left: '.4in',
          right: '.4in',
        },
        wait_until: 'networkidle0',
        print_background: true,
      }
      pctp = "<html><head><meta charset='UTF-8' /></head><body>#{pctp}</body></html>"
      CombinePDF.parse(Grover.new(pctp, grover_options).to_pdf, allow_optional_content: true)
    end

    # The logic for creating the CarePlan PDF is fairly complicated and needs to be used in both the careplan controllers and the signable document controllers
    def careplan_combine_pdf_object
      @goal = Health::Goal::Base.new
      @readonly = false
      # If we already have a document with a signature, use that to try and avoid massive duplication
      if (health_file_id = @careplan.most_appropriate_pdf_id)
        if (health_file = Health::HealthFile.find(health_file_id))
          return CombinePDF.parse(health_file.content, allow_optional_content: true)
        end
      end
      # If we haven't sent this for signatures, build out the PDF
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
        @ssm_partial = 'health/self_sufficiency_matrix_forms/show'
      elsif @form.is_a? GrdaWarehouse::HmisForm
        @ssm_partial = 'clients/assessment_form'
      end
      @cha = @patient.comprehensive_health_assessments.recent.first

      pdf = CombinePDF.new

      pdf << careplan_pdf_coversheet

      # debugging
      # render layout: false

      # render(
      #   pdf: file_name,
      #   layout: false,
      #   encoding: "UTF-8",
      #   page_size: 'Letter',
      #   header: { html: { template: 'health/careplans/_pdf_header' }, spacing: 1 },
      #   footer: { html: { template: 'health/careplans/_pdf_footer'}, spacing: 5 },
      #   # Show table of contents by providing the 'toc' property
      #   # toc: {}
      # )

      pdf << careplan_pdf_full

      pdf << CombinePDF.parse(@careplan.health_file.content, allow_optional_content: true) if @careplan.health_file.present?
      pdf << CombinePDF.parse(@cha.health_file.content, allow_optional_content: true) if @cha.present? && @cha.health_file.present? && @cha.health_file.content_type == 'application/pdf'
      pdf << CombinePDF.parse(@form.health_file.content, allow_optional_content: true) if @form.present? && @form.is_a?(Health::SelfSufficiencyMatrixForm) && @form.health_file.present?
      pdf
    end
  end
end
