# Documentation of derivation of word count variables

## Context

See Main Text Methods section and Supplementary Material section D for a description of the role of word count variables.

Note that as well as the three word counts described in those materials (words on protester messaging, disruption, and negative comments about the protest), this code also counts words on positive comments about the protest. This variable was [dropped during piloting](/doc/pilot_results.pdf) but retained in prompts for stability between piloting and final processing.

## Shared code

The process is fully documented by means of provision of the Python code which generated the counts. Below we also include a natural language summary of this process. Running the script [/word_count/src/code_and_count_article_words.py](/word_count/src/code_and_count_article_words.py) processes the [specific articles](/articles/specific) and recreates the word count output files in [/word_count/](/word_count/). The script uses two additional Python source files: LLM API interface functions are in [/word_count/src/llmproc_core.py](/word_count/src/llmproc_core.py) and prompts are in [/word_count/src/prompts_for_code_and_count_article_words.py](/word_count/src/prompts_for_code_and_count_article_words.py). The script can be run without an Anthropic API key because prompt responses are [cached](/llm_caches/). 

## Process summary

Each article is processed in turn through a sequence of LLM prompts. Articles are tagged for starts and ends of content blocks, allowing subsequent deterministic non-LLM code to use the tags to count words in blocks.

In an initial very long prompt, the LLM is given:

1. Our standard definitions of relevant concepts such as disruptive environmental protest.
1. Definitions of the four types of content to be identified for marking and counting.
1. A syntax for inserting tags marking the starts and ends of blocks of the four types of content.
1. Four example articles which have been tagged in this manner, including comments justifying tag positions with reference to the definitions.
1. The article to tag, and an instruction to return the article exactly as provided but with tags inserted.

Pictures are not present in the article in the prompt, but both the figure captions and the alt text is present, with pre-inserted tags identifying this text as what it is, and the prompt contains instructions for including the picture material in content blocks as appropriate. For example, a picture might be included in a protester messaging block if it contains a banner with legible text.

The returned tagged article is checked for compliance with the required tagging syntax. Whether this check passes or fails, a second prompt is issued, asking the LLM to check its own work and see if it can be improved. If a tagging syntax error occurred, this error is pointed out.

Of the 100 articles, after the first round, there were tagging syntax errors for six, and after the second round, for one article only.

The single article for which the LLM could not produce syntactically correct tagging was manually corrected (correction file [here](/word_count/corrections.txt)).

After tagging, deterministic non-LLM code used the tags to count the number of words of each content type. In this context, a picture is worth 50 words.

## Output files in [/word_count/](/word_count/)

Word counts after the first tagging round are in [block_word_counts_first.tsv](/word_count/block_word_counts_first.tsv), after the second tagging round are in [block_word_counts_second.tsv](/word_count/block_word_counts_second.tsv), and the final counts (after manual correction of tagging for one article) are in [block_word_counts_final.tsv](/word_count/block_word_counts_final.tsv)

A text log file containing all LLM output and tagging error detection (essentially an audit trail) in is [article_content_block_word_counts_LLMResponses.txt](/word_count/article_content_block_word_counts_LLMResponses.txt).

A JSON file [llm_coded_content_blocks.json](/word_count/llm_coded_content_blocks.json) contains both tagged articles and word counts in a more structured format, after the second LLM pass.