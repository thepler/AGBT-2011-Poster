#!/usr/bin/env Rscript

cat(paste("Adding idas R library path", "\n"))
.libPaths("/gscuser/idas/R/x86_64-pc-linux-gnu-library/2.10")

cat(paste("Loading R Libraries", "\n"))
library("grid")
library("reshape")
library("plyr")
library("ggplot2")
library("Cairo")
#data <- read.table("illumina-pipeline-bases-tally.sql.out.clean.gb", header=TRUE, sep="\t")
cat(paste("Reading in data", "\n"))
data <- read.table("days-vs-month.txt", header=TRUE, sep="\t")
data$Month <- as.POSIXct(data$Month, format="%Y-%m-%d")
#data$Month <- as.POSIXct(data$Month, format="%Y-%m")
cat(paste("Setting up Cairo SVG output", "\n"))
svg(
    filename = "days-vs-month.svg",
#    width    = 10,
#    height   = 10,
#    bg       = "white",
#    pointsize = 12
)
#pdf(file="month.pdf")
cat(paste("Plotting", "\n"))

# Line Chart
#ggplot(data, aes(month, gb)) + geom_line()

# Scatter Plot with a Trend Line
#qplot(month, gb, 
#        data = data, 
#        geom = c("point", "smooth"), 
#        span = 0.5, # the "wiggle" of the trend line 0 no wiggle 1 most wiggle
#        se = FALSE,
#        main = "Illumina Bases Count"
#)

# Scatter Plot (as Bars)
ggplot(data, aes(Month, Days)) + geom_bar(stat="identity") + opts(title="Illumina Processing Time (Average Wallclock Days per Run) by Month")
#ggplot(data, aes(as.character(month), gb)) + geom_bar() # Experiment DO NOT USE

# Regular "R Plotting"
#plot(data)

# turn off the SVG printing device
dev.off()
quit(save="no", status=0)
