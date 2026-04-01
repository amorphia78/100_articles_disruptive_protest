import anthropic
import os
import json

client = None
no_cache = False

def load_client(api_key: str | None = None) -> anthropic.Anthropic:
    global client
    if api_key is not None:
        client = anthropic.Anthropic(api_key=api_key)
    else:
        try:
            with open('key.txt', 'r') as file:
                file_api_key = file.read().strip()
            client = anthropic.Anthropic(api_key=file_api_key)
        except FileNotFoundError:
            print("key.txt file not found - key couldn't be loaded, remainder of code requires a full set of cached LLM responses")
        except Exception as e:
            print(f"Error loading API key: {str(e)} - key couldn't be loaded, remainder of code requires a full set of cached LLM responses")
            
def send_prompt(prompt, prefill="", prior_prompt="", prior_llm ="" ):
    global client
    if prior_prompt != "":
        messages = [
            { 'role': "user",
              'content': [ {'type': "text", 'text': prior_prompt} ]
            }, {
              'role': "assistant",
              'content': [ {'type': "text", 'text': prior_llm } ]
            }, {
              'role': "user",
              'content': [ {'type': "text", 'text': prompt } ]
        } ]
        if prefill:
            messages.append( {
                'role': "assistant",
                'content': [ {'type': "text", 'text': prefill} ]
            } )
    else:
        messages = [ {
                'role': "user",
                'content': [ {'type': "text", 'text': prompt} ]
        } ]
        if prefill:
            messages.append( {
                'role': "assistant",
                'content': [ {'type': "text", 'text': prefill} ]
            } )
    response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=2000,
        temperature=0,
        messages=messages,
    ).content[0].text
    if prefill:
        response = prefill + response
    return response

def process_with_cache(process_func, article, additional_arg=None):
    cache_dir = f"../../llm_caches/{process_func.__name__}"
    os.makedirs(cache_dir, exist_ok=True)
    if additional_arg is not None:
        safe_arg = str(additional_arg).replace('/', '_').replace('\\', '_')
        cache_file = f"{cache_dir}/{article['id']}_{safe_arg}.json"
    else:
        cache_file = f"{cache_dir}/{article['id']}.json"
    if os.path.exists(cache_file) and not no_cache:
        print(f"{process_func.__name__} for article {article['id']} (retrieving cache)")
        with open(cache_file, 'r', encoding='utf-8') as f:
            cached_data = json.load(f)
            return cached_data['string_data'] if 'string_data' in cached_data else cached_data
    else:
        print(f"{process_func.__name__} for article {article['id']} (consulting LLM)")
        if additional_arg is not None:
            result = process_func(article, additional_arg)
        else:
            result = process_func(article)
        if isinstance(result, str):
            data_to_store = {'string_data': result}
        else:
            data_to_store = result
        with open(cache_file, 'w', encoding='utf-8') as f:
            json.dump(data_to_store, ensure_ascii=False, indent=2, fp=f)  # type: ignore
        return result