library(shiny)
library(bslib)
library(reticulate)
library(telegram.bot)
library(magrittr)

py_install(c('pytube'))

# Define UI for the application
ui <- page_navbar(
  title = "Youtube Downloader",
  nav_spacer(),
  nav_item(
    input_dark_mode(id = "dark_mode", mode = "light")),
  sidebarLayout(
    sidebarPanel(
      textInput("LINK", "Youtube Link", placeholder = "Paste Youtube Link"),
      actionButton("submit", label = "Download audio and Send")
    ),
    mainPanel(
      textOutput("status_output")
    )
  )
)

# Define server logic
server <- function(input, output) {
  
  # Use reticulate to import the pytube library
  pytube <- import("pytube")
  
  # Function to download and send the mp3 file
  download_and_send <- function(yt_url) {
    tryCatch({
      # Download mp3
      yt <- pytube$YouTube(yt_url)
      audio_stream <- yt$streams$filter(only_audio = TRUE)$first()
      audio_stream$download()
      
      # Send mp3 file via Telegram
      credentials <- read.csv("Telegram_credentials.csv")
      bot <- Bot(token = credentials[1, "token"])
      
      files <- list.files()
      mp3_file <- files[grepl("\\.mp4$", files)]
      
      bot$sendAudio(
        chat_id = credentials[1, "chat_ID"],
        audio = mp3_file,
        caption = "YT video"
      )
      
      # Delete files to save space
      file.remove(mp3_file)
      
      output$status_output <- renderText("MP3 file sent successfully!")
    }, error = function(e) {
      output$status_output <- renderText("Error: Unable to download or send the YouTube video.")
    })
  }
  
  # Event handler for the submit button
  observeEvent(input$submit, {
    yt_link <- input$LINK
    download_and_send(yt_link)
  })
  
}

# Run the application
shinyApp(ui = ui, server = server)