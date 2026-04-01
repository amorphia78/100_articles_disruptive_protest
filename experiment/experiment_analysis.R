
source("functions.R")
source("load_and_join_data.R")


## Main effect analysis: pooled effect of all treatments

#create df with pooled analysis results and plot them
est_CI_pooled_raw_std   <- run_main_effect_analyses(outcomes, standardise_outcomes=TRUE, data=d)
est_CI_pooled_std <- results_to_df(est_CI_pooled_raw_std)
plot_pooled_results(est_CI_pooled_std, outcome_levels=outcomes, file_suffix="_standardised")

#unstandardized, for in-text results
est_CI_pooled_raw   <- run_main_effect_analyses(outcomes, standardise_outcomes=FALSE, data=d)
est_CI_pooled <- results_to_df(est_CI_pooled_raw)
est_CI_pooled


## Weighted by ideology-source combination likelihood

est_weight <- lapply(outcomes, run_weighted_main_analysis, standardise_outcomes=TRUE, weights_name="ideo_outlet_weight")
est_weight <- do.call(rbind, est_weight)

#heterogeneous treatment effects by ideology
est_hetero <- lapply(outcomes, run_hetero_analysis, moderator="ideology_7p_num")
est_hetero <- do.call(rbind, est_hetero)


## Mediation by environmentalist identity

#calculate first-differences
d$identity_change <- d$Envir_identif_w2 - d$Envir_identif
d$outcome_scale_change <- d$outcome_scale_w2 - d$outcome_scale

#fit mediation models with random effect of article
fit_MtoT <- glmer(identity_change ~ treated + (- 1 + treated | id), data=d)
fit_YtoM <- glmer(outcome_scale_change ~ treated + identity_change + (- 1 + treated | id), data=d)
fit_med <- mediate(fit_MtoT, fit_YtoM, sims=500, treat="treated", mediator="identity_change")
summary(fit_med)
#note: preregistration mistakenly included cluster="id"; this is wrong and will not run
#note: glmer() with family=linear instead of the equivalent lmer(), otherwise mediate throws an error
#as a result of the potential non-linearity (the g in glmer), mediate() will report separate effects for
#treated and control groups, but they are identical, because the model is in fact linear


## Pooled analysis with non-specific articles added

est_CI_nonspec_raw <- run_main_effect_analyses(outcomes, standardise_outcomes=TRUE, data=d_nonspec)
est_CI_nonspec <- results_to_df(est_CI_nonspec_raw)


## Characteristics analysis

#fit a model per block
est_CI_chars_raw <- lapply(1:max(char_blocks), analyze_one_block, standardise_chars=TRUE)
est_CI_chars <- results_to_df(est_CI_chars_raw)
plot_char_results(est_CI_chars, char_levels=characteristics, file_suffix = "_standardised", char_labels=char_labels)

