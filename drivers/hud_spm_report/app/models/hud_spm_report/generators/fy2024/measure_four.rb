###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Measure 2a and 2b: The Extent to which Persons Who Exit Homelessness
# to Permanent Housing Destinations Return to Homelessness within 6, 12,
# and 24 months.
module HudSpmReport::Generators::Fy2024
  class MeasureFour < MeasureBase
    def self.question_number
      'Measure 4'.freeze
    end

    def self.table_descriptions
      {
        'Measure 4' => 'Employment and Income Growth for Homeless Persons in CoC Program-funded Projects',
        '4.1' => 'Change in earned income for adult system stayers during the reporting period',
        '4.2' => 'Change in non-employment cash income for adult system stayers during the reporting period',
        '4.3' => 'Change in total income for adult system stayers during the reporting period',
        '4.4' => 'Change in earned income for adult system leavers',
        '4.5' => 'Change in non-employment cash income for adult system leavers',
        '4.6' => 'Change in total income for adult system leavers',
      }.freeze
    end

    def run_question!
      tables = [
        ['4.1', :run_4_1],
        ['4.2', :run_4_2],
        ['4.3', :run_4_3],
        ['4.4', :run_4_4],
        ['4.5', :run_4_5],
        ['4.6', :run_4_6],
      ]

      @report.start(self.class.question_number, tables.map(&:first))

      tables.each do |name, msg|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    COLUMNS = {
      'B' => 'Previous FY',
      'C' => 'Current FY',
      'D' => 'Difference',
    }.freeze

    private def run_4_1(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Number of adults (system stayers)',
          3 => 'Number of adults with increased earned income',
          4 => 'Percentage of adults who increased earned income',
        },
        COLUMNS,
      )
    end

    private def run_4_2(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Number of adults (system stayers)',
          3 => 'Number of adults with increased non-employment cash income',
          4 => 'Percentage of adults who increased non-employment cash income',
        },
        COLUMNS,
      )
    end

    private def run_4_3(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Number of adults (system stayers)',
          3 => 'Number of adults with increased total income',
          4 => 'Percentage of adults who increased total income',
        },
        COLUMNS,
      )
    end

    private def run_4_4(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Number of adults who exited (system leavers)',
          3 => 'Number of adults who exited with increased earned income',
          4 => 'Percentage of adults who increased earned income',
        },
        COLUMNS,
      )
    end

    private def run_4_5(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Number of adults who exited (system leavers)',
          3 => 'Number of adults who exited with increased non-employment cash income',
          4 => 'Percentage of adults who increased non-employment cash income',
        },
        COLUMNS,
      )
    end

    private def run_4_6(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Number of adults who exited (system leavers)',
          3 => 'Number of adults who exited with increased total income',
          4 => 'Percentage of adults who increased total income',
        },
        COLUMNS,
      )
    end
  end
end
