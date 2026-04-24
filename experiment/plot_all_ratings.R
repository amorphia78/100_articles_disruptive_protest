setwd_disruption_analysis() # This function needs to be defined in your .RProfile file to setwd() to the disruption_analysis repo root
library(dplyr)
library(tidyr)
library(ggplot2)
source("functions.R") #for char_labels
library(ggh4x) #for facetted_pos_scales

#get data
d_ratings <- read.csv("all_ratings_clean.csv")

#drop characteristics not of interest
d_ratings <- d_ratings %>%
  dplyr::select(-any_of(c("numberOfProtesters_imputed", "ordinary_imputed", "levelOfDisruption.PrivateJets", "issueBundling")))

#make long
d_long <- d_ratings %>%
  #pivot to long
  pivot_longer(
    cols = -id,
    names_to = "characteristic",
    values_to = "value"
  )

#add characteristic blocks
characteristics <- c("numberOfProtesters",
                     "levelOfDisruption.BusinessDamaging", "levelOfDisruption.PublicEveryday",
                     "levelOfDisruption.GovernmentOrAuthority", "levelOfDisruption.CultureOrSport",
                     "nature.Blockade", "nature.Attached", "nature.AlteratVandal", "nature.Interrupting",
                     "portrayal", "words.general_disruption", "words.protester_messaging", "words.negative_comments",            
                     "perceived_disruption", "ordinary", "acceptance")
char_blocks <- c(rep(1, 9), rep(2, 4), rep(3, 2), 4)
names(char_blocks) <- characteristics
d_long$block <- as.factor(char_blocks[d_long$characteristic])

#set levels
d_long$characteristic <- factor(
  d_long$characteristic,
  levels=characteristics)

#convert them to nice labels
d_long$charlabel <- recode(d_long$characteristic, !!!char_labels)

#plot faceted histograms
pdf(("figures/char_distributions.pdf"), 8, 8)
ggplot(d_long, aes(x = value, fill=block)) +
  geom_histogram(bins = 30) +
  facet_wrap(~ charlabel, scales="free",
             labeller = labeller(charlabel = label_wrap_gen())) +
  theme_minimal() +
  theme(strip.text.x = element_text(size = 11),
        # remove the vertical grid lines
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        legend.position = "bottom",
        legend.direction = "horizontal",
        legend.box.margin = margin(t = -15)) +
  labs(x = "", y = "Count", fill = "Causal block") + 
  scale_fill_manual(values=c("#6c8ebf", "#82b366", "#d6b656", "#b46504")) +
  facetted_pos_scales(
    x = list(
      charlabel == "Number of Protesters" ~ scale_x_continuous(limits = c(1, 8), breaks = 1:8),
      charlabel == "Disruption to: polluting business" ~ scale_x_continuous(limits = c(1, 5), breaks = 1:5),
      charlabel == "Disruption to: public" ~ scale_x_continuous(limits = c(1, 5), breaks = 1:5),
      charlabel == "Disruption to: authority" ~ scale_x_continuous(limits = c(1, 5), breaks = 1:5),
      charlabel == "Disruption to: culture/sport" ~ scale_x_continuous(limits = c(1, 5), breaks = 1:5),
      charlabel == "Tactic: blockade" ~ scale_x_continuous(limits = c(0, 1), breaks = 0:1),
      charlabel == "Tactic: attachment" ~ scale_x_continuous(limits = c(0, 1), breaks = 0:1),
      charlabel == "Tactic: vandalism (often minor)" ~ scale_x_continuous(limits = c(0, 1), breaks = 0:1),
      charlabel == "Tactic: event interruption" ~ scale_x_continuous(limits = c(0, 1), breaks = 0:1),
      charlabel == "Article: positive portrayal" ~ scale_x_continuous(limits = c(1, 5), breaks = 1:5),
      charlabel == "Article: words on disruption" ~ scale_x_continuous(limits = c(0, 7), breaks = 0:7),
      charlabel == "Article: words on protester message" ~ scale_x_continuous(limits = c(0, 7), breaks = 0:7),
      charlabel == "Article: words negative about protest" ~ scale_x_continuous(limits = c(0, 7), breaks = 0:7),
      charlabel == "Public perception: protest disruptive" ~ scale_x_continuous(limits = c(1, 5), breaks = 1:5),
      charlabel == "Public perception: protesters ordinary" ~ scale_x_continuous(limits = c(1, 5), breaks = 1:5),
      charlabel == "Public perception: protest acceptable" ~ scale_x_continuous(limits = c(1, 5), breaks = 1:5)
    )
  )
dev.off()


## Visualize the correlation matrix

library(corrplot)

#sort columns
d_ratings_cor <- d_ratings[-1][,characteristics]

#get correlation matrix
cor_matrix <- cor(d_ratings_cor, use = "pairwise.complete.obs")

#give tidy names
charnames <- c("Number of Protesters",
  "Disruption to: polluting business",
  "Disruption to: public",
  "Disruption to: authority",
  "Disruption to: culture/sport",
  "Tactic: blockade",
  "Tactic: attachment",
  "Tactic: vandalism (often minor)",
  "Tactic: event interruption",
  "Article: positive portrayal",
  "Article: words on disruption",
  "Article: words on protester message",
  "Article: words negative about protest",
  "Public perception: protest disruptive",
  "Public perception: protesters ordinary",
  "Public perception: protest acceptable")
rownames(cor_matrix) <- charnames
colnames(cor_matrix) <- charnames

pdf(("figures/char_correlations.pdf"), 11, 11)
corrplot(cor_matrix,
         method = "color",         # color-shaded squares
         type = "upper",           # only upper triangle
         addCoef.col = "black",    # add correlation coefficients
         tl.col = "black",         # text label color
         tl.srt = 45,              # label rotation
         number.cex = 0.7,         # size of the coefficients
         mar = c(0, 0, 0, 0),
         col = colorRampPalette(c("red", "white", "blue"))(200))  # color scale
dev.off()

