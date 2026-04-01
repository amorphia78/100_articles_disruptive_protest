#libraries
library(lme4)
library(lmerTest)
library(dplyr)
library(multtest) #install with bioconductor
library(mediation)
library(ggplot2)
library(survey)
library(xtable)
library(marginaleffects)

#arguments to prevent silent partial matching of column names
options(
  warnPartialMatchDollar = TRUE,
  warnPartialMatchAttr = TRUE,
  warnPartialMatchArgs = TRUE
)

##Data processing

# Function to standardize outcomes by wave 1 SD
standardise_outcomes <- function(data, outcomes) {
  data_std <- data
  for (outcome in outcomes) {
    w1_sd <- sd(data[[outcome]], na.rm = TRUE)
    data_std[[paste0(outcome, "_std")]] <- data[[outcome]] / w1_sd
    data_std[[paste0(outcome, "_w2_std")]] <- data[[paste0(outcome, "_w2")]] / w1_sd
  }
  return(data_std)
}

# Function to standardize characteristics by their SD
standardise_chars <- function(data, chars) {
  data_std <- data
  for (char in chars) {
    char_sd <- sd(data[[char]], na.rm = TRUE)
    data_std[[paste0(char, "_std")]] <- data[[char]] / char_sd
  }
  return(data_std)
}


##Analysis

#function to get the main treatment effect (and SE, p-val, CI) for all outcomes,
#either standardized or not
run_main_effect_analyses <- function(outcomes, standardise_outcomes, data=d) {
  
  results <- lapply(outcomes, function(outcome) {
    
    #print which model we are fitting
    standardisation_label <- if( standardise_outcomes ) "standardised" else "unstandardised"
    message(paste0("Fitting ", standardisation_label, " model for ", outcome))
    
    #get the outcome (w2 and w1) variable names (standardized or not)
    std_suffix <- if( standardise_outcomes ) "_std" else ""
    outcome_w1 <- paste0(outcome, std_suffix)
    outcome_w2 <- paste0(outcome, "_w2", std_suffix)
    
    #fit the model and print treatment effect p-value
    fit <- lmer(get(outcome_w2) ~ 1 + treated + get(outcome_w1) + (-1 + treated | id), data = data)
    message(paste0("  p-value for treated = ", format.pval(summary(fit)$coefficients["treated", "Pr(>|t|)"], digits = 3)))

    #extract RE model estimates
    est_CI <- get_model_estimates(fit, covar_of_interest = "treated")
    est_CI <- cbind(outcome, est_CI)
    
  })
  
  return(results)
}

#function to run weighted main effect analysis for one outcome
run_weighted_main_analysis <- function(outcome, standardise_outcomes, weights_name=NULL, svy_design=NULL, data=d){
  
  if(is.null(weights_name) & is.null(svy_design)){
    stop("You must pass a value for either weights_name (column of weights in the data)
         or svy_design (a design created by svydesign() in the survey package).")
  }
  
  #get the new characteristic variable names (standardized or not)
  std_suffix <- if( standardise_outcomes ) "_std" else ""
  outcome_w1 <- paste0(outcome, std_suffix)
  outcome_w2 <- paste0(outcome, "_w2", std_suffix)
  
  #create design from weights variable if no design was given
  if(is.null(svy_design)){
    svy_design <- svydesign(
      ids = ~1, # no clustering
      weights = reformulate(weights_name),   # survey weight variable
      data = data
    )
  }
  
  #fit weighted model (no random effects)
  formula <- paste0(outcome_w2, " ~ ", outcome_w1, " + treated")
  fit <- svyglm(
    as.formula(formula),
    design = svy_design
  )
  
  #extract model estimates
  est_CI <- get_model_estimates(fit, covar_of_interest="treated")
  est_CI <- cbind(outcome, est_CI)
  
  # previously done with WeMix:
  # #fit weighted model
  # data$weights_L2 <- 1
  # formula <- paste0(outcome_w2, " ~ ", outcome_w1, " + treated + (-1 + treated | id)")
  # fit <- mix(as.formula(formula), data = data, weights=c(weights_name, "weights_L2"))
  # wald <- waldTest(fit, type="beta", coefs = "treated")
  # 
  # #extract model estimates
  # est <- summary(fit)$coef["treated",,drop=F]
  # p <- wald$p
  # est_CI <- data.frame(outcome=outcome, est, p)
  
  return(est_CI)
  
}

#function to extract estimates for covariate(s) of interest from fitted RE model
get_model_estimates <- function(fit, covar_of_interest){
  
  #get effect estimates
  coefs <- coef(summary(fit))[covar_of_interest, , drop=F]
  est <- coefs[, "Estimate"]
  se <- coefs[, "Std. Error"]
  p <- coefs[, "Pr(>|t|)"]
  #p-values are added due to package lmerTest
  
  #get confidence intervals
  CI <- confint(fit, parm = covar_of_interest )
  CI_low <- CI[, "2.5 %"]
  CI_high <- CI[, "97.5 %"]
  
  #return all results in dataframe
  return(data.frame(est, se, p, CI_low, CI_high))
  
}

#function to analyze one block's worth of characteristics, controlling for all from previous block
analyze_one_block <- function(block, standardise_chars, outcome="outcome_scale", all_chars=characteristics,
                              all_blocks=char_blocks, data=d, standardise_outcomes=FALSE, return_models=FALSE,
                              design=NULL){
  #note: standardise_outcomes is set to FALSE by default, because the default outcome, outcome_scale, is already
  #standardized

  #get new characteristics in this block
  chars_to_include <- all_chars[all_blocks == block]

  #get the new characteristic variable names(standardized or not)
  std_suffix_char <- if( standardise_chars ) "_std" else ""
  chars_to_include <- paste0(chars_to_include, std_suffix_char)

  #get characteristics in previous blocks
  covariates <- all_chars[all_blocks < block]
  
  #get the outcome (w2 and w1) variable names (standardized or not)
  std_suffix <- if( standardise_outcomes ) "_std" else ""
  outcome_w1 <- paste0(outcome, std_suffix)
  outcome_w2 <- paste0(outcome, "_w2", std_suffix)

  #add characteristics from this and all previous blocks to a model
  #with random effect for each article treatment (id)
  RH_vars <- paste(c(chars_to_include, covariates), collapse = " + ")

  #fit model
  if(is.null(design)){
    formula <- paste0(outcome_w2, " ~ ", outcome_w1, " + ", RH_vars, " + (1 | id)")
    fit <- lmer(as.formula(formula), data=data[data$treated==1,])
  } else {
    #fit weighted model (no random effects)
    formula <- paste0(outcome_w2, " ~ ", outcome_w1, " + ", RH_vars)
    fit <- svyglm(
      as.formula(formula),
      design = design
    )
  }
  
  message("fitting model for block ", block, "\nfomula:\n", formula, "\n")

  #leave out "imputed" dummies from reporting
  imputed_dummy <- grepl("_imputed", chars_to_include)
  chars_of_interest <- chars_to_include[!imputed_dummy]

  #extract estimates
  est_CI_block <- get_model_estimates(fit, covar_of_interest=chars_of_interest)

  #add characteristic and block indicators
  est_CI_block$characteristic <- chars_of_interest
  est_CI_block$block <- block

  if(return_models){
    return(list(estimates = est_CI_block, model = fit))
  } else {
    return(est_CI_block)
  }
  
}

#function to convert a list of extracted coefficients
#from get_model_estimates() to a dataframe, and add
#a column of FDR-adjusted p-values
results_to_df <- function(est_CI_raw){
  
  #combine all the results row-wise
  est_CI <- as.data.frame(do.call(rbind, est_CI_raw))
  
  #add two-stage FDR-adjusted p-values
  fdr_result <- mt.rawp2adjp(est_CI$p, proc="ABH")
  est_CI$fdr <- fdr_result$adjp[order(fdr_result$index), "ABH"]
  #this is Adaptive two-stage Benjamini–Hochberg from Benjamini et al. (2006)
  #classic non-adaptive BH (1995) is: p.adjust(outputs$p, method="BH")
  
  return(est_CI)
  
}

#function to calculate the raw conditional means for one outcome: pre/post for treatment/control
get_cond_means <- function(outcome, data=d) {
  
  #kick out outcome-specific dropouts (respondents who were missing outcome in either wave)
  is_complete <- as.vector( !is.na(data[outcome]) & !is.na(data[paste0(outcome,"_w2")]) )
  d_complete <- data[is_complete,]
  n <- sum(is_complete)
  
  #calculate means
  w1_means <- tapply(d_complete[[outcome]], d_complete$treated, mean, na.rm=T)
  w2_means <- tapply(d_complete[[paste0(outcome,"_w2")]], d_complete$treated, mean, na.rm=T)
  
  #calculate differences
  control_diff <- w2_means[1] - w1_means[1]
  treat_diff <- w2_means[2] - w1_means[2]
  did <- treat_diff - control_diff
  
  result <- round(c(w1_means[1], w2_means[1], control_diff,
                    w1_means[2], w2_means[2], treat_diff,
                    did, n), 3)
  return(result)
  
}

#function to fit heterogeneous treatment effect model (of main effect) for one outcome
get_hetero_fit <- function(outcome, moderator, standardise_outcomes=TRUE, data=d){
  
  #get the new characteristic variable names (standardized or not)
  std_suffix <- if( standardise_outcomes ) "_std" else ""
  outcome_w1 <- paste0(outcome, std_suffix)
  outcome_w2 <- paste0(outcome, "_w2", std_suffix)
  
  #fit interaction model
  formula <- paste0(outcome_w2, " ~ ", outcome_w1, " + ", moderator, "*treated", " + (-1 + treated | id)")
  fit <- lmer(as.formula(formula), data=data)
  
  return(fit)
  
}

#function to run heterogeneous treatment effect analysis (of main effect) for one outcome
run_hetero_analysis <- function(outcome, moderator, standardise_outcomes=TRUE, data=d){
  
  #fit the model
  fit <- get_hetero_fit(outcome, moderator, standardise_outcomes=standardise_outcomes, data=data)
  
  #get names of moderator covariates
  coefs <- summary(fit)$coefficients
  covar_of_interest <- grep(paste0(moderator, ".*treated"), rownames(coefs), value=TRUE)
  
  #extract model estimates
  est_CI <- get_model_estimates(fit, covar_of_interest=covar_of_interest)
  est_CI <- cbind(outcome, est_CI)
  
  return(est_CI)
  
}

#function to make newdata for marginaleffects from model object values of a moderator 
make_hetero_newdata <- function(fit, moderator, data=d, modvalues=NULL){
  
  #if no values of the moderator whose CATEs we want to know
  #are given, use all unique values
  if(is.null(modvalues)){
    modvalues <- unique(d[,moderator])
    modvalues <- modvalues[!is.na(modvalues)]
  }
  
  #make a dataset for getting the marginal effects
  newdata <- do.call(
    datagrid,
    c(
      list(model = fit, treated = 0),
      setNames(list(modvalues), moderator)
    )
  )
  
  return(newdata)
  
}

get_CATEs <- function(fit, newdata, moderator){
  
  #get marginal effect of Treated for different values of the moderator
  CATEs <- slopes(fit, newdata = newdata)
  #note: only need one Treated value, as model is linear: other values would give same result
  CATEs <- tail(CATEs, nrow(newdata))[c(moderator, "estimate","conf.low","conf.high")]
  
  return(CATEs)
  
}


##Plotting

#function to plot effect estimates and CIs for different outcomes
plot_pooled_results <- function(est_CI, outcome_levels, file_suffix=""){
  
  #set level order
  est_CI$outcome <- factor(est_CI$outcome, levels=outcome_levels)
  
  #replace level names for Behavior and Environmentalist identity
  levels(est_CI$outcome)[c(4,5)] <- c("Intentions", "Envir. identity")
  
  #make plot and print to file in figures folder
  pdf(paste0("figures/main_effects_by_outcome", file_suffix, ".pdf"), 10, 5)
  print(ggplot(est_CI, aes(x=outcome, y=est)) +
          geom_hline(yintercept=0, color="dark grey") +
          geom_errorbar(aes(ymin=CI_low, ymax=CI_high), width=.03, color="#b85450") +
          geom_point(color="#b85450") +
          ylab(paste0("Effect of disruption treatment")) +
          theme_bw() +
          theme(axis.title.x=element_blank(),
                axis.title.y=element_text(size=15),
                axis.text=element_text(size=15))
  )
  dev.off()
  
}

#function to plot conditional treatment effects from slopes() fit
get_CATE_plot <- function(fit, newdata, moderator, outcome){
  
  #make plot
  p <- plot_slopes(
    fit,
    variables = "treated",
    condition = moderator,
    newdata = newdata
  )
  
  #replace level name for Environmentalist identity
  if(outcome == "Envir_identif"){
    outcome_name <- "Envir. identity"
  } else if (outcome == "Behavior") {
    outcome_name <- "Intentions"
  } else {
    outcome_name <- outcome
  }
  
  #tweak appearance
  p <- p +
    theme_bw() +
    theme(axis.title.y=element_blank()) +
    ggtitle(outcome_name) + 
    scale_y_continuous(breaks = c(-.25, 0, .25, .5, .75), limits=c(-.4, .8)) + 
    xlab("Ideology") +
    geom_hline(yintercept=0, color="dark grey", linetype="dashed")
  
  #suppress y axis ticks and text for all but Salience
  if(outcome != "Salience"){
    p <- p +
      theme(axis.text.y=element_blank(),
            axis.ticks.y=element_blank())
  }
  
  #set line color
  for (i in seq_along(p$layers)) {
    if (inherits(p$layers[[i]]$geom, "GeomLine")) {
      p$layers[[i]]$aes_params$colour <- "#b85450"
    }
  }
  
  return(p)
  
}

# Data structure for label mapping
char_labels <- c(
  "numberOfProtesters" = "Number of Protesters",
  "levelOfDisruption.BusinessDamaging" = "Disruption to: polluting business",
  "levelOfDisruption.PublicEveryday" = "Disruption to: public",
  "levelOfDisruption.GovernmentOrAuthority" = "Disruption to: authority",
  "levelOfDisruption.CultureOrSport" = "Disruption to: culture/sport",
  "nature.Blockade" = "Tactic: blockade",
  "nature.Attached" = "Tactic: attachment",
  "nature.AlteratVandal" = "Tactic: vandalism (often minor)",
  "nature.Interrupting" = "Tactic: event interruption",
  "portrayal" = "Article: positive portrayal",
  "words.general_disruption" = "Article: words on disruption",
  "words.protester_messaging" = "Article: words on protester message",
  "words.negative_comments" = "Article: words negative about protest",
  "perceived_disruption" = "Public perception: protest disruptive",
  "ordinary" = "Public perception: protesters ordinary",
  "acceptance" = "Public perception: protest acceptable"
)

#function to plot effect estimates and CIs for different characteristics
plot_char_results <- function(est_CI, char_levels, file_suffix="", char_labels){
  
  #remove "_std" from variable names
  est_CI$characteristic <- gsub("_std", "", est_CI$characteristic)

  if(!is.null(char_labels)){  
    #apply labels if provided
    est_CI$characteristic <- recode(est_CI$characteristic, !!!char_labels)
    est_CI$characteristic <- factor(est_CI$characteristic, levels=unname(char_labels))
  } else {
    #otherwise just set level order
    est_CI$characteristic <- factor(est_CI$characteristic, levels=char_levels)
  }
  
  pdf(paste0("figures/effects_of_characteristics", file_suffix, ".pdf"), 10, 5)
  p <- ggplot(est_CI, aes(x=characteristic, y=est, color=as.factor(block))) +
    geom_hline(yintercept=0, color="dark grey") +
    geom_errorbar(aes(ymin=CI_low, ymax=CI_high), width=.1) +
    geom_point() +
    ylab("Effect of characteristic") +
    theme_bw() +
    theme(axis.title.x=element_blank(),
          axis.text.x = element_text(angle = 45, hjust=1),
          axis.title.y=element_text(size=12),
          axis.text=element_text(size=11),
          legend.position = "bottom",
          legend.direction = "horizontal",
          legend.box.margin = margin(t = -10)
    ) + 
    labs(color="Causal block") +
    scale_color_manual(values=c("#6c8ebf", "#82b366", "#d6b656", "#b46504"))
  print(p)
  dev.off()
  
  return(p) #return the plot in case we want to combine several
  
}


## Making results tables

#turn dataframe of estimates and CIs into Latex table
make_results_table <- function(est_CI, firstcol_values, firstcol_name, file_name, caption, label, compact=FALSE){
  
  #replace first column (outcome or characteristic) values
  est_CI[,1] <- firstcol_values
  
  #if table needs to be compact, replace two CI columns with one containing a range
  if("CI_low" %in% colnames(est_CI) & compact){
    
    est_CI$CI_low <-  sprintf("%.2f -- %.2f",
                              est_CI$CI_low,
                              est_CI$CI_high)
    est_CI <- dplyr::select(est_CI, -CI_high)
    
    #set column names and printing digits
    colnames(est_CI) <- c(firstcol_name, "Est.", "SE", "p", "CI", "FDR")
    digits <- c(0,0,2,2,3,0,3)
    
  } else {
    
    #otherwise just set column names and printing digits
    colnames(est_CI) <- c(firstcol_name, "Est.", "SE", "p", "CI, min", "CI, max", "p (FDR)")
    digits <- c(0,0,2,2,3,2,2,3)
    
  }
  
  #print to Latex file
  print(est_CI)
  est_CI_x <- xtable(est_CI, digits = digits,
                     caption = caption,
                     label = label)
  print(est_CI_x, file=file_name, include.rownames=FALSE,
        table.placement = "h!t")
  
}

