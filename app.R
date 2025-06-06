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
    temp_file <- tempfile(fileext = ".qmd")
    writeLines(quarto_content, temp_file, useBytes = TRUE)

    # Render the Quarto document
    output_file <- tempfile(fileext = ".html")
    quarto::quarto_render(temp_file, output_file = output_file)

    # Display the Quarto source
    output$quarto_source <- renderText({
      quarto_content
    })

    # Display the rendered output
    output$quarto_output <- renderUI({
      includeHTML(output_file)
    })
  })
}

shinyApp(ui = ui, server = server)