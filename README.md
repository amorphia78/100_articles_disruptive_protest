# 100_articles_disruptive_protest

## Technical Materials for manuscript "How 100 news articles about disruptive protest affect environmental attitudes"

This repository comprises the Technical Materials for the anonymous manuscript "How 100 news articles about disruptive protest affect environmental attitudes" which is currently under blind review. There is a [license](LICENCE).

## Contents

### [/articles/](/articles/)

Contains all 110 articles (100 specific and 10 general) in HTML format. To view the articles easily in your browser, rather than seeing the HTML source, use [this link](https://raw.githack.com/amorphia78/tmp_dis_prot_package/main/articles/article_index.html).

For a material availability statement and full description of how the articles were screened, sampled, summarised, and checked, see [this document](/doc/article_processing.pdf) (LLM prompts are in [this document](/doc/article_processing_llm_prompts.pdf)).

### [/word_count/](/word_count/)

Running [/word_count/src/code_and_count_article_words.py](/word_count/src/code_and_count_article_words.py) will process the specific articles to recreate the word count output files in [/word_count/](/word_count/), also using additional files, as described in [this document](/doc/article_word_count_details.md).

### [/llm_caches/](/llm_caches/)

Contains cached LLM prompt responses so that [code_and_count_article_words.py](/word_count/src/code_and_count_article_words.py) can be run by those without an Anthropic API key, using the [process_with_cache()](/word_count/src/llmproc_core.py#L60) function.

### [/experiment/](/experiment/)

Contains .R files and data to produce the analyses in the main text (`experiment_analyses.R`) and the appendices (`appendix_analyses.R`), respectively. A separate script (`plot_all_ratings.R`) produces Figure 1 in the manuscript, showing histograms of the protest/article feature distributions, as well as a feature intercorrelation plot for the Appendices. These files should be run with the directory they are in (i.e. [/experiment/](/experiment/)) as the working directory.

Data from the experiment (all wave 1 respondents) are in the file `disruption_stimulus_data_clean.RData` (and also in `disruption_stimulus_data_clean.csv` for easier visual inspection/import into other statistical software). The file `all_ratings_clean.csv` contains the ratings of the articles produced by research assistants, crowd coders and an LLM.

The R scripts `load_and_join_data.R` and `functions.R` are called by the analysis scripts above and contain helper code respectively for cleaning the data (including joining experiment and rating data) and for analyzing and plotting results. `raking/twoway_frequencies_IAS.Rdata` contains the two-way joint distributions of ideology, age and sex in the UK population that are necessary to rake their full joint distribution, which is necessary for representativeness weighting.

The Figures and Tables folders contain the graphs and LaTeX tables produced by the analysis scripts. These are the figures and tables that appear in the main text and appendices of the paper.

### [/doc/](/doc/)

Contains documentation files linked to above, including details on article sampling and production, and additionally, results of two [pilot tests for rating](/doc/pilot_results.pdf) article/protest features, and [a priori power analyses](/doc/power_analysis_results.pdf).
