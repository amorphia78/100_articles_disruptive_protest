source("functions.R")
library(haven)

##list outcome and characteristic variable names

#list outcomes of interest
outcomes <- c("Salience", "Concern", "Policy", "Behavior", "Envir_identif")
outcome_names <- c(outcomes[-c(4,5)], "Intentions", "Envir. identity") #for plots and tables

#list characteristics and their corresponding blocks
characteristics <- c("numberOfProtesters", "numberOfProtesters_imputed",
                     "levelOfDisruption.BusinessDamaging", "levelOfDisruption.PublicEveryday",
                     "levelOfDisruption.GovernmentOrAuthority", "levelOfDisruption.CultureOrSport",
                     "nature.Blockade", "nature.Attached", "nature.AlteratVandal", "nature.Interrupting",
                     "portrayal", "words.general_disruption", "words.protester_messaging", "words.negative_comments",            
                     "perceived_disruption", "ordinary", "ordinary_imputed",
                     "acceptance")
char_blocks <- c(rep(1, 10), rep(2, 4), rep(3, 3), 4)
names(char_blocks) <- characteristics #print char_blocks to check block allocations


##process rating data

#get cleaned data
d_ratings <- read.csv("all_ratings_clean.csv")

#standardize characteristics
d_ratings <- standardise_chars(d_ratings, characteristics)


##process experiment data

#get cleaned data
load(file="disruption_stimulus_data_clean.Rdata")

#kick out wave 2 dropouts
sum(!is.na(d$treated))/nrow(d) #check retention rate first
d <- d[!is.na(d$treated),]

#standardize outcomes
d <- standardise_outcomes(d, outcomes)

#get list of non-specific articles (not rated)
articles <- unique(d$id)[-1]
nonspec_articles <- articles[!articles %in% unique(d_ratings$id)]

#check data
#table(d$treated) #n per condition
#table(d$id) #n per article

#keep dataframe with non-specific articles, then kick them out
d_nonspec <- d
d <- d[!d$id %in% nonspec_articles,]


##join rating and experiment data

#join with rating data
d <- merge(d, d_ratings, by="id", all.x=T)


##add outlet-ideology probability data

#read outlet-ideology data
d_ideology <- read.csv("../Reuters/reading_prob_by_ideology.csv")

#tweak outlet names to fit experiment data
d_ideology$outlet <- recode(d_ideology$outlet, `BBC News online` = "BBC", DailyMail = "Daily-Mail",
                            Guardian="The-Guardian", `ITV News online`="ITV", TheTimes = "The-Times",
                            `Sky News online`="Sky")

#combine extreme ideology categories from 7-pt. scale (as in outlet data)
d$ideology_2to6 <- d$ideology_7p_num
d$ideology_2to6[d$ideology_2to6==1] <- 2
d$ideology_2to6[d$ideology_2to6==7] <- 6
d$ideology_2to6[is.na(d$ideology_2to6)] <- 99 #NA back to 99 as in with Reuters data

#get outlets from articles
d$outlet <- sapply(strsplit(d$id, "_"), `[`, 1)

#join ideology data
d <- merge(d, d_ideology, by=c("outlet", "ideology_2to6"), all.x=T)

#find out what pct. of treated group saw the outlet
outlets <- unique(d$outlet)
outlet_ps <- sapply(outlets, function(outlet) sum(d$outlet==outlet, na.rm=T)/sum(d$treated==1, na.rm=T))

#correct for existing outlet oversampling (to avoid double weighting)
d$ideo_outlet_weight <- d$probability / outlet_ps[d$outlet]

#check total weight per outlet
wgth_pr_out <- tapply(d$ideo_outlet_weight, d$outlet, sum, na.rm=T)
wgth_pr_out / sum(wgth_pr_out) #pct of the total weight taken up by each
#looks good, only slightly different from original outlet weights

#get average weight of treated respondents per ideology
ideo_weights <- tapply(d$ideo_outlet_weight, as.factor(d$ideology_2to6), mean, na.rm=T)
#as.factor is needed to make sure names are strings, not numbers

#make it so that control respondents of each ideology are weighted
#as much as treatment respondents of that ideology
control_ideologies <- as.character(d$ideology_2to6[d$treated == 0])
d$ideo_outlet_weight[d$treated == 0] <- ideo_weights[control_ideologies]

#inspect results
#View(d[c("treated","id","outlet","ideology_2to6","probability","ideo_outlet_weight")])

#check that average weights of treated and control group are (almost) the same
tapply(d$ideo_outlet_weight, d$treated, mean, na.rm=T)
