library(lubridate)
require(dplyr)
require(magrittr)
require(scales)
library(jsonlite)

housed <- read.csv(housed_file_path, na.strings=c("","NA"))
housed$month_year <- as.Date(housed$month_year)
housed$search_start <- as.Date(housed$search_start)
housed$search_end <- as.Date(housed$search_end)
housed$housed_date <- as.Date(housed$housed_date)
housed$housing_exit <- as.Date(housed$housing_exit)
housed$destination <- as.character(housed$destination)

# print(housed$housing_exit)
returns <- read.csv(returns_file_path, na.strings=c("","NA"))

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

# print(head(housed_1, n=5))

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
  filter(as.Date(start_date) > as.Date(housing_exit)) %>%
  filter(project_type %in% c(1,2,4)) %>%
  arrange(client_id, start_date)

# print(head(post_housing, n=5))

# print(post_housing)

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

#number housed
num_housed_1 <- paste(length(unique(housed_1$client_id)), "total clients", sep=" ")

# print(num_housed_1)

housedPlot_1 <- as.character(toJSON(housed_1 %>%
  arrange(desc(housed_date)) %>%
  group_by(month_year) %>%
  summarise(
  n_clients = n_distinct(client_id)
  ) %>%
  mutate(
    cumsum = cumsum(n_clients)
  ) %>%
  filter(as.Date(month_year) > as.Date('2012-01-01')) %>%
  filter(as.Date(month_year) < as.Date('2018-08-01'))))


time_to_housing_1 <- paste(round(mean(as.Date(housed_1$search_end) - as.Date(housed_1$search_start), na.rm=TRUE), digits=2), "days to find housing", sep=" ")

time_in_housing_1 <- paste(round(mean(as.Date(housed_1$housing_exit) - as.Date(housed_1$housed_date), na.rm = TRUE), digits = 2), "days in program", sep=" ")


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

# exits to PH and shelter
ph_exits_1 <- paste(length(unique(housed_1$client_id[housed_1$ph_destination=="ph"])), "clients (", percent(length(housed_1$client_id[housed_1$ph_destination=="ph"])/length(housed_1$client_id[!is.na(housed_1$housing_exit)])), ") exited to permanent housing", sep=" ")

shelter_exits_1 <- paste(length(unique(housed_1$client_id[housed_1$destination %in% c('1')])), "clients (", percent(length(housed_1$client_id[housed_1$destination %in% c('1')])/length(housed_1$client_id[!is.na(housed_1$housing_exit)])), ") exited to Shelter", sep=" ")


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