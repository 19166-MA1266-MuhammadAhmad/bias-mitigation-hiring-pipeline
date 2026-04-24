library(shiny)
library(DT)
library(dplyr)
library(readr)
library(ggplot2)

ui <- fluidPage(
  titlePanel("Bias Mitigation Dashboard — AI Hiring"),
  tabsetPanel(
    # --- Tab 1: Model Performance ---
    tabPanel("Model Performance",
      br(),
      h4("Performance Metrics (Test Set)"),
      DTOutput("perf_table"),
      br(),
      h4("Accuracy Comparison"),
      plotOutput("acc_plot", height = "350px")
    ),

    # --- Tab 2: Fairness Metrics ---
    tabPanel("Fairness Metrics",
      br(),
      h4("Fairness Evaluation (All Models)"),
      DTOutput("fair_table"),
      br(),
      h4("Bias Reduction Summary"),
      DTOutput("reduction_table"),
      br(),
      fluidRow(
        column(6, h4("Demographic Parity: Baseline vs Mitigated"),
                  plotOutput("dpd_plot", height = "320px")),
        column(6, h4("Calibration: Baseline vs Mitigated"),
                  plotOutput("cal_plot", height = "320px"))
      )
    ),

    # --- Tab 3: Before/After Comparison ---
    tabPanel("Before / After",
      br(),
      h4("Fairness Improvement by Dataset"),
      selectInput("cmp_dataset", "Dataset",
                  choices = c("Dataset 1", "Dataset 2", "Dataset 3")),
      fluidRow(
        column(6, h4("Baseline RF"), DTOutput("before_table")),
        column(6, h4("Best Mitigated"), DTOutput("after_table"))
      ),
      br(),
      plotOutput("before_after_plot", height = "350px")
    ),

    # --- Tab 4: Prediction ---
    tabPanel("Predict",
      br(),
      sidebarLayout(
        sidebarPanel(
          selectInput("pred_dataset", "Dataset",
                      choices = c("Dataset 1", "Dataset 2", "Dataset 3")),
          conditionalPanel(
            condition = "input.pred_dataset == 'Dataset 1'",
            numericInput("d1_gender", "Gender (0=Female, 1=Male)", value = 0, min = 0, max = 1),
            numericInput("d1_cgpa", "CGPA", value = 3.0, min = 0, max = 4, step = 0.1),
            numericInput("d1_exp", "Experience Years", value = 2, min = 0, max = 20),
            numericInput("d1_skills", "Skills Score", value = 70, min = 0, max = 100),
            numericInput("d1_interview", "Interview Score", value = 70, min = 0, max = 100)
          ),
          conditionalPanel(
            condition = "input.pred_dataset == 'Dataset 2'",
            numericInput("d2_age", "Age", value = 30, min = 18, max = 65),
            numericInput("d2_gender", "Gender (0=Female, 1=Male)", value = 0, min = 0, max = 1),
            numericInput("d2_edu", "Education Level (1-4)", value = 2, min = 1, max = 4),
            numericInput("d2_exp", "Experience Years", value = 5, min = 0, max = 40),
            numericInput("d2_prev", "Previous Companies", value = 2, min = 0, max = 10),
            numericInput("d2_dist", "Distance from Company", value = 20, min = 0, max = 100),
            numericInput("d2_interview", "Interview Score", value = 60, min = 0, max = 100),
            numericInput("d2_skill", "Skill Score", value = 60, min = 0, max = 100),
            numericInput("d2_personality", "Personality Score", value = 50, min = 0, max = 100),
            numericInput("d2_recruit", "Recruitment Strategy (1-3)", value = 1, min = 1, max = 3)
          ),
          conditionalPanel(
            condition = "input.pred_dataset == 'Dataset 3'",
            selectInput("d3_age", "Age Group",
                        choices = c("18-24", "25-34", "35-44", "45-54", "55-64", "65+")),
            selectInput("d3_edlevel", "Education Level",
                        choices = c("NoFormalEducation", "Primary", "Secondary",
                                    "Bachelor", "Master", "Doctoral")),
            numericInput("d3_employment", "Employment (0/1)", value = 0, min = 0, max = 1),
            numericInput("d3_gender", "Gender (0=Female, 1=Male)", value = 0, min = 0, max = 1),
            numericInput("d3_mental", "Mental Health (0=No, 1=Yes)", value = 0, min = 0, max = 1),
            numericInput("d3_yearscode", "Years Coding", value = 5, min = 0, max = 50),
            numericInput("d3_yearscodepro", "Years Coding Professionally", value = 3, min = 0, max = 50),
            numericInput("d3_salary", "Previous Salary", value = 50000, min = 0),
            numericInput("d3_cs", "Computer Skills", value = 5, min = 0, max = 20)
          ),
          actionButton("predict_btn", "Predict", class = "btn-primary")
        ),
        mainPanel(
          h4("Prediction Result"),
          verbatimTextOutput("pred_result")
        )
      )
    )
  )
)

server <- function(input, output, session) {

  perf <- reactive({
    path <- "outputs/model_metrics_dual_dataset.csv"
    if (file.exists(path)) read_csv(path, show_col_types = FALSE) else tibble()
  })

  fair <- reactive({
    path <- "outputs/fairness/fairness_metrics.csv"
    if (file.exists(path)) read_csv(path, show_col_types = FALSE) else tibble()
  })

  reduction <- reactive({
    path <- "outputs/fairness/bias_reduction.csv"
    if (file.exists(path)) read_csv(path, show_col_types = FALSE) else tibble()
  })

  output$perf_table <- renderDT({
    df <- perf()
    if (nrow(df) == 0) return(NULL)
    df %>% mutate(across(where(is.numeric), ~ round(., 3))) %>%
      datatable(options = list(pageLength = 20, dom = 'ft'), rownames = FALSE)
  })

  output$acc_plot <- renderPlot({
    df <- perf()
    if (nrow(df) == 0) return(NULL)
    ggplot(df, aes(x = model, y = accuracy, fill = dataset)) +
      geom_col(position = "dodge") +
      coord_flip() +
      labs(x = "Model", y = "Accuracy", fill = "Dataset") +
      theme_minimal(base_size = 14)
  })

  output$fair_table <- renderDT({
    df <- fair()
    if (nrow(df) == 0) return(NULL)
    df %>% mutate(across(where(is.numeric), ~ round(., 4))) %>%
      datatable(options = list(pageLength = 20, dom = 'ft'), rownames = FALSE)
  })

  output$reduction_table <- renderDT({
    df <- reduction()
    if (nrow(df) == 0) return(NULL)
    df %>% mutate(across(where(is.numeric), ~ round(., 2))) %>%
      datatable(options = list(dom = 't'), rownames = FALSE)
  })

  output$dpd_plot <- renderPlot({
    df <- fair()
    if (nrow(df) == 0) return(NULL)
    ggplot(df, aes(x = model, y = demographic_parity, fill = dataset)) +
      geom_col(position = "dodge") +
      coord_flip() +
      labs(x = "Model", y = "Demographic Parity Difference", fill = "Dataset") +
      theme_minimal(base_size = 13)
  })

  output$cal_plot <- renderPlot({
    df <- fair()
    if (nrow(df) == 0 || !"calibration" %in% names(df)) return(NULL)
    ggplot(df, aes(x = model, y = calibration, fill = dataset)) +
      geom_col(position = "dodge") +
      coord_flip() +
      labs(x = "Model", y = "Calibration Difference", fill = "Dataset") +
      theme_minimal(base_size = 13)
  })

  # --- Before/After tab ---
  output$before_table <- renderDT({
    df <- fair()
    if (nrow(df) == 0) return(NULL)
    df %>% filter(dataset == input$cmp_dataset, model == "baseline_rf") %>%
      mutate(across(where(is.numeric), ~ round(., 4))) %>%
      datatable(options = list(dom = 't'), rownames = FALSE)
  })

  output$after_table <- renderDT({
    df <- fair()
    if (nrow(df) == 0) return(NULL)
    df %>% filter(dataset == input$cmp_dataset, model != "baseline_rf") %>%
      slice_min(demographic_parity, n = 1) %>%
      mutate(across(where(is.numeric), ~ round(., 4))) %>%
      datatable(options = list(dom = 't'), rownames = FALSE)
  })

  output$before_after_plot <- renderPlot({
    df <- fair()
    if (nrow(df) == 0) return(NULL)
    sub <- df %>% filter(dataset == input$cmp_dataset) %>%
      mutate(type = if_else(model == "baseline_rf", "Baseline", "Mitigated"))
    sub_long <- sub %>%
      tidyr::pivot_longer(cols = c(demographic_parity, equalized_odds, calibration),
                          names_to = "metric", values_to = "value")
    ggplot(sub_long, aes(x = metric, y = value, fill = type)) +
      geom_col(position = "dodge") +
      labs(x = "Fairness Metric", y = "Value", fill = "Model Type",
           title = paste("Before vs After —", input$cmp_dataset)) +
      theme_minimal(base_size = 14) +
      theme(axis.text.x = element_text(angle = 20, hjust = 1))
  })

  # --- Prediction tab ---
  observeEvent(input$predict_btn, {
    ds <- input$pred_dataset

    if (ds == "Dataset 1") {
      model_path <- "models/best_model_dataset1.rds"
      new_data <- data.frame(
        Gender = as.integer(input$d1_gender),
        CGPA = input$d1_cgpa,
        Experience_Years = input$d1_exp,
        Skills_Score = input$d1_skills,
        Interview_Score = input$d1_interview,
        Education_Level = factor("Bachelors", levels = c("Bachelors", "Masters"))
      )
    } else if (ds == "Dataset 2") {
      model_path <- "models/best_model_dataset2.rds"
      new_data <- data.frame(
        Age = input$d2_age,
        Gender = as.integer(input$d2_gender),
        EducationLevel = factor(input$d2_edu),
        ExperienceYears = input$d2_exp,
        PreviousCompanies = input$d2_prev,
        DistanceFromCompany = input$d2_dist,
        InterviewScore = input$d2_interview,
        SkillScore = input$d2_skill,
        PersonalityScore = input$d2_personality,
        RecruitmentStrategy = factor(input$d2_recruit)
      )
    } else {
      model_path <- "models/best_model_dataset3.rds"
      new_data <- data.frame(
        Age = factor(input$d3_age),
        EdLevel = factor(input$d3_edlevel),
        Employment = as.integer(input$d3_employment),
        Gender = as.integer(input$d3_gender),
        MentalHealth = as.integer(input$d3_mental),
        YearsCode = input$d3_yearscode,
        YearsCodePro = input$d3_yearscodepro,
        PreviousSalary = input$d3_salary,
        ComputerSkills = input$d3_cs
      )
    }

    if (!file.exists(model_path)) {
      output$pred_result <- renderText("Model file not found. Run the pipeline first.")
      return()
    }
    model <- readRDS(model_path)
    prob <- tryCatch(predict(model, new_data = new_data, type = "prob")$.pred_1, error = function(e) NA)
    cls  <- tryCatch(as.character(predict(model, new_data = new_data, type = "class")$.pred_class), error = function(e) "Error")
    label <- if (ds == "Dataset 1") {
      ifelse(cls == "1", "SELECTED", "REJECTED")
    } else if (ds == "Dataset 2") {
      ifelse(cls == "1", "HIRED", "NOT HIRED")
    } else {
      ifelse(cls == "1", "EMPLOYED", "NOT EMPLOYED")
    }
    result <- paste0(
      "Dataset: ", ds, "\n",
      "Prediction: ", label, "\n",
      "Probability: ", round(prob, 3), "\n"
    )
    output$pred_result <- renderText(result)
  })
}

shinyApp(ui = ui, server = server)
