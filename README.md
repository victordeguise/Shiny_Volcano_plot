# Shiny_Volcano_plot

Script R to visualize differential expression analysis ([kissDE](https://www.bioconductor.org/packages/release/bioc/html/kissDE.html) output) with a volcano plot interactif with plotly and r shiny.

# Prerequisites

R and the following R packages should be installed:

- pacman
- shiny
- DT
- ggplot2
- plotly ( must have open-ssl, if not : sudo apt-get install libcurl4-openssl-dev libxml2-dev )

# Launch the Shiny App

After cloning the github repository, open the Shiny_volcano_plot.R script in RStudio. Then, click on the “Run App” button on the upper right corner of the text editor. The Shiny App will load. To visualize your results, you can add your kissDE results in Data folder, your file must be in kissDE output format.
