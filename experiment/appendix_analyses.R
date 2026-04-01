library(patchwork)
source("functions.R")
source("load_and_join_data.R")


#### Preregistered analyses ####

## Main effect analysis: pooled effect of all treatments

#get raw conditional mean differences
diffs <- t(sapply(outcomes, get_cond_means))
colnames(diffs) <- c("Control, pre","Control, post", "Control, diff",
                     "Treated, pre","Treated, post", "Treated, diff",
                     "Diff in diff", "n")
rownames(diffs) <- outcome_names

#write to Latex
print(xtable(diffs, digits=c(0,2,2,2,2,2,2,2,0)), file="tables/conditional_means.tex", include.colnames=F, only.contents = T,
      hline.after = NULL)

#get unstandardized effect sizes
est_CI_pooled_raw_unstd <- run_main_effect_analyses(outcomes, standardise_outcomes=FALSE, data=d)
est_CI_pooled_unstd <- results_to_df(est_CI_pooled_raw_unstd)
make_results_table(est_CI_pooled_unstd, firstcol_values=outcome_names,
                   firstcol_name="Outcome", file_name="tables/main_effects_unstand.tex",
                   caption="Main effect of article treatment on environmental attitudes, unstandardized.",
                   label="tab:main_unstand")

#get standardized effect sizes
est_CI_pooled_raw_std   <- run_main_effect_analyses(outcomes, standardise_outcomes=TRUE, data=d)
est_CI_pooled_std <- results_to_df(est_CI_pooled_raw_std)
make_results_table(est_CI_pooled_std, firstcol_values=outcome_names,
                   firstcol_name="Outcome", file_name="tables/main_effects_stand.tex",
                   caption="Main effect of article treatment on environmental attitudes, standardized.",
                   label="tab:main_stand")


## Weighted by ideology-source combination likelihood

meanweight <- mean(d$ideo_outlet_weight)
summary(d$ideo_outlet_weight/meanweight) #interquartile range
est_weight_raw <- lapply(outcomes, run_weighted_main_analysis, standardise_outcomes=TRUE, weights_name="ideo_outlet_weight")
est_weight <- results_to_df(est_weight_raw)
make_results_table(est_weight, firstcol_values=outcome_names,
                   firstcol_name="Outcome", file_name="tables/main_effects_ideoweights.tex",
                   caption="Main effect of article treatment on environmental attitudes, standardized.
                   Responses are weighted by the likelihood of a respondent reading the outlet of their treatment article,
                   given their ideology.",
                   label="tab:main_ideoweights")


##Heterogeneous treatment effects by ideology

est_CI_hetero_raw <- lapply(outcomes, run_hetero_analysis, moderator="ideology_7p_num")
est_CI_hetero <- results_to_df(est_CI_hetero_raw)
make_results_table(est_CI_hetero, firstcol_values=outcome_names,
                   firstcol_name="Outcome", file_name="tables/main_effects_ideo_hetero.tex",
                   caption="Interaction effect between ideology (7-pt. scale from ``Very left-wing'' to ``Very right-wing'')
                   and article treatment on environmental attitudes, standardized.",
                   label="tab:main_effects_ideo_hetero")

#plot treatment effect by ideology
CATE_plots <- lapply(outcomes, function(outcome, moderator="ideology_7p_num"){
  #fit the model
  fit <- get_hetero_fit(outcome, moderator, standardise_outcomes=TRUE, data=d)
  #make newdata set
  newdata <- make_hetero_newdata(fit, moderator, data=d)
  #make a plot
  get_CATE_plot(fit, newdata, moderator, outcome)
})

#combine and print the plots to file in figures folder
pdf(paste0("figures/main_by_7ptideology.pdf"), 8, 4)
wrap_plots(CATE_plots, nrow = 1)
dev.off()


## Characteristics analysis

#fit a model per block, unstandardized characteristics
est_CI_chars_raw_unstd <- lapply(1:max(char_blocks), analyze_one_block, standardise_chars=FALSE)
est_CI_chars_unstd <- results_to_df(est_CI_chars_raw_unstd)
est_CI_chars_unstd <- dplyr::select(est_CI_chars_unstd, -block)
est_CI_chars_unstd <- est_CI_chars_unstd %>% relocate(characteristic)
make_results_table(est_CI_chars_unstd, firstcol_values=char_labels,
                   firstcol_name="Feature", file_name="tables/char_effects_unstand.tex",
                   caption="Effect of features (unstandardized) on environmental attitudes.",
                   label="tab:char_unstand", compact=TRUE)

#fit a model per block, standardized characteristics
est_CI_chars_raw_std <- lapply(1:max(char_blocks), analyze_one_block, standardise_chars=TRUE)
est_CI_chars_std <- results_to_df(est_CI_chars_raw_std)
est_CI_chars_std <- dplyr::select(est_CI_chars_std, -block)
est_CI_chars_std <- est_CI_chars_std %>% relocate(characteristic)
make_results_table(est_CI_chars_std, firstcol_values=char_labels,
                   firstcol_name="Feature", file_name="tables/char_effects_stand.tex",
                   caption="Effect of features (standardized) on environmental attitudes.",
                   label="tab:char_stand", compact=TRUE)

#leaving out blockade (look at number of protesters)
est_CI_protesters_raw <- analyze_one_block(1, standardise_chars=TRUE, all_chars = characteristics[-7],
                                           all_blocks = char_blocks[-7])
est_CI_protesters <- results_to_df(list(est_CI_protesters_raw))
est_CI_protesters["numberOfProtesters",]

#leaving out number of protesters (look at blockade)
est_CI_blockade_raw <- analyze_one_block(1, standardise_chars=TRUE, all_chars = characteristics[-c(1,2)],
                                         all_blocks = char_blocks[-c(1,2)])
est_CI_blockade <- results_to_df(list(est_CI_blockade_raw))
est_CI_blockade["nature.Blockade",]

#leaving out level of disruption to general public (look at perceived disruption)
est_CI_perceived_raw <- analyze_one_block(3, standardise_chars=TRUE, all_chars = characteristics[-4],
                                          all_blocks = char_blocks[-4])
est_CI_perceived <- results_to_df(list(est_CI_perceived_raw))
est_CI_perceived["perceived_disruption",]


## Pooled analysis with non-specific articles added

est_CI_nonspec_raw <- run_main_effect_analyses(outcomes, standardise_outcomes=TRUE, data=d_nonspec)
est_CI_nonspec <- results_to_df(est_CI_nonspec_raw)
make_results_table(est_CI_nonspec, firstcol_values=outcome_names,
                   firstcol_name="Outcome", file_name="tables/main_effects_nonspec.tex",
                   caption="Main effect of article treatment on environmental attitudes, standardized.
                   Includes respondents seeing ten additional articles not covering a specific
                   disruptive protest.",
                   label="tab:main_nonspec")

#n per outcome
t(sapply(outcomes, get_cond_means, data=d_nonspec))[,8]


#### Robustness checks (non-preregistered) ####

##weighting by demographics (age, ideology, sex)

#load two-way population tables (created by raking/raking_joint_probs.R)
load("raking/twoway_frequencies_IAS.Rdata")

#drop four observations with incomplete demographics
d_complete <- subset(d,
                       !is.na(Ideology_Prolific) &
                       !is.na(age_bins) &
                       !is.na(Sex))

#create design with raked ideology, age, sex joint distribution
design <- svydesign(ids = ~1, data = d_complete, weights = ~1)
raked_design <- rake(
  design,
  sample.margins = list(
    ~Ideology_Prolific + age_bins,
    ~Ideology_Prolific + Sex,
    ~age_bins + Sex
  ),
  population.margins = list(pop_IA, pop_IS, pop_AS)
)

#estimate main effect
est_CI_demweight_raw <- lapply(outcomes, run_weighted_main_analysis, standardise_outcomes=TRUE, svy_design=raked_design, data=d_complete)
est_CI_demweight <- results_to_df(est_CI_demweight_raw)
make_results_table(est_CI_demweight, firstcol_values=outcome_names,
                   firstcol_name="Outcome", file_name="tables/main_effects_demweights.tex",
                   caption="Main effect of article treatment on environmental attitudes, standardized.
                   Responses are weighted to representative of the UK population on ideology, age and sex.",
                   label="tab:main_demweights")
plot_pooled_results(est_CI_demweight, outcome_levels=outcomes, file_suffix="_demweights")

#estimate characteristic effects
est_CI_chars_demweight_raw <- lapply(1:max(char_blocks), analyze_one_block, standardise_chars=TRUE, data=d_complete, svy_design=raked_design)
est_CI_chars_demweight <- results_to_df(est_CI_chars_demweight_raw)
plot_char_results(est_CI_chars_demweight, char_levels=characteristics, file_suffix = "_demweights", char_labels=char_labels)
est_CI_chars_demweight <- dplyr::select(est_CI_chars_demweight, -block)
est_CI_chars_demweight <- est_CI_chars_demweight %>% relocate(characteristic)
make_results_table(est_CI_chars_demweight, firstcol_values=char_labels,
                   firstcol_name="Characteristic", file_name="tables/char_effects_demweights.tex",
                   caption="Effect of characteristics (standardized) on environmental attitudes.
                   Responses are weighted to representative of the UK population on ideology, age and sex.",
                   label="tab:char_demweights", compact=TRUE)

#sanity check 1: inspecting the raked probability of each ideology, age, sex combination
prop.table(svytable(~Ideology_Prolific + age_bins + Sex, raked_design))
prop.table(table(d$Ideology_Prolific, d$age_bins, d$Sex)) #compare to the sample
#DK 65+ people are very underrepresented

#sanity check 2: inspecting the weights
d_complete$dem_weight <- weights(raked_design) 
d_complete$dem_weight <- d_complete$dem_weight / mean(d_complete$dem_weight) #normalize
tapply(d_complete$dem_weight, list(d_complete$Ideology_Prolific, d_complete$age_bins, d_complete$Sex), mean)
#DK people indeed receive very high weights, especially if 65+


##Polarization: heterogeneous treatment effects by pre-treatment attitude

est_CI_polarize_raw <- lapply(outcomes, function(outcome) {
  run_hetero_analysis(outcome, moderator=paste0(outcome, "_std"), standardise_outcomes = TRUE)
})
est_CI_polarize <- results_to_df(est_CI_polarize_raw)
make_results_table(est_CI_polarize, firstcol_values=outcome_names,
                   firstcol_name="Outcome/moderator", file_name="tables/main_effects_polarize.tex",
                   caption="Interaction effects between the article treatment and pre-treatment environmental attitudes.
                   Outcome is the same attitude post-treatment. Positive effects indicate polarization. All attitudes
                   standardized.",
                   label="tab:main_polarize")

#correlations between attitudes and ideology
sapply(outcomes, function(outcome) cor(d[,outcome], d$ideology_7p_num, use="pairwise.complete"))


## Characteristics analysis: bivariate

#get characteristics of interest; all but imputation dummies
imputed_dummy <- grepl("_imputed", characteristics)
chars_of_interest <- characteristics[!imputed_dummy]

#estimate a bivariate model for each characteristic
est_CI_bivar_raw <- lapply(chars_of_interest, function(char){
  
  #add characteristics from this and all previous blocks to a model
  #with random effect for each article treatment (id)
  formula <- paste0("outcome_scale_w2 ~ outcome_scale + ", char, "_std + (1 | id)")
  message("fitting bivariate model for characteristic ", char, "\nfomula:\n", formula, "\n")
  
  #fit the model
  fit <- lmer(as.formula(formula), data=d[d$treated==1,])
  
  #extract estimates
  est_CI_onechar <- get_model_estimates(fit, covar_of_interest=paste0(char, "_std"))
  
  #add characteristic indicator
  est_CI_onechar$characteristic <- char
  est_CI_onechar$block <- char_blocks[char]
  
  return(est_CI_onechar)
  
})
est_CI_bivar <- results_to_df(est_CI_bivar_raw)
plot_char_results(est_CI_bivar, char_levels=characteristics, file_suffix = "_bivariate", char_labels=char_labels)


## Characteristics analysis: individual outcomes

# Generate results for all outcomes
outcomes <- c("Concern", "Policy", "Behavior")
est_CI_chars_list <- lapply(outcomes, function(outcome) {
  
  message("fitting models for outcome ", outcome)
  
  #get results for all blocks for this outcome
  est_CI_chars_raw <- lapply(1:max(char_blocks), analyze_one_block,  standardise_chars=TRUE,
                             outcome = outcome, data=d, standardise_outcomes=TRUE)
  results_to_df(est_CI_chars_raw)
  
})
names(est_CI_chars_list) <- outcomes

#combine all dfs and apply FDR correction
est_CI_chars_byoutc <- results_to_df(est_CI_chars_list)
min(est_CI_chars_byoutc$fdr) #none significant

# Create individual plots
plot_list <- lapply(seq_along(outcomes), function(i) {
  outcome <- outcomes[i]
  p <- plot_char_results(est_CI_chars_list[[outcome]],
                         char_levels = characteristics, file_suffix = paste0("_", outcome),
                         char_labels = char_labels)
  p <- p +  ylab(outcome) #update y-axis label to reflect outcome
  
  # Suppress x-axis labels and legend for all except the last plot
  if (i < length(outcomes)) {
    p <- p + theme(axis.text.x = element_blank(),
                   axis.title.x = element_blank(),
                   legend.position="none")
  }
  return(p)
})

# Combine plots vertically
combined_plot <- plot_list[[1]] / plot_list[[2]] / plot_list[[3]]
print(combined_plot)
ggsave("figures/effects_of_characteristics_by_outcome.pdf", combined_plot,
       width=9, height=9, bg="white")