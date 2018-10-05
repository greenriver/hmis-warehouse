# require 'rserve/simpler'
require 'rinruby'
module Reporting
  class RrhReport

    attr_accessor :program_1_id, :program_2_id
    def initialize program_1_id:, program_2_id:
      self.program_1_id = program_1_id || ''
      self.program_2_id = program_2_id || ''
    end

    # mostly for debugging, allow external access
    def r
      R
    end

    def set_time_format
      # We need this for exporting to the appropriate format
      @default_date_format = Date::DATE_FORMATS[:default]
      @default_time_format = Time::DATE_FORMATS[:default]
      Date::DATE_FORMATS[:default] = "%Y-%m-%d"
      Time::DATE_FORMATS[:default] = "%Y-%m-%d %H:%M:%S"
    end

    def reset_time_format
      Date::DATE_FORMATS[:default] = @default_date_format
      Time::DATE_FORMATS[:default] = @default_time_format
    end

    def housed
      @housed ||= Reporting::Housed.all
    end

    def returns
      @returns ||= Reporting::Return.all
    end

    def num_housed_1
      @num_housed_1 ||= begin
        set_r_variables
        @num_housed_1
      end
    end
    def num_housed_2
      @num_housed_2 ||= begin
        set_r_variables
        @num_housed_2
      end
    end
    def housed_plot_1
      @housedPlot_1 ||= begin
        set_r_variables
        @housedPlot_1
      end
    end
    def housed_plot_2
      @housedPlot_2 ||= begin
        set_r_variables
        @housedPlot_2
      end
    end
    def time_to_housing_1
      @time_to_housing_1 ||= begin
        set_r_variables
        @time_to_housing_1
      end
    end
    def time_to_housing_2
      @time_to_housing_2 ||= begin
        set_r_variables
        @time_to_housing_2
      end
    end
    def time_in_housing_1
      @time_in_housing_1 ||= begin
        set_r_variables
        @time_in_housing_1
      end
    end
    def time_in_housing_2
      @time_in_housing_2 ||= begin
        set_r_variables
        @time_in_housing_2
      end
    end
    def success_failure_1
      @success_failure_1 ||= begin
        set_r_variables
        @success_failure_1
      end
    end
    def success_failure_2
      @success_failure_2 ||= begin
        set_r_variables
        @success_failure_2
      end
    end
    def ph_exits_1
      @ph_exits_1 ||= begin
        set_r_variables
        @ph_exits_1
      end
    end
    def shelter_exits_1
      @shelter_exits_1 ||= begin
        set_r_variables
        @shelter_exits_1
      end
    end
    def ph_exits_2
      @ph_exits_2 ||= begin
        set_r_variables
        @ph_exits_2
      end
    end
    def shelter_exits_2
      @shelter_exits_2 ||= begin
        set_r_variables
        @shelter_exits_2
      end
    end
    def return_1
      @return_1 ||= begin
        set_r_variables
        @return_1
      end
    end
    def return_2
      @return_2 ||= begin
        set_r_variables
        @return_2
      end
    end
    def return_length_1
      @return_length_1 ||= begin
        set_r_variables
        @return_length_1
      end
    end
    def return_length_2
      @return_length_2 ||= begin
        set_r_variables
        @return_length_2
      end
    end
    def demographic_plot_1
      @demographic_plot_1 ||= begin
        set_r_variables
        @demographic_plot_1
      end
    end
    def demographic_plot_2
      @demographic_plot_2 ||= begin
        set_r_variables
        @demographic_plot_2
      end
    end

    def length_of_time_buckets
      @length_of_time_buckets ||= {
        '(0,7]' => 'Less than 1 week',
        '(7,30]' => '1 week to one month',
        '(30,91]' => '1 month to 3 months',
        '(91,182]' => '3 months to 6 months',
        '(182,364]' => '3 months to 1 year',
        '(364,728]' => '1 year to 2 years',
        '(728,Inf]' => '2 years or more',
      }
    end

    def set_r_variables
      set_time_format
      housed_file = Tempfile.new('housed')
      CSV.open(housed_file, 'wb') do |csv|
        csv << housed.first.attributes.keys
        housed.each do |m|
          csv << m.attributes.values
        end
      end

      returns_file = Tempfile.new('returns')
      CSV.open(returns_file, 'wb') do |csv|
        csv << returns.first.attributes.keys
        returns.each do |m|
          csv << m.attributes.values
        end
      end

      R.program_1 = program_1_id
      R.program_2 = program_2_id
      # For debugging, an R REPL in a Ruby REPL!
      # R.prompt
      install_missing_r_packages()
      R.eval <<~REOF
        housed <- read.csv("#{housed_file.path}")

        housed$month_year <- as.Date(housed$month_year)
        housed$search_start <- as.Date(housed$search_start)
        housed$search_end <- as.Date(housed$search_end)
        housed$housed_date <- as.Date(housed$housed_date)
        housed$housing_exit <- as.Date(housed$housing_exit)
        housed$destination <- as.character(housed$destination)
        # print(housed)

        returns <- read.csv("#{returns_file.path}")

        returns$start_date <- as.Date(returns$start_date)
        returns$end_date <- as.Date(returns$end_date)
        # print(returns)

        if(program_1=='')
        {
          housed_1 <- housed
        } else
        {
          housed_1 <- housed %>% filter(project_id == program_1)
        }
        if(program_2=='')
        {
          housed_2 <- housed
        } else
        {
          housed_2 <- housed %>% filter(project_id == program_2)
        }

        # print(head(housed_1, n=5))
        # print(head(housed_2, n=5))

        #retrieve post-housing ES or SO records for clients housed through the first program
        first_housed_dates <- housed_1 %>%
          arrange(client_id, housing_exit) %>%
          group_by(client_id) %>%
          distinct(client_id, .keep_all=TRUE) %>%
          select(client_id, housing_exit)

        # print(head(first_housed_dates, n=5))

        services_with_housed_dates <- returns %>%
          filter(client_id %in% first_housed_dates$client_id) %>%
          left_join(first_housed_dates, on = c("client_id" = "client_id"))

        # print(head(services_with_housed_dates, n=5))
        # print(head(services_with_housed_dates$housing_exit, n=5))

        post_housing <- services_with_housed_dates %>%
          filter(start_date > housing_exit) %>%
          filter(project_type %in% c(1,2,4)) %>%
          arrange(client_id, start_date)

        # print(head(post_housing, n=5))

        post_housing <- post_housing[!is.na(post_housing$start_date),]
        post_housing <- post_housing[!is.na(post_housing$end_date),]

        l <- mapply(seq.Date, post_housing$start_date, post_housing$end_date, 1)
        df2 <- data.frame(group = rep(post_housing$client_id,sapply(l,length)),
                          dates = unlist(l))
        unique_dates = aggregate(dates ~ group, df2, function(x) length(unique(x)))
        post_housing = left_join(post_housing, unique_dates, by=c("client_id"="group"))
        post_housing %<>% mutate(
          adjusted_days_homeless = dates
        ) %>%
          select(-dates)
        post_housing_1 <- post_housing

        # print(head(post_housing_1, n=5))

        #retrieve post-housing ES or SO records for clients housed through the second program
        first_housed_dates <- housed_2 %>%
          arrange(client_id, housing_exit) %>%
          group_by(client_id) %>%
          distinct(client_id, .keep_all=TRUE) %>%
          select(client_id, housing_exit)

        # print(head(first_housed_dates, n=5))

        services_with_housed_dates <- returns %>%
          filter(client_id %in% first_housed_dates$client_id) %>%
          left_join(first_housed_dates, on = c("client_id" = "client_id"))

        post_housing <- services_with_housed_dates %>%
          filter(start_date > housing_exit) %>%
          filter(project_type %in% c(1,2,4)) %>%
          arrange(client_id, start_date)

        post_housing <- post_housing[!is.na(post_housing$start_date),]
        post_housing <- post_housing[!is.na(post_housing$end_date),]
        l <- mapply(seq.Date, post_housing$start_date, post_housing$end_date, 1)
        df2 <- data.frame(group = rep(post_housing$client_id,sapply(l,length)),
                          dates = unlist(l))
        unique_dates = aggregate(dates ~ group, df2, function(x) length(unique(x)))
        post_housing = left_join(post_housing, unique_dates, by=c("client_id"="group"))
        post_housing %<>% mutate(
          adjusted_days_homeless = dates
        ) %>%
          select(-dates)
        post_housing_2 <-post_housing

        # print(head(post_housing_2, n=5))

        #number housed
        num_housed_1 <- paste(length(unique(housed_1$client_id)), "total clients", sep=" ")
        num_housed_2 <- paste(length(unique(housed_2$client_id)), "total clients", sep=" ")
      REOF
      R.eval <<~REOF
        # print(num_housed_1)
        # print(num_housed_2)

        housedPlot_1 <- as.character(toJSON(housed_1 %>%
          arrange(desc(housed_date)) %>%
          group_by(month_year) %>%
          summarise(
          n_clients = n_distinct(client_id)
          ) %>%
          mutate(
            cumsum = cumsum(n_clients)
          ) %>%
          filter(month_year > as.Date('2012-01-01')) %>%
          filter(month_year < as.Date('2018-08-01'))))

        # print(housedPlot_1)

        housedPlot_2 <- as.character(toJSON(housed_2 %>%
          arrange(desc(housed_date)) %>%
          group_by(month_year) %>%
          summarise(
            n_clients = n_distinct(client_id)
          ) %>%
          mutate(
            cumsum = cumsum(n_clients)
          ) %>%
          filter(month_year > as.Date('2012-01-01')) %>%
          filter(month_year < as.Date('2018-08-01'))))

        # print(housedPlot_2)

        time_to_housing_1 <- paste(round(mean(housed_1$search_end - housed_1$search_start, na.rm=TRUE), digits=2), "days to find housing", sep=" ")

        time_to_housing_2 <- paste(round(mean(housed_2$search_end - housed_2$search_start, na.rm = TRUE), digits = 2), "days to find housing", sep=" ")

        time_in_housing_1 <- paste(round(mean(housed_1$housing_exit - housed_1$housed_date, na.rm = TRUE), digits = 2), "days in program", sep=" ")

        time_in_housing_2 <- paste(round(mean(housed_2$housing_exit - housed_2$housed_date, na.rm = TRUE), digits = 2), "days in program", sep=" ")
      REOF
      R.eval <<~REOF
        success_failure_1 <- as.character(toJSON(rbind(housed_1 %>%
          filter(ph_destination=='ph') %>%
          distinct(client_id) %>%
          filter(!client_id %in% post_housing_1$client_id) %>%
          mutate(
            outcome = 'successful exit to PH'
          ),
        #clients that ended up back in shelter
        post_housing_1 %>%
          distinct(client_id) %>%
          mutate(
            outcome = 'returned to shelter'
          ),
        #clients that exited to an unknown destination and did not return to shelter
        housed_1 %>%
          filter(!is.na(housing_exit)) %>%
          filter(is.na(destination)) %>%
          filter(!client_id %in% post_housing_1$client_id) %>%
          distinct(client_id) %>%
          mutate(
            outcome = 'unknown outcome'
          ),
        #clients that exited to other institutions and never came back to shelter
        housed_1 %>%
          filter(!is.na(housing_exit)) %>%
          filter(destination != '1') %>%
          filter(destination != '16') %>%
          filter(ph_destination != 'ph') %>%
          filter(!client_id %in% post_housing_1$client_id) %>%
          distinct(client_id) %>%
          mutate(
            outcome = 'exited to other institution'
          ) )%>%
          group_by(outcome) %>%
          summarise(
            count = n_distinct(client_id)
          )))

        success_failure_2 <- as.character(toJSON(rbind(housed_2 %>%
          filter(ph_destination=='ph') %>%
          distinct(client_id) %>%
          filter(!client_id %in% post_housing_2$client_id) %>%
          mutate(
            outcome = 'successful exit to PH'
          ),
        #clients that ended up back in shelter
        post_housing_2 %>%
          distinct(client_id) %>%
          mutate(
            outcome = 'returned to shelter'
          ),
        #clients that exited to an unknown destination and did not return to shelter
        housed_2 %>%
          filter(!is.na(housing_exit)) %>%
          filter(is.na(destination)) %>%
          filter(!client_id %in% post_housing_2$client_id) %>%
          distinct(client_id) %>%
          mutate(
            outcome = 'unknown outcome'
          ),
        #clients that exited to other institutions and never came back to shelter
        housed_2 %>%
          filter(!is.na(housing_exit)) %>%
          filter(destination != '1') %>%
          filter(destination != '16') %>%
          filter(ph_destination != 'ph') %>%
          filter(!client_id %in% post_housing_2$client_id) %>%
          distinct(client_id) %>%
          mutate(
            outcome = 'exited to other institution'
          ))  %>%
            group_by(outcome) %>%
            summarise(
              count = n_distinct(client_id)
            )))
        # print(success_failure_2)

        # exits to PH and shelter
        ph_exits_1 <- paste(length(unique(housed_1$client_id[housed_1$ph_destination=="ph"])), "clients (", percent(length(housed_1$client_id[housed_1$ph_destination=="ph"])/length(housed_1$client_id[!is.na(housed_1$housing_exit)])), ") exited to permanent housing", sep=" ")

        shelter_exits_1 <- paste(length(unique(housed_1$client_id[housed_1$destination %in% c('1')])), "clients (", percent(length(housed_1$client_id[housed_1$destination %in% c('1')])/length(housed_1$client_id[!is.na(housed_1$housing_exit)])), ") exited to Shelter", sep=" ")


        ph_exits_2 <- paste(length(unique(housed_2$client_id[housed_2$ph_destination=="ph"])), "clients (", percent(length(housed_2$client_id[housed_2$ph_destination=="ph"])/length(housed_2$client_id[!is.na(housed_2$housing_exit)])), ") exited to permanent housing", sep=" ")


        shelter_exits_2 <- paste(length(unique(housed_2$client_id[housed_2$destination %in% c('1')])), "clients (", percent(length(housed_2$client_id[housed_2$destination %in% c('1')])/length(housed_2$client_id[!is.na(housed_2$housing_exit)])), ") exited to Shelter", sep=" ")


        # # returns to shelter from PH exits
        post_ph_return = post_housing_1[post_housing_1$client_id %in% housed_1$client_id[housed_1$ph_destination=='ph'],]
        return_1 <- paste(length(unique(post_ph_return$client_id)), " (", percent(length(unique(post_ph_return$client_id))/length(unique(housed_1$client_id[housed_1$ph_destination=="ph"]))), ") clients returned to shelter", sep="")

        post_housing_1[post_housing_1$client_id %in% housed_1$client_id[housed_1$ph_destination=='ph'],]
        return_length_1 <- as.character(toJSON(post_housing_1 %>% distinct(client_id, .keep_all=TRUE) %>%
         select(client_id, adjusted_days_homeless) %>%
         transform(Discrete=cut(as.numeric(adjusted_days_homeless),
                                breaks = c(0, 7, 30, 91,182, 364, 728, Inf))) %>%
         group_by(Discrete) %>%
         summarise(
           clients = n_distinct(client_id)
         )))

        post_ph_return = post_housing_2[post_housing_2$client_id %in% housed_2$client_id[housed_2$ph_destination=='ph'],]
        return_2 <- paste(length(unique(post_ph_return$client_id)), " (", percent(length(unique(post_ph_return$client_id))/length(unique(housed_2$client_id[housed_2$ph_destination=="ph"]))), ") clients returned to shelter", sep="")
        return_length_2 <- as.character(toJSON(post_housing_1 %>% distinct(client_id, .keep_all=TRUE) %>%
         select(client_id, adjusted_days_homeless) %>%
         transform(Discrete=cut(as.numeric(adjusted_days_homeless),
                                breaks = c(0, 7, 30, 91,182, 364, 728, Inf))) %>%
         group_by(Discrete) %>%
         summarise(
           clients = n_distinct(client_id)
         )))


        demographic_plot_1 <-  as.character(toJSON(rbind(housed_1 %>%
         group_by(
           race
         ) %>%
         summarise(
           count = n_distinct(client_id)
         ) %>%
         mutate(
           freq = count / sum(count),
           type='full-population'
         ),
         housed_1 %>%
           filter(ph_destination=="ph") %>%
           group_by(
             race
           ) %>%
           summarise(
             count = n_distinct(client_id)
           ) %>%
           mutate(
             freq = count / sum(count),
             type='housed'
           )
         )))

         demographic_plot_2 <- as.character(toJSON(rbind(housed_2 %>%
          group_by(
            race
          ) %>%
          summarise(
            count = n_distinct(client_id)
          ) %>%
          mutate(
            freq = count / sum(count),
            type='full-population'
          ),
        housed_2 %>%
          filter(ph_destination=="ph") %>%
          group_by(
            race
          ) %>%
          summarise(
            count = n_distinct(client_id)
          ) %>%
          mutate(
            freq = count / sum(count),
            type='housed'
          ))))
      REOF

      housed_file.close
      housed_file.unlink
      returns_file.close
      returns_file.unlink
      reset_time_format

      @num_housed_1 = R.num_housed_1
      @num_housed_2 = R.num_housed_2
      @housedPlot_1 = JSON.parse R.housedPlot_1
      @housedPlot_2 = JSON.parse R.housedPlot_2
      @time_to_housing_1 = R.time_to_housing_1 || 'unknown days to find housing' # prevent re-running if we receive no answer
      @time_to_housing_2 = R.time_to_housing_2 || 'unknown days to find housing'
      @time_in_housing_1 = R.time_in_housing_1 || 'unknown days in find housing'
      @time_in_housing_2 = R.time_in_housing_2 || 'unknown days in find housing'
      @success_failure_1 = JSON.parse R.success_failure_1
      @success_failure_2 = JSON.parse R.success_failure_2
      @ph_exits_1 = R.ph_exits_1
      @shelter_exits_1 = R.shelter_exits_1
      @ph_exits_2 = R.ph_exits_2
      @shelter_exits_2 = R.shelter_exits_2
      @return_1 = R.return_1
      @return_2 = R.return_2
      @return_length_1 = begin
        (JSON.parse R.return_length_1).map do |row|
          row[:discrete] = length_of_time_buckets.try(:[], row['Discrete']) || row['Discrete']
          row[:count] = row['clients']
          row
        end
      rescue
        []
      end
      @return_length_2 = begin
        (JSON.parse R.return_length_2).map do |row|
          row[:discrete] = length_of_time_buckets.try(:[], row['Discrete']) || row['Discrete']
          row[:count] = row['clients']
          row
        end
      rescue
        []
      end
      @demographic_plot_1 = JSON.parse R.demographic_plot_1
      @demographic_plot_2 = JSON.parse R.demographic_plot_2

    end

    def install_missing_r_packages
      R.eval <<~REOF
        list.of.packages <- c("lubridate", "dplyr", "magrittr", "scales", "jsonlite")
        new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
        if(length(new.packages)) install.packages(new.packages)
        library(lubridate)
        require(dplyr)
        require(magrittr)
        require(scales)
        library(jsonlite)
      REOF
    end
  end
end