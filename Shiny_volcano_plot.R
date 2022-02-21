#setwd("~/LocalPedagoNGS/Volcano_plot/")
library(shiny)
library (ggplot2)
library(plotly)

# Define UI for application that draws a histogram
ui <- shinyUI(fluidPage(
  tags$head(
    tags$style(HTML("

      .selectize-input {
        height: 35px;
        width: 400px;
        font-size: 11pt;
        padding-top: 5px;
      }"))),
  h1("Volcano Plot"),
  selectInput('inputFile', label='select a specie:',
              choices = c(
                          "zebrafish",
                          "rhodnius_OV",
                          "moustique",
                          "chien")),
  fluidRow(column( 9,
  plotlyOutput('volcanoPlot')),
  
  column(3,
  # Sidebar with the different filters
  sidebarLayout(position = "right",
                sidebarPanel(h2("Filters"),
                             width = 12,
                             helpText("Choose the threshold for each filter."),
                             
                             sliderInput("deltaPSI",
                                         label = "Value of deltaPSI:",
                                         min = 0,
                                         max = 1,
                                         value = 0.1,
                                         step = 0.1),
                             
                             numericInput("padj",
                                          label = "Threshold adjusted p-value:",
                                          value = 0.05,
                                          step = 0.01),
                             helpText("Adjusted p-value should be a numeric between 0 and 1.")),
                        mainPanel(width = 1))),
  column(12,
  # Table with data
  tagList(
    DT::dataTableOutput('data')
           )
  )
)))

server <- function(input, output){
  
  #read in the table as a function of the select input
  dataFrame <- reactive({
    filename <- paste0("../kissDE_results/kissDE_",input$inputFile,"_kissplice_1.tab")
    data <- read.csv(file=filename, sep='\t')
    colnames(data) <- c("Gene_Id",	"Gene_Name","Chromosome_and_genomic_position","Strand",	"Event_type","Variable_part_length",	
                             "Frameshift_?"	,"CDS_?"	,"Gene_biotype","number_of_known_splice_sites/number_of_SNPs",	
                             "genomic_blocs_size_(upper_path)"	,"genomic_position_of_each_splice_site_(upper_path)/of_each_SNP",	
                             "paralogs_?"	,"Complex_event_?",	"snp_in_variable_region" ,"Event_name",	"genomic_blocs_size_(lower_path)",	
                             "genomic_position_of_each_splice_site_(lower_path)",	"Psi_for_each_replicate", 
                             "Read_coverage(upper_path)"	,"Read_coverage(lower_path)",	"Canonical_sites?", 
                             "CountsNorm", "psiNorm","adjusted_pvalue" ,"dPSI",	"warnings")
    data$adjusted_pvalue[data$adjusted_pvalue==0]<- 2.2e-16 
    
    data$diffexpressed <- "Not significant"
    data$diffexpressed[data$dPSI > input$deltaPSI & data$adjusted_pvalue < input$padj] <- "UP"
    data$diffexpressed[data$dPSI < -input$deltaPSI & data$adjusted_pvalue < input$padj ] <- "DOWN"
    data$diffexpressed[data$dPSI > input$deltaPSI & data$adjusted_pvalue < input$padj & data$`CDS_?`=="True"] <- "CDS_UP"
    data$diffexpressed[data$dPSI < -input$deltaPSI & data$adjusted_pvalue < input$padj & data$`CDS_?`=="True"] <- "CDS_DOWN"
    
    data
    })
   
  # Keep only the selected columns
  dataToShow <- reactive({
    dataFrame()[dataFrame()$diffexpressed != "Not significant",] %>% select(1:3, 5, 8,16,25,26)
  })
    
    # display the table containing the data
    output$data <- DT::renderDataTable(
      DT::datatable(dataToShow(),
                    rownames = FALSE, 
                    filter = "top",
                    extensions = 'Buttons', 
                    options = list(
                      dom = 'Bfrtip',
                      buttons = c('copy', 'print'),
                      pageLength = 15,
                      scrollX = TRUE
                    )
      )
    )
  
  #plot with ggplot and plotly to make it interactive:
  output$volcanoPlot <- renderPlotly({ 
    mycolors <- c("grey", "red", "blue", "red", "blue")
    myshape <- c(16, 16, 16, 17,17)
    mysize <- c(0.5,1,1,2,2)
    names(mysize) <- c("Not significant", "UP", "DOWN", "CDS_UP", "CDS_DOWN")
    names(myshape)<- c("Not significant", "UP", "DOWN", "CDS_UP", "CDS_DOWN")
    names(mycolors) <- c("Not significant", "UP", "DOWN", "CDS_UP", "CDS_DOWN")
   plot <- ggplot(dataFrame(), aes(x=dPSI, y=-log10(adjusted_pvalue), label = Gene_Name,
    color =diffexpressed, shape=diffexpressed,size=diffexpressed,
    text =paste("</br> dPSI :",dPSI,"</br> Pval :",adjusted_pvalue,
    "</br> GeneID :",Gene_Id, "</br> GeneName :",Gene_Name,"</br> Event Type :",
    Event_type, "</br> BCC name : ", Event_name, 
    "</br> Position : ", Chromosome_and_genomic_position))) +
      xlab("dPSI") + ylab("-log10Pval") +
      geom_point() + 
      ggtitle(paste0("kissDE_",input$inputFile,"_kissplice")) +
      scale_colour_manual(values = mycolors) +
      scale_shape_manual(values= myshape)+
      scale_size_manual(values= mysize )+
      theme_bw()
   ggplotly(plot, tooltip =  "text")
   
  })
}

shinyApp(ui, server)
