################################################################################
## Script for publication frequencies graph:
## "Figure 1. Distribution of year of publication for studies measuring pollen 
## limitation of plant reproduction included in the GloPL data base."
## title extracted from draft PLDataPaper7_6_2017_GAG_JHB_WD_jcv.docx
################################################################################

library(data.table)
library(ggplot2)
library(ggsci)
library(scales)

# =============================================================================
# Read & prepare data
# =============================================================================
# Read latest dataset
PL_all <- fread("Data/PL_ANALYSIS_02_10_2017.csv", colClasses = "character")

# Get only columns of interest
PL <- PL_all[,.(Year, Author, unique_number, unique_study_number)]
# Note: what is unique_study_number_TK vs. unique_study_number? 
# see the Excel file PL_masters_02_10_2017.xlsx

# There are character values for variable Year
unique(PL$Year)
# replace "2003b" with "2003" so to avoid transformation to NA when applying as.numeric
PL[Year == "2003b", Year := "2003"]
PL[, Year := as.numeric(Year)]
# check which records got NA for variable Year:
PL[is.na(Year)]

# Aggregate
PL_aggreg <- PL[!is.na(Year), # consider only records that have year information
                .(N_publications = uniqueN(unique_study_number),
                  N_studies = uniqueN(unique_number)), # same as = .N here (if a study is a row)
                by = Year]
PL_aggreg <- PL_aggreg[order(Year)]
PL_aggreg[, N_cumul_studies := cumsum(N_studies)]

# =============================================================================
# Plot
# =============================================================================

# Set 2nd scale "multiplication" factor
my_factor <- 0.02
# it should be in the range of the ratio of max value on left OY 
# divided by max values of the right OY (2nd axis)
max(PL_aggreg$N_publications)/max(PL_aggreg$N_cumul_studies)

# Experiment with color
mypal = ggsci::pal_npg("nrc", alpha = 1)(2)
scales::show_col(mypal); mypal

my_plot <- 
    ggplot(data = PL_aggreg, 
           aes(x = Year)) +
    geom_bar(aes(y = N_publications), 
             stat = "identity",
             fill = "#4DBBD5FF") +
    geom_line(aes(y = N_cumul_studies * my_factor),
              size = 1,
              color = "#E64B35FF") +
    scale_y_continuous(sec.axis = sec_axis(trans = ~ . / my_factor, 
                                           name = "Cumulative number of \n pollen limitation studies"),
                       limits = c(0, 75),
                       expand = c(0, 0)) +
    # set axis labels
    labs(x = "Year of publication", 
         y = "Number of publications") + 
    # eliminate default background
    theme_bw() + 
    theme( 
        panel.grid.major = element_line(size = 0.3, 
                                        linetype = "longdash"),
        panel.grid.minor = element_blank(), # eliminate minor grids
        # set font family for all text within the plot ("serif" should work as "Times New Roman")
        # note that this can be overridden with other adjustment functions below
        text = element_text(family = "serif", size = 8),
        # adjust text in X-axis title
        # axis.title.x = element_text(size = 10),
        # adjust title of first/left Y-axis
        axis.title.y = element_text(color = "#4DBBD5FF"),
        # adjust labels of first/left Y-axis 
        axis.text.y  = element_text(color = "#4DBBD5FF"),
        # adjust title of right/second Y-axis 
        axis.title.y.right = element_text(angle = 90, # set text rotation
                                          color = "#E64B35FF"), 
        # adjust labels of right/second Y-axis 
        axis.text.y.right  = element_text(color = "#E64B35FF"),
        # set margins around entire plot ( https://goo.gl/zdgLMt )
        plot.margin = unit(c(t = 0.4, 
                             r = 1.1, 
                             b = 0, 
                             l = 0.1), 
                           "mm")
    )

# inspect graph
my_plot

# save graph
ggsave(plot = my_plot,
       filename = "Output/Publication_freq.pdf", 
       width = 9, height = 5.5, scale = 1, units = "cm")

# =============================================================================
# References
# =============================================================================
# https://rpubs.com/MarkusLoew/226759
# https://whatalnk.github.io/r-tips/ggplot2-secondary-y-axis.nb.html
# using the grob approach: http://rpubs.com/kohske/dual_axis_in_ggplot2