# packages 
library(rvest)
library(dplyr)
library(geosphere)


# webscraping google sheet #####
link <- "https://docs.google.com/spreadsheets/d/e/2PACX-1vRHvr69sISXqaYL9DA0jeUl0TIe-OTXdSS7JgIQCfmL3jboMEEt7ZK-3L4hLPLeAuXw_y15xBSjD_hj/pubhtml?gid=0&single=true"

flight_log <- read_html(link) %>% 
  html_node("table") %>% 
  rvest::html_table() 

# remove first column
flight_log <- flight_log[,-1]
# add names to data frame
names(flight_log) <- flight_log[1,]
# remove first row
flight_log <- flight_log[-1,]
row.names(flight_log) <- NULL

flight_log_cleaned <- flight_log %>% 
  mutate(trip_no = as.integer(trip_no),
         depart_date = as.Date(depart_date, format = '%d/%m/%Y'),
         roundtrip_return_date = as.Date(roundtrip_return_date, format = '%d/%m/%Y')) %>% 
  filter(!is.na(trip_no)) 

write.csv(flight_log_cleaned, here::here('intermediate_data','flight_log_cleaned.csv'))


# creating list of airport lat long ####
latlong_vector <- mapply(function(y,z) list(c(y,z)), 
                         airports_only$latitude_deg, airports_only$longitude_deg)


names(latlong_vector) <- airports_only$iata_code
# calculate Great Circle Distance between airports in flight_log_cleaned ####

geosphere::distHaversine()


# calculate emissions ####


# (170 g CO2_eq per passenger per km)
# Reference: https://research.chalmers.se/publication/508693/file/508693_Fulltext.pdf


