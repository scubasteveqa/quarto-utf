library(shiny)
library(quarto)

ui <- fluidPage(
  titlePanel("UTF-8 Character Display"),
  sidebarLayout(
    sidebarPanel(
      textInput("utf8_input", "Enter UTF-8 characters:", 
                value = "Hello 你好 こんにちは Привет 안녕하세요 🌍 👋"),
      actionButton("render_btn", "Generate Quarto Document")
    ),
    mainPanel(
      h3("Generated Document"),
      verbatimTextOutput("quarto_source"),
      tags$hr(),
      h3("Rendered Output"),
      uiOutput("quarto_output")
    )
  )
)

server <- function(input, output, session) {
  
  # Generate the Quarto document when button is clicked
  observeEvent(input$render_btn, {
    # Create temporary directory for Quarto files
    temp_dir <- tempfile("quarto_")
    dir.create(temp_dir)
    
    # Create the Quarto document content
    quarto_content <- paste0(
      "---\n",
      "title: \"UTF-8 Character Display\"\n",
      "format: html\n",
      "engine: knitr\n",
      "---\n\n",
      "## Raw UTF-8 Characters\n\n",
      "```{=html}\n",
      "<pre style=\"font-family: monospace; white-space: pre-wrap;\"><code>", 
      input$utf8_input,
      "</code></pre>\n",
      "```\n\n",
      "## Using `cat()` function\n\n",
      "```{r, echo=FALSE}\n",
      "cat(\"", gsub("\"", "\\\\\"", input$utf8_input), "\")\n",
      "```\n\n",
      "## Using hexadecimal representation\n\n",
      "```{r, echo=FALSE}\n",
      "chars <- strsplit(\"", gsub("\"", "\\\\\"", input$utf8_input), "\", \"\")[[1]]\n",
      "hex_values <- sapply(chars, function(c) {\n",
      "  paste0(\"U+\", toupper(as.hexmode(utf8ToInt(c))))\n",
      "})\n",
      "data.frame(Character = chars, `Unicode Hex` = hex_values)\n",
      "```\n"
    )
    
    # Write to temporary file
    input_file <- file.path(temp_dir, "document.qmd")
    writeLines(quarto_content, input_file, useBytes = TRUE)
    
    # Set working directory to temp_dir
    old_wd <- getwd()
    setwd(temp_dir)
    
    # Render the Quarto document without specifying an output path
    tryCatch({
      quarto::quarto_render("document.qmd")
      
      # Display the Quarto source
      output$quarto_source <- renderText({
        quarto_content
      })
      
      # Display the rendered output
      output$quarto_output <- renderUI({
        includeHTML(file.path(temp_dir, "document.html"))
      })
    }, 
    error = function(e) {
      message("Error rendering Quarto document: ", e$message)
      output$quarto_output <- renderUI({
        tags$div(
          tags$h4("Error rendering Quarto document:"),
          tags$pre(e$message)
        )
      })
    }, 
    finally = {
      # Restore working directory
      setwd(old_wd)
    })
  })
}

shinyApp(ui = ui, server = server)
