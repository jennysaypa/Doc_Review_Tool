options(java.parameters = "-Xmx1024m", scipen =  999)

#library(ggplot2)
#library(plotly)
library(shiny)
library(shinydashboard)
library(shinyjs)
library(DT)
library(dplyr)
library(xlsx)
library(RODBC)




 #Open SQL Connection
   SQLconn <- odbcDriverConnect("Driver=SQL Server;server=Knuckle;database=Volcanic;trusted_connection=yes;")
   sample_data <-sqlQuery(SQLconn, sql_statement ,stringsAsFactors=FALSE)
   odbcCloseAll()



ui <- shinyUI( tagList(useShinyjs(), navbarPage( 
              'OHTA Insight Tool (Coal demo)',
              navbarMenu('SQL Dataset',
              tabPanel('Import Accounts / Transactions Dataset',
                       div(id = 'Sidebar',
                       sidebarPanel( tags$h3('Transactions'), tags$hr(),
                         # tags$style(type="text/css",
                         #            ".shiny-output-error { visibility: hidden; }",
                         #            ".shiny-output-error:before { visibility: hidden; }"),
                         fileInput("file1", "File Upload", multiple = FALSE,
                                   accept = c("text/csv", "text/comma-separated-values,text/plain", ".csv")), tags$hr(),
                         textAreaInput(inputId = 'sql_txt', 'Run your SQL Statement', rows= 3), 
                         actionButton(inputId = 'run_sql', 'Run in SQL'), 
                         uiOutput('select_columns'), width = 3
                       )),
                         mainPanel( actionButton('toggle_sidebar', "", icon = icon('eye-open', lib = 'glyphicon')),
                                    verbatimTextOutput('button_done_print'), 
                                    uiOutput('details_output'))
                      ),
              tabPanel('Import Document Dataset', 
                       div(id ='Sidebar_0', sidebarPanel( tags$h3('Documents'), tags$hr(),
                         fileInput("file0", "File Upload", multiple = FALSE,
                                                                   accept = c("text/csv", "text/comma-separated-values,text/plain", ".csv")), tags$hr(),
                                                         textAreaInput(inputId = 'sql_txt_doc', 'Run your SQL Statement', rows= 3), 
                                                         actionButton(inputId = 'run_sql_doc', 'Run in SQL'),
                                                         uiOutput('select_columns_doc'), width = 3
                                                         )),
                       mainPanel(actionButton('toggle_sidebar_0', "", icon = icon('eye-open', lib = 'glyphicon')),
                                 uiOutput('doc_details_output')))),

              
              tabPanel('Supporting Documents',
                       div(id = 'Sidebar_2', 
                           sidebarPanel(
                                    tags$h3('Associate Documents to Transactions'),
                                     tags$p('Click on the transactions and documents together to link them.')
                          )),
                       mainPanel(actionButton('toggle_sidebar_2', "", icon = icon('eye-open', lib = 'glyphicon')),
                                    uiOutput('Ref_Table'))),
              tabPanel('Exclusions',
                       div(id = 'Sidebar_3',
                       sidebarPanel( tags$h3('Annotate your Exclusions'),
                                     tags$p('Annotate the exclusions with a reason for exclusion (dropdown menu?)'))),
                       mainPanel(actionButton('toggle_sidebar_3', "", icon = icon('eye-open', lib = 'glyphicon')),
                         dataTableOutput('Excl_from_Main_Table'))
                       ), 
              tabPanel('Summary',
                       div(id = 'Sidebar_4',
                       sidebarPanel(
                         uiOutput('Summarize_dropdown'),  
                         #uiOutput( 'freq_amounts_dropdown'),
                         uiOutput( 'cross_tab_dropdown'), width = 3
                       )),
                       mainPanel(actionButton('toggle_sidebar_4', "", icon = icon('eye-open', lib = 'glyphicon')),
                                 uiOutput('summary_output'),
                                 uiOutput('chart_title'),
                                 tableOutput('chart'),
                                 plotOutput('barchart_by_type'))
              ),
              tabPanel('Cover Page',
                       div(id = 'Sidebar_5', 
                           sidebarPanel(tags$p('General Information, Summary, Background, Conclusions, Receipts, Disbursements'), width = 3)),
                           mainPanel(actionButton('toggle_sidebar_5', "", icon = icon('eye-open', lib = 'glyphicon')), tags$hr(),
                                     textAreaInput('gen_info', 'General Information', rows = 5, cols = 20),
                                     textAreaInput('background', 'Background', rows= 5, cols = 20),
                                     textAreaInput('receipts', 'Receipts', rows= 5, cols = 20),
                                     textAreaInput('disbursements', 'Disbursements', rows= 5, cols = 20),
                                     textAreaInput('conclusions', 'Conclusions', rows= 5, cols = 20))),
              tabPanel('QC Checklist'),
              tabPanel('Export to Spreadsheet')
        )))


server <- function(input, output, session) {
  
#################Side bar interactivity############################################

sidebar_showing <- reactiveVal(TRUE)
sidebar_showing_0 <- reactiveVal(TRUE)
sidebar_showing_2 <- reactiveVal(TRUE)
sidebar_showing_3 <- reactiveVal(TRUE)
sidebar_showing_4 <- reactiveVal(TRUE)
sidebar_showing_5 <- reactiveVal(TRUE)
  
  observeEvent(input$toggle_sidebar, {
    if (sidebar_showing()) {
     shinyjs::hide(id = "Sidebar")
      sidebar_showing(FALSE)
    }
    else {
     shinyjs::show(id = "Sidebar")
      sidebar_showing(TRUE)
    }
  })
  
  observeEvent(input$toggle_sidebar_0, {
    if (sidebar_showing_0()) {
      shinyjs::hide(id = "Sidebar_0")
      sidebar_showing_0(FALSE)
    }
    else {
      shinyjs::show(id = "Sidebar_0")
      sidebar_showing_0(TRUE)
    }
  })

  observeEvent(input$toggle_sidebar_2, {
    if (sidebar_showing_2()) {
      shinyjs::hide(id = "Sidebar_2")
      sidebar_showing_2(FALSE)
    }
    else {
      shinyjs::show(id = "Sidebar_2")
      sidebar_showing_2(TRUE)
    }
  })

  observeEvent(input$toggle_sidebar_3, {
    if (sidebar_showing_3()) {
      shinyjs::hide(id = "Sidebar_3")
      sidebar_showing_3(FALSE)
    }
    else {
      shinyjs::show(id = "Sidebar_3")
      sidebar_showing_3(TRUE)
    }
  })
  
  observeEvent(input$toggle_sidebar_4, {
    if (sidebar_showing_4()) {
      shinyjs::hide(id = "Sidebar_4")
      sidebar_showing_4(FALSE)
    }
    else {
      shinyjs::show(id = "Sidebar_4")
      sidebar_showing_4(TRUE)
    }
  })
  
  observeEvent(input$toggle_sidebar_5, {
    if (sidebar_showing_5()) {
      shinyjs::hide(id = "Sidebar_5")
      sidebar_showing_5(FALSE)
    }
    else {
      shinyjs::show(id = "Sidebar_5")
      sidebar_showing_5(TRUE)
    }
  })

  
  
#################Global Environments############################################ 
  
    sql_Data <- reactiveValues()
    sql_doc_Data <- reactiveValues()
    grouped_Data <- reactiveValues()
    xtab_Data <- reactiveValues()
    Excluded_Data <- reactiveValues()
    Ref_Tran_Data <- reactiveValues()
    Ref_Doc_Data <- reactiveValues()
    data_import_fl <- reactiveVal(FALSE)
    data_import_doc_fl <- reactiveVal(FALSE)
    data_import <- reactiveValues()
    data_import_doc <- reactiveValues()
    view_xtables_selected <- reactive(input$view_xtables)
    button_done <- reactiveVal(FALSE)
    button_count <- reactiveVal(0)
    

#################First Tab: Importing the Data and Managing the Columns############################################
    
    observeEvent(input$run_sql_doc, {
      #Open SQL Connection
      SQLconn <- odbcDriverConnect("Driver=SQL Server;server=Knuckle;database=Volcanic;trusted_connection=yes;")
      sql_doc_Data$rawdf <<-sqlQuery(SQLconn, isolate(input$sql_txt_doc), stringsAsFactors=FALSE)
      odbcCloseAll()
      data_import_doc$colnames <-colnames(sql_doc_Data$rawdf)
      data_import_doc_fl(TRUE) 
    })
    
    
    observeEvent(input$file0, {
      sql_doc_Data$rawdf <<- read.csv(input$file0$datapath, header = TRUE, sep = ',', quote = "'", stringsAsFactors = FALSE)
      data_import_doc$colnames <-colnames(sql_doc_Data$rawdf)
      data_import__doc_fl(TRUE)
    })
    
    
    
    
    observeEvent(input$run_sql, {
      #Open SQL Connection
      SQLconn <- odbcDriverConnect("Driver=SQL Server;server=Knuckle;database=Volcanic;trusted_connection=yes;")
      sql_Data$rawdf <<-sqlQuery(SQLconn, isolate(input$sql_txt), stringsAsFactors=FALSE)
      Excluded_Data$df <- data.frame()
      odbcCloseAll()
      data_import$colnames <-colnames(sql_Data$rawdf)
      data_import_fl(TRUE)    
    })

    
    observeEvent(input$file1, {
      sql_Data$rawdf <<- read.csv(input$file1$datapath, header = TRUE, sep = ',', quote = "'", stringsAsFactors = FALSE)
      Excluded_Data$df <- nrow(sql_Data$rawdf, 0)
      data_import$colnames <-colnames(sql_Data$rawdf)
      data_import_fl(TRUE)
    })
    
  
    observeEvent( input$hide_show_columns, {
      sql_Data$df <- sql_Data$rawdf %>% select(input$hide_show_columns)
    })
    
    observeEvent( input$hide_show_columns_doc, {
      sql_doc_Data$df <- sql_doc_Data$rawdf %>% select(input$hide_show_columns_doc)
    })
    
    
    output$select_columns <- renderUI({
      if (data_import_fl())  {
        box(
          tags$hr(),
          #checkboxInput('nothing_bar', 'Select First Column', FALSE),
          checkboxGroupInput('hide_show_columns', 'Show/Hide Columns in your SQL Dataset',
                            data_import$colnames, selected = data_import$colnames, width = '200px')
        )
      }
    })
    
    output$select_columns_doc <- renderUI({
      if (data_import_doc_fl())  {
        box(
          tags$hr(),
          #checkboxInput('nothing_bar', 'Select First Column', FALSE),
          checkboxGroupInput('hide_show_columns_doc', 'Show/Hide Columns in your SQL Dataset',
                             data_import_doc$colnames, selected = data_import_doc$colnames, width = '200px')
        )
      }
    })
    
    # observe({
    #   updateCheckboxGroupInput(
    #     session, 'hide_show_columns', choices = data_import$colnames,
    #     selected = if (input$nothing_bar) data_import$colnames)
    # })

#################Second Tab: Summary Tables############################################
    output$Summarize_dropdown <- renderUI({
        div(
        selectInput('first_group', '1. Summarize by:', colnames(sql_Data$df), selected =  colnames(sql_Data$df)[1], width = '200px'),
        selectInput('second_group', '2. Summarize by:', colnames(sql_Data$df), selected =  colnames(sql_Data$df)[1], width = '200px'),
        selectInput('third_group', '3. Summarize by:', colnames(sql_Data$df), selected =  colnames(sql_Data$df)[1], width = '200px'),
        selectInput('fourth_group', '4. Summarize by:', colnames(sql_Data$df), selected =  colnames(sql_Data$df)[1], width = '200px')
        )
    })
    
    xtab_sqlData <- reactive({
      
      if ( data_import_fl() ) {
        if ( grepl('Grenade', tolower(isolate(input$sql_txt)))) {
          xtab_Data$list <- lapply(sql_Data$df[,c('Flophouse', 'Airship', 'Cadaver', 'Sacred', 'Curve')],
                                 function(Cadaver) as.data.frame.matrix(xtabs( ~ Cadaver + sql_Data$df[[input$first_group]])))
        }
        returnValue(xtab_Data$list)
      }
    }) 
    
    group_sqlData <- reactive({
      
      if ( data_import_fl() ) {
          if ( grepl('Hunk', tolower(isolate(input$sql_txt)))) {
          grouped_Data$df <- data.frame(sql_Data$df %>% group_by_(input$first_group, input$second_group, input$third_group, input$fourth_group) %>%
                                          summarise( Amount_Current = as.character(sum(Joystick, na.rm = TRUE)),
                                                     Amount_ThroughPut = as.character(sum(Locus, na.rm = TRUE)),
                                                     Account_Count = n()))
        }
        
        if ( grepl('Grenade', tolower(isolate(input$sql_txt)))) {
          grouped_Data$df <- data.frame(sql_Data$df %>% group_by_(input$first_group, input$second_group, input$third_group, input$fourth_group) %>%
                                          summarise( min_tran_date = as.character(min(Passion, na.rm = TRUE)),
                                                     max_tran_date = as.character(max(Passion, na.rm = TRUE)),
                                                     count_trans = n(),
                                                     total_sum_receipts = sum(Plastic[sign(Plastic) > 0], na.rm = TRUE),
                                                     total_sum_disbursements = sum(Plastic[sign(Plastic) < 0], na.rm = TRUE)))
        }
      }

      returnValue(grouped_Data$df)
    })  
     
     make_barchart <- reactive({
       if ( grepl('Grenade', tolower(isolate(input$sql_txt)))) {
         tran_count_chart <-grouped_Data$df[,'count_trans']
         names_tran_count_chart <- grouped_Data$df[,input$first_group]
         #supp_text <- rep('a', length(names_tran_count_chart))
       }
       returnValue(list(tran_count_chart, names_tran_count_chart))
     })
     
     
     output$barchart_by_type <- renderPlot({
       if ( data_import_fl() ) {
         #plot_ly(make_barchart(), x=~x, y = ~y, type = 'bar', text = supp_text)
         barplot(make_barchart()[[1]], main = 'Transaction Count', horiz = FALSE,
                 ylab = 'Transactions', xlab=as.character(input$first_group),
                 names.arg = make_barchart()[[2]], axisnames = TRUE)
       }
         
       
     })
     
     output$freq_amounts_dropdown <- renderUI({
       if ( data_import_fl() ) {
         if ( grepl('Grenade', tolower(isolate(input$sql_txt)))) {
           selectInput('view_xtables', 
                       'Frequencies or Amounts:',
                       choices = c('Freq', 'Amounts'),
                       selected = NULL, multiple = FALSE)
         }
       }
     })
     
     
     
          output$cross_tab_dropdown <- renderUI({
       if ( data_import_fl() ) {
         if ( grepl('Grenade', tolower(isolate(input$sql_txt)))) {
           selectInput('view_xtables', 
                  'Analyze Frequencies by:',
                   choices = c('Flophouse', 'Airship', 'Cadaver', 'Sacred', 'Curve'),
                   selected = NULL, multiple = FALSE)
         }
       }
     })
    
     
     observeEvent(view_xtables_selected(), {
       if ( 'Flophouse' %in% view_xtables_selected() ) {
         output$chart_title <- renderUI({ if( data_import_fl() ) {tags$h3('TRAN TYPE HIST') }})
         output$chart <- renderTable( t(xtab_sqlData()[[1]]), rownames = TRUE)
       }
       
       if ( 'Airship' %in% view_xtables_selected() ) {
         output$chart_title <- renderUI({ if( data_import_fl() ) {tags$h3('REV CD HIST') }})
         output$chart <- renderTable( t(xtab_sqlData()[[2]]), rownames = TRUE)
       }
       
       if ( 'Cadaver' %in% view_xtables_selected() ) {
         output$chart_title <- renderUI({ if( data_import_fl() ) {tags$h3('Cadaver') }})
         output$chart <- renderTable( t(xtab_sqlData()[[3]]), rownames = TRUE)
       }
       
       if ( 'Sacred' %in% view_xtables_selected() ) {
         output$chart_title <- renderUI({ if( data_import_fl() ) {tags$h3('Sacred') }})
         output$chart <- renderTable( t(xtab_sqlData()[[4]]), rownames = TRUE)
       }
       if ( 'Curve' %in% view_xtables_selected() ) {
         output$chart_title <- renderUI({ if( data_import_fl() ) {tags$h3('Curve') }})
         output$chart <- renderTable( t(xtab_sqlData()[[5]]), rownames = TRUE)
       }
       
     })
     
    
    output$summary_output <- renderUI({
      fluidPage(
        box(width=20,
            if ( data_import_fl() ) {
              column(9, offset = 9,
                     HTML('<div class="btn-group" role="group">'),
                     actionButton(inputId = "move_to_cover_page",label = "Move to Cover Page"),
                     HTML('</div>')
              )
            }
            
            ,
            
            column(9,dataTableOutput("summary_table")),
            tags$script(HTML('$(document).on("click", "input", function () {
                             var checkboxes = document.getElementsByName("row_selected");
                             var checkboxesChecked = [];
                             for (var i=0; i<checkboxes.length; i++) {
                             if (checkboxes[i].checked) {
                             checkboxesChecked.push(checkboxes[i].value);
                             }
                             }
                             Shiny.onInputChange("checked_rows",checkboxesChecked);
            })')),
            tags$script("$(document).on('click', '#Main_table button', function () {
                  Shiny.onInputChange('lastClickId',this.id);
                  Shiny.onInputChange('lastClick', Math.random())
            });")
            
        )
      )
    }) 
     
     
    output$summary_table <- DT::renderDataTable( 
      group_sqlData(), options = list(paging =FALSE, searching = FALSE), server = TRUE)
    
#################First Tab: SQL Dataset and Exclude/ Reference Items ############################################
    output$details_output<-renderUI({
      fluidPage(
        box(width=20,
            if ( data_import_fl() ) {
              column(9, offset = 9,
                   HTML('<div class="btn-group" role="group">'),
                   actionButton(inputId = "Excl_row_head",label = "Exclude items"),
                   actionButton(inputId = "Ref_row_head",label = 'Move item to "Supporting Documents"'),
                   HTML('</div>')
            )
            },
            column(9,dataTableOutput("Main_table")),
            tags$script(HTML('$(document).on("click", "input", function () {
                             var checkboxes = document.getElementsByName("row_selected");
                             var checkboxesChecked = [];
                             for (var i=0; i<checkboxes.length; i++) {
                             if (checkboxes[i].checked) {
                             checkboxesChecked.push(checkboxes[i].value);
                             }
                             }
                             Shiny.onInputChange("checked_rows",checkboxesChecked);
            })')),
      tags$script("$(document).on('click', '#Main_table button', function () {
                  Shiny.onInputChange('lastClickId',this.id);
                  Shiny.onInputChange('lastClick', Math.random())
            });")

        )
        )
      })
    
    output$Main_table<-renderDataTable(
      
      if (data_import_fl()) {
        DT=datatable(sql_Data$df, 
                     filter = 'top', 
                     #options = list(paging = FALSE, searching = FALSE), 
                     escape=FALSE, rownames = TRUE)
      }, server = TRUE
      )
    
    output$doc_details_output<-renderUI({
      fluidPage(
        box(width=20,
            if ( data_import_doc_fl() ) {
              column(9, offset = 9,
                     HTML('<div class="btn-group" role="group">'),
                     actionButton(inputId = "Ref_row_head_doc",label = 'Move to "Supporting Documents"'),
                     HTML('</div>')
              )
            },
            column(9,dataTableOutput("Doc_table")),
            tags$script(HTML('$(document).on("click", "input", function () {
                             var checkboxes = document.getElementsByName("row_selected");
                             var checkboxesChecked = [];
                             for (var i=0; i<checkboxes.length; i++) {
                             if (checkboxes[i].checked) {
                             checkboxesChecked.push(checkboxes[i].value);
                             }
                             }
                             Shiny.onInputChange("checked_rows",checkboxesChecked);
            })')),
            tags$script("$(document).on('click', '#Main_table button', function () {
                  Shiny.onInputChange('lastClickId',this.id);
                  Shiny.onInputChange('lastClick', Math.random())
            });")
            
        )
      )
    })
    
    output$Doc_table<-renderDataTable(
      
      if (data_import_doc_fl()) {
        DT=datatable(sql_doc_Data$df, 
                     filter = 'top', 
                     #options = list(paging = FALSE, searching = FALSE), 
                     escape=FALSE, rownames = TRUE)
      }, server = TRUE
    )
    
    #################Features: Exclude/ Reference Items ############################################
    
    # output$button_done_print <- renderPrint(
    #   if ( button_done() ) {
    #     paste0("Button Done. ", button_count())
    #     button_done(FALSE)
    #     }
    #   )
    
    observeEvent(input$Excl_row_head,{
      selected_rows <- 0
      selected_rows <- input$Main_table_rows_selected
      rows_to_exclude<- selected_rows
      Excluded_Data$df <- rbind(Excluded_Data$df, sql_Data$df[rows_to_exclude,])
      sql_Data$df <- sql_Data$df[-rows_to_exclude,]
      # button_count(button_count() + 1)
      # button_done(TRUE)
      }
    )
    
    output$Excl_from_Main_Table <- renderDataTable(Excluded_Data$df, filter = 'top', options = list(paging = TRUE, searching = FALSE), escape=FALSE, rownames = TRUE)
    
    
    observeEvent(input$Ref_row_head,{
      selected_rows <- 0
      selected_rows <- input$Main_table_rows_selected
      rows_to_ref<- selected_rows
      if (grepl('Grenade', tolower(isolate(input$sql_txt)))) {
        Ref_Tran_Data$df <- rbind(Ref_Tran_Data$df, sql_Data$df[rows_to_ref,c('Nectar', 'Neck','Blush', 'Plastic', 'Passion')])
      }
      # button_count(button_count() + 1)
      # button_done(TRUE)
    }
    )
    
    
    observeEvent(input$Ref_row_head_doc,{
      selected_rows <- 0
      selected_rows <- input$Doc_table_rows_selected
      rows_to_ref<- selected_rows
      if (grepl('doc_indx_vw', tolower(isolate(input$sql_txt_doc)))) {
        Ref_Doc_Data$df <- rbind(Ref_Doc_Data$df, sql_doc_Data$df[rows_to_ref,c('Germ', 'Queen','Punch', 'Deer', 'Fang', 'TITLE', 'AMOUNT', 'PAGE_CT', 'Shrimp', 'Abstract')])
        Ref_Doc_Data$df[['Abstract']] <- paste0(Ref_Doc_Data$df[['Shrimp']], Ref_Doc_Data$df[['Abstract']])
      }
      # button_count(button_count() + 1)
      # button_done(TRUE)
    }
    )
    
    output$Ref_Table <- renderUI({
      fluidPage(
        box(width=20,
            if ( data_import_fl() ) {
              column(9, offset = 9,
                     HTML('<div class="btn-group" role="group">'),
                     actionButton(inputId = "move_to_cover_page_ref",label = "Move to Cover Page"),
                     HTML('</div>')
              )
            }
            
            ,
            
            column(9,dataTableOutput("Ref_Tran_Table")),
            column(9,dataTableOutput("Ref_Doc_Table"))
            
        )
      )
    }) 
    
    output$Ref_Tran_Table <- renderDataTable(Ref_Tran_Data$df, filter = 'top', options = list(paging = TRUE, searching = FALSE), escape=FALSE, rownames = TRUE)
    
    output$Ref_Doc_Table <- renderDataTable(Ref_Doc_Data$df, filter = 'top', options = list(paging = TRUE, searching = FALSE), escape=FALSE, rownames = TRUE)
    
    
##################Move to Cover Page###############################################
    observeEvent( input$move_to_cover_page_ref, {
      
      Tran_Table_rows <- isolate(input$Ref_Tran_Table_rows_selected)
      Tran_Data_Values <- Ref_Tran_Data$df[Tran_Table_rows, ]
      colnames(Tran_Data_Values) <- NULL
      print(Tran_Data_Values)
      showModal(modalDialog(
        

        
        selectizeInput('tran_elements_move_over', 'Data Values from Transactions Side', 
                       choices = Tran_Data_Values,
                       selected = NULL, multiple = TRUE),
        
        
        title = 'Move to Cover Page', 
        "Select what elements to move over to each section in the Cover Page.",
        easyClose = TRUE,
        footer = NULL
      ))
    })
    
}

shinyApp(ui = ui, server = server)
