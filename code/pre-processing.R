# importing raw airport code data
airports_raw <- read.csv(file = here::here('raw_data', 'airports.csv'), stringsAsFactors = F)

airports_only <- subset(x = airports_raw, 
                        # want airports with valid IATA codes
                        grepl('airport', type) & nchar(iata_code) > 2)

write.csv(airports_only, file = here::here('intermediate_data', 'airports_only.csv'), row.names = F)
