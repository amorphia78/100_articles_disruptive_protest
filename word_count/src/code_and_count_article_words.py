# Note to self from author: originally called processCodedTextBlocks.py

import prompts_for_code_and_count_article_words as pr
import json
import llmproc_core as llm
import datetime
import os
from bs4 import BeautifulSoup, Comment
import re
import warnings

client = llm.load_client()
timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
llm_system_instruction = ""

warning_log_filename = f"warnings_{timestamp}.log"

def custom_formatwarning(message, category, *_args, **_kwargs ):
    formatted_warning = f"{datetime.datetime.now()}: {category.__name__}: {message}\n"
    with open(warning_log_filename, 'a') as log_file:
        log_file.write(formatted_warning)
    return formatted_warning

warnings.formatwarning = custom_formatwarning

def llm_tag_first_go(article):
    article_string = reconstitute_article_string(article)
    prompt = pr.tag_instructions_prompt_intro + article_string + pr.tag_instructions_prompt_end
    return llm.send_prompt(prompt)

def llm_tag_second_go_after_error(article):
    return llm_tag_second_go( article, pr.have_another_go_after_error_prompt + article["tag_error_message"] )

def llm_tag_second_go_no_error(article):
    return llm_tag_second_go( article, pr.have_another_go_no_error_prompt )

def llm_tag_second_go(article, have_another_go_prompt):
    article_string = reconstitute_article_string(article)
    original_prompt = pr.tag_instructions_prompt_intro + article_string + pr.tag_instructions_prompt_end
    return llm.send_prompt(have_another_go_prompt, prior_prompt = original_prompt, prior_llm = article["tag_first_go"])

def reconstitute_article_string(article):
    return_string = f"ID: {article['id']}\nSource: {article['source']}\nTitle: {article['title']}\n"
    if article.get("subtitle"):
        return_string += f"Subtitle: {article['subtitle']}\n"
    return return_string + f"Content: {article['main_content']}"

def parse_article_from_tag_string(content):
    return list(parse_articles_string(content).values())[0]

def parse_articles_string(content):
    coded_articles = {}
    current_article = {}
    content_lines = []
    for line in content.splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith('ID:'):
            if current_article:
                if content_lines:
                    current_article['main_content'] = '\n'.join(content_lines)
                article_id = current_article['id']
                coded_articles[article_id] = current_article.copy()
            current_article = {}
            content_lines = []
            current_article['id'] = line[3:].strip()
        elif line.startswith('Source:'):
            current_article['source'] = line[7:].strip()
        elif line.startswith('Title:'):
            current_article['title'] = line[6:].strip()
        elif line.startswith('Subtitle:'):
            current_article['subtitle'] = line[9:].strip()
        elif line.startswith('Content:'):
            if line[8:].strip():  # If there's content on the same line
                content_lines.append(line[8:].strip())
        else:
            content_lines.append(line)
    if current_article:
        if content_lines:
            current_article['main_content'] = '\n'.join(content_lines)
        article_id = current_article['id']
        coded_articles[article_id] = current_article.copy()
    return coded_articles

def parse_articles_file(filename):
    content = open(filename, 'r', encoding='utf-8').read()
    return parse_articles_string(content)

def parse_articles_from_html_directory(directory_path):
    coded_articles = {}

    # Process all HTML files in the directory
    for filename in os.listdir(directory_path):
        if filename.endswith('.html'):
            filepath = os.path.join(directory_path, filename)

            # Extract source from filename (everything before first underscore)
            source = filename.split('_')[0] if '_' in filename else 'Unknown'

            with open(filepath, 'r', encoding='utf-8') as file:
                html_content = file.read()

            # Parse HTML with BeautifulSoup
            soup = BeautifulSoup(html_content, 'html.parser')

            # Extract article ID from HTML comment
            article_id = None
            for comment in soup.find_all(string=lambda text: isinstance(text, Comment)):
                id_match = re.search(r'Article ID:\s*(.+)', comment.strip())
                if id_match:
                    article_id = id_match.group(1)
                    break

            if not article_id:
                print(f"Warning: No article ID found in {filename}")
                continue

            current_article = {
                'id': article_id,
                'source': source
            }

            # Extract title from h1
            h1_tag = soup.find('h1')
            if h1_tag:
                current_article['title'] = h1_tag.get_text(strip=True)
                title_word_count = len(current_article['title'].split())
            else:
                print(f"Warning: No title (h1) found for article {article_id}")
                title_word_count = 0

            # Extract subtitle from h2
            h2_tag = soup.find('h2')
            subtitle_word_count = 0
            if h2_tag:
                current_article['subtitle'] = h2_tag.get_text(strip=True)
                subtitle_word_count = len(current_article['subtitle'].split())

            # Extract content
            content_lines = []

            # Find the main content area (everything after h1 and h2)
            # Start processing after the h2 (or h1 if no h2)
            start_tag = h2_tag if h2_tag else h1_tag

            if start_tag:
                for element in start_tag.find_next_siblings():
                    if element.name == 'p':
                        # Process paragraph text
                        text = element.get_text(strip=True)
                        if text:
                            content_lines.append(text)

                    elif element.name == 'figure':
                        # Process images with captions
                        img = element.find('img')
                        figcaption = element.find('figcaption')

                        if img and figcaption:
                            caption_text = figcaption.get_text(strip=True)
                            alt_text = img.get('alt', '')  # Get alt text if it exists
                            # Combine caption and alt text if both exist
                            if alt_text and alt_text != caption_text:
                                combined_text = f"{caption_text} (Alt: {alt_text})"
                            else:
                                combined_text = caption_text
                            content_lines.append(f'#PH #CS {combined_text} #CE')

            # Join content lines and count words
            content_word_count = 0
            if content_lines:
                current_article['main_content'] = '\n'.join(content_lines)
                # Count words in content, excluding image placeholder tags
                for line in content_lines:
                    if not line.startswith('#PH'):
                        content_word_count += len(line.split())
                    else:
                        # Count words in caption (between #CS and #CE)
                        caption_match = re.search(r'#CS (.+?) #CE', line)
                        if caption_match:
                            content_word_count += len(caption_match.group(1).split())

            # Add to coded_articles dictionary
            coded_articles[article_id] = current_article

            # Print parsing summary
            print(f"Parsed HTML file for {article_id}, title {title_word_count}, "
                  f"subtitle {subtitle_word_count}, content {content_word_count}")

    return coded_articles

def ensure_tags_have_spaces(content):
    """Ensure all tags are properly separated by spaces."""
    for tag in ['#DS', '#DE', '#PS', '#PE', '#MS', '#ME', '#AS', '#AE', '#NS', '#NE', '#PH', '#CS', '#CE']:
        content = content.replace(tag, f' {tag} ')
    return content

class InvalidTagNestingError(Exception):
    """Custom exception for invalid tag nesting"""

    def __init__(self, message, word_list=None, error_position=None):
        super().__init__(message)
        self.word_list = word_list
        self.error_position = error_position

    def get_context(self):
        if self.word_list is None or self.error_position is None:
            return None
        start = max(0, self.error_position - 10)
        end = min(len(self.word_list), self.error_position + 11)
        return self.word_list[start:end]

def analyze_content(content):
    """Analyze content with multiple block types."""
    # Define block types and their tags
    block_types = {
        'general_disruption': {'start': '#DS', 'end': '#DE'},
        'protester_messaging': {'start': '#MS', 'end': '#ME'},
        'positive_comments': {'start': '#PS', 'end': '#PE'},
        'negative_comments': {'start': '#NS', 'end': '#NE'}
    }

    # Special tags that don't define blocks
    special_tags = {'#PH', '#CS', '#CE'}

    # Initialize statistics
    stats = {'total_words': 0, 'total_pictures': 0}
    for block_type in block_types:
        stats[f'{block_type}_words'] = 0
        stats[f'{block_type}_pictures'] = 0

    # Prepare content
    content = ensure_tags_have_spaces(content)

    # Add spaces around punctuation to prevent word merging (for some reason the LLM is sometimes omitting whitespace)
    # BUT preserve (Alt: pattern for alt text detection
    content = re.sub(r'(?<!\(Alt)([.,!?;:)])', r' \1', content)  # Space before punctuation, except after (Alt
    content = re.sub(r'\((?!Alt:)', r'( ', content)  # Space after opening paren, except for (Alt:
    content = re.sub(r'\s+', ' ', content)  # Normalize multiple spaces

    words = content.split()

    # Track depth of each block type
    block_depths = {block_type: 0 for block_type in block_types}

    # Track caption and alt text state
    in_caption = False
    in_alt_text = False

    # Process words
    for i, word in enumerate(words):
        # Handle caption tags
        if word == '#CS':
            in_caption = True
            continue
        elif word == '#CE':
            in_caption = False
            in_alt_text = False  # Reset alt text flag when leaving caption
            continue

        # Detect alt text within captions
        if in_caption:
            if word.startswith('(Alt:'):
                in_alt_text = True
            if in_alt_text and word.endswith(')'):
                in_alt_text = False
                continue  # Skip the closing word with )
            if in_alt_text:
                continue  # Skip all words inside alt text

        if word in special_tags:
            if word == '#PH':
                stats['total_pictures'] += 1
                for block_type, depth in block_depths.items():
                    if depth > 0:
                        stats[f'{block_type}_pictures'] += 1
            continue

        # Check if it's a block tag
        is_tag = False
        for block_type, tags in block_types.items():
            if word == tags['start']:
                if block_depths[block_type] > 0:
                    raise InvalidTagNestingError(
                        f"Nested {block_type} blocks are not allowed",
                        words,
                        i
                    )
                block_depths[block_type] += 1
                is_tag = True
                break
            elif word == tags['end']:
                if block_depths[block_type] == 0:
                    raise InvalidTagNestingError(
                        f"Found end tag without matching start tag for {block_type}",
                        words,
                        i
                    )
                block_depths[block_type] -= 1
                is_tag = True
                break

        # Word is not a tag, count it if it contains letters (and not just punctuation)
        if not is_tag and re.search(r'[a-zA-Z]', word):
            stats['total_words'] += 1

            # Then check which specific blocks it belongs to
            for block_type, depth in block_depths.items():
                if depth > 0:
                    stats[f'{block_type}_words'] += 1

    # Check for unclosed blocks
    for block_type, depth in block_depths.items():
        if depth > 0:
            raise InvalidTagNestingError(
                f"Unclosed {block_type} block at end of content",
                words,
                len(words) - 1
            )

    return stats

def count_words_in_tagged_blocks(article):
    for field in ['title', 'subtitle', 'main_content']:
        if field in article and article[field]:
            try:
                article[field + '_analysis'] = analyze_content(article[field])
            except InvalidTagNestingError as e:
                warnings.warn(f"Error in tags for article {article["id"]}.")
                article[field + '_analysis'] = f"Error in {field}: {str(e)}"
                article["tag_error"] = "present"

                context = e.get_context()
                print(f"Error: {str(e)}")
                print(f"Context: {' '.join(context)}")

def move_tags_to_main_fields(articles, which_go):
    output_path = f"tmp_{timestamp}_{which_go}.txt"
    with open(output_path, 'w', encoding='utf-8') as f:
        for article in articles.values():
            f.write(article.get(which_go, f"ERROR: tagging {which_go} not found")+"\n")
    return parse_articles_file(output_path)

def write_word_counts_file(articles, append_file="", output_folder = "output_folders/article_content_block_word_counts/"):
    output_path = f'{output_folder}block_word_counts_{append_file}.tsv'

    # Define block types
    block_types = ['total', 'general_disruption', 'protester_messaging', 'positive_comments', 'negative_comments']

    # Define content sections and their stat types
    content_sections = {
        'title': ['words'],
        'subtitle': ['words'],
        'main_content': ['words', 'pictures'],
        'all_content': ['words', 'pictures', 'words_and_pictures']
    }

    # Build header
    header = ['id']
    for section, stat_types in content_sections.items():
        for block in block_types:
            for stat_type in stat_types:
                header.append(f'{section}_{block}_{stat_type}')
    header.append('tagging_error')

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\t'.join(header) + '\n')

        for article_id, article in articles.items():
            row = [article_id]

            # Get analysis dicts
            analyses = {
                'title': article.get('title_analysis', {}),
                'subtitle': article.get('subtitle_analysis', {}),
                'main_content': article.get('main_content_analysis', {})
            }

            # Ensure all are dicts
            for key in analyses:
                if not isinstance(analyses[key], dict):
                    analyses[key] = {}

            # Process title, subtitle, main_content
            for section in ['title', 'subtitle', 'main_content']:
                for block in block_types:
                    for stat_type in content_sections[section]:
                        key = f'{block}_{stat_type}'
                        row.append(str(analyses[section].get(key, 0)))

            # Process all_content (combined)
            for block in block_types:
                words = sum(analyses[s].get(f'{block}_words', 0) for s in ['title', 'subtitle', 'main_content'])
                pictures = analyses['main_content'].get(f'{block}_pictures', 0)
                words_and_pictures = words + (pictures * 50)

                row.extend([str(words), str(pictures), str(words_and_pictures)])

            row.append(article.get('tagging_error', 'no'))
            f.write('\t'.join(row) + '\n')

def attach_tagging_error_to_original_article(article,tagged_article):
    if tagged_article.get("tag_error","") == "present":
        article["tag_error_message"] = "\n".join(
            value for value in [
                tagged_article.get("title_analysis", ""),
                tagged_article.get("subtitle_analysis", ""),
                tagged_article.get("main_content_analysis", "")
            ]
            if isinstance(value, str) and "Error" in value
        )

def apply_manual_corrections(articles_with_second_tagging, corrections_file_path, output_folder):
    articles_with_second_tagging_plus_corrections = articles_with_second_tagging.copy()
    manually_corrected_articles = parse_articles_file(corrections_file_path)

    # Replace articles that had tagging errors with corrected versions
    for article_id, original_article in articles_with_second_tagging.items():
        if original_article.get("tagging_error") == "yes":
            # Look for a corrected version
            if article_id in manually_corrected_articles:
                print(f"Applying manual corrections for article: {article_id}")
                corrected_article = manually_corrected_articles[article_id].copy()

                # Recompute word counts for the corrected article
                count_words_in_tagged_blocks(corrected_article)

                # Set tagging error to "no" since it's been manually corrected
                corrected_article["tagging_error"] = "no"

                # Replace in the output dictionary
                articles_with_second_tagging_plus_corrections[article_id] = corrected_article
            else:
                print(f"PROBLEM: No manual correction found for article with tagging error: {article_id}")

    write_word_counts_file(articles_with_second_tagging_plus_corrections, "final", output_folder )

def llm_code_and_count(
        directory_to_process = "../coding_batches/batch6/individual_articles/specific_and_edited",
        do_manual_corrections = True,
        output_folder = f'output_folders/article_content_block_word_counts/',
        corrections_file = "../coding_batches/batch6/individual_articles/specific_and_edited_block_tagging_manual_corrections/tagged_content_manually_corrected.txt"
    ):
    articles_for_coding = parse_articles_from_html_directory( directory_to_process )
    output_file = f"{output_folder}/article_content_block_word_counts_LLMResponses.txt"
    with open(output_file, 'w', encoding='utf-8') as f:
        articles_with_first_tagging = {}
        articles_with_second_tagging = {}
        for article in articles_for_coding.values():
            f.write("\nProcessing " + article["id"] + '\n')
            article["tag_first_go"] = llm.process_with_cache(llm_tag_first_go, article)
            f.write("\nFIRST LLM OUTPUT\n" + article["tag_first_go"] + '\n')
            article_with_first_tagging = parse_article_from_tag_string(article["tag_first_go"])
            count_words_in_tagged_blocks(article_with_first_tagging)

            if article_with_first_tagging.get("tag_error", "") == "present":
                f.write("\nFirst round: TAGGING ERROR(S) DETECTED\n")
                attach_tagging_error_to_original_article(article, article_with_first_tagging)
                # Add the specific error details to the log
                if "tag_error_message" in article:
                    f.write("Error details:\n" + article["tag_error_message"] + '\n')
                article_with_first_tagging["tagging_error"] = "yes"
                article["tag_second_go"] = llm.process_with_cache(llm_tag_second_go_after_error, article)
            else:
                f.write("\nFirst round: No tagging errors detected\n")
                article_with_first_tagging["tagging_error"] = "no"
                article["tag_second_go"] = llm.process_with_cache(llm_tag_second_go_no_error, article)

            articles_with_first_tagging[article_with_first_tagging["id"]] = article_with_first_tagging

            f.write("\nSECOND LLM OUTPUT\n" + article["tag_second_go"] + '\n')
            article_with_second_tagging = parse_article_from_tag_string(article["tag_second_go"])
            count_words_in_tagged_blocks(article_with_second_tagging)

            if article_with_second_tagging.get("tag_error", "") == "present":
                f.write("\nSecond round: TAGGING ERROR(S) DETECTED\n")
                attach_tagging_error_to_original_article(article, article_with_second_tagging)
                # Add the specific error details to the log
                if "tag_error_message" in article:
                    f.write("Error details:\n" + article["tag_error_message"] + '\n')
                article_with_second_tagging["tagging_error"] = "yes"
            else:
                f.write("\nSecond round: No tagging errors detected\n")
                article_with_second_tagging["tagging_error"] = "no"

            articles_with_second_tagging[article_with_second_tagging["id"]] = article_with_second_tagging

        with open(f'{output_folder}/llm_coded_content_blocks.json', 'w') as f:
            json.dump(articles_with_second_tagging, f, indent=4)
        write_word_counts_file(articles_with_first_tagging, "first", output_folder )
        write_word_counts_file(articles_with_second_tagging, "second", output_folder )
        if do_manual_corrections:
            apply_manual_corrections(articles_with_second_tagging, corrections_file, output_folder )

def main():
    llm_code_and_count(
        "../../articles/specific/",
        True,
        "../../word_count/",
        "../../word_count/corrections.txt"
    )

if __name__ == "__main__":
    main()
