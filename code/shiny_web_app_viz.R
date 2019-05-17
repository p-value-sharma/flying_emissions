# packages ####
library(plotly)
library(shiny)
library(dplyr)
library(rvest)
library(geosphere)
library(lubridate)

# load data ####
longlat_vector <- readRDS(file = here::here('intermediate_data', 'longlat_vector.RDS'))
departure_latlong <- read.csv(file = here::here('intermediate_data', 'departure_latlong.csv'), stringsAsFactors = F)
arrival_latlong <- read.csv(file = here::here('intermediate_data', 'arrival_latlong.csv'), stringsAsFactors = F)

default_url <- "https://docs.google.com/spreadsheets/d/e/2PACX-1vRHvr69sISXqaYL9DA0jeUl0TIe-OTXdSS7JgIQCfmL3jboMEEt7ZK-3L4hLPLeAuXw_y15xBSjD_hj/pubhtml?gid=0&single=true"

# I used https://xkcd.com/977/ to choose a map projection, which is to say I have no good reason
geo <- list(
  scope = 'world',
  projection = list(type = 'winkel tripel'),
  showland = TRUE,
  showcountries = TRUE,
  showocean = TRUE,
  landcolor = toRGB("gray95"),
  countrycolor = toRGB("gray80"),
  oceancolor = "#7fcdff"

)


# define UI ####
ui <- fluidPage(
  titlePanel("Flight emissions tracker"),
  sidebarLayout(
    sidebarPanel(
      fluidRow(
        column(12, wellPanel(
          urlInput(inputId = "my_url", label = "URL:", default_url),
          actionButton(inputId = "reset", label = "Reset to example URL"),
          tags$style(type='text/css', "#my_url { width:100%; }")
        ))),
      uiOutput("slider")
    ),
    mainPanel(
      # text on flights and summarized CO2eq emissions
      textOutput("selected_var"),
      plotlyOutput("plot", width = 800, height = 800, inline = T)
      )
  ))


inputPanel
# define server function ####
server <- function(input, output, session) {
  output$slider <- renderUI({sliderInput(inputId = "range", label = "Dates:",
                                     min = min(output$data$depart_date), max = max(output$data$depart_date),
                                     value = c(min(output$data$depart_date), max(output$data$depart_date)))})
  
  output$data <- reactive(data_for_viz_live <- scrapeGoogleSheet_form(link = input$my_url), label = 'data')
  
  output$plot <- renderPlotly({
    plot_geo(output$data) %>%
      add_segments(
        x = ~dep_long, xend = ~arriv_lon,
        y = ~dep_lat, yend = ~arriv_lat,
        alpha = 0.5, size = I(2), color = I("red"), 
        split = ~trip_no,
        text = ~ifelse(roundtrip == 'Yes',
                       paste0(formatC(tCO2_eq_kg*2, format = 'd', big.mark = ','), ' kg CO<sub>2</sub>eq',
                              '<br>', departure_airport, '↔', arrival_airport),           
                       paste0(formatC(tCO2_eq_kg, format = 'd', big.mark = ','), ' kg CO<sub>2</sub>eq',
                              '<br>', departure_airport, '→', arrival_airport)),
        hoverinfo = 'text'
      ) %>% 
      layout(
        showlegend = F,
        geo = geo,
        margin= list(l=0,r=0,b=0,t=0,pad=0)) 
  })
  observe({
    # Run whenever reset button is pressed
    input$reset
    
    # Send an update to my_url, resetting its value
    updateUrlInput(session, "my_url", 
                   value = default_url)
  })
}

# Create Shiny object ####
shinyApp(ui = ui, server = server)




# random ####

HTML(paste0('You took ', strong(paste0("X",' flights')), ' and')),
HTML(paste0('emitted ', strong(paste0("X",' kg CO')),tags$sub('2'), strong('eq')))


renderText()
render
