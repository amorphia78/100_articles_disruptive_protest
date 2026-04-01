#!/usr/bin/env python3
"""
Process HTML files in generalOLD and specificOLD directories:
- Copy to new directories (general, specific) without OLD suffix
- Replace absolute GitHub raw image URLs with relative ../logos/ paths
- Create article_index.html with a table of all articles
"""

import os
import re
import shutil
from pathlib import Path


LOGO_URL_PATTERN = re.compile(
    r'https://raw\.githubusercontent\.com/[^"\']+/outlet_logos/([^"\']+\.png)'
)
H1_PATTERN = re.compile(r'<h1[^>]*>(.*?)</h1>', re.IGNORECASE | re.DOTALL)


def process_html(content):
    """Replace absolute logo URL with relative path, return (new_content, logo_filename)."""
    match = LOGO_URL_PATTERN.search(content)
    if not match:
        raise ValueError("No logo URL found in file")
    logo_filename = match.group(1)
    new_content = LOGO_URL_PATTERN.sub(f'../logos/{logo_filename}', content)
    return new_content, logo_filename


def extract_h1(content):
    """Extract text content from the first <h1> tag."""
    match = H1_PATTERN.search(content)
    if not match:
        raise ValueError("No <h1> tag found in file")
    # Strip any inner HTML tags from the h1 text
    inner = match.group(1)
    inner = re.sub(r'<[^>]+>', '', inner).strip()
    return inner


def source_display(logo_filename):
    """Convert logo filename (e.g. BBC-News.png) to display name (e.g. BBC News)."""
    name = logo_filename.replace('.png', '')
    return name.replace('-', ' ')


def process_directory(old_dir, new_dir, type_label, rows):
    """Copy and process all HTML files from old_dir to new_dir, appending rows."""
    old_path = Path(old_dir)
    new_path = Path(new_dir)

    if not old_path.exists():
        print(f"Warning: {old_dir} does not exist, skipping.")
        return

    new_path.mkdir(exist_ok=True)

    html_files = sorted(old_path.glob('*.html'))
    if not html_files:
        print(f"Warning: No HTML files found in {old_dir}")
        return

    for html_file in html_files:
        content = html_file.read_text(encoding='utf-8')

        new_content, logo_filename = process_html(content)
        h1_text = extract_h1(content)

        dest_file = new_path / html_file.name
        dest_file.write_text(new_content, encoding='utf-8')

        rows.append({
            'type': type_label,
            'source': source_display(logo_filename),
            'title': h1_text,
            'relative_path': f'{new_path.name}/{html_file.name}',
        })

    print(f"Processed {len(html_files)} file(s) from {old_dir} → {new_dir}")


def build_index(rows, output_path='article_index.html'):
    """Build the article_index.html file."""
    table_rows = []
    for row in rows:
        table_rows.append(
            f'    <tr>\n'
            f'      <td>{row["type"]}</td>\n'
            f'      <td>{row["source"]}</td>\n'
            f'      <td><a href="{row["relative_path"]}">{row["title"]}</a></td>\n'
            f'    </tr>'
        )

    table_html = '\n'.join(table_rows)

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Article index</title>
  <style>
    body {{ font-family: sans-serif; max-width: 900px; margin: 2em auto; padding: 0 1em; }}
    table {{ border-collapse: collapse; width: 100%; }}
    th, td {{ text-align: left; padding: 0.5em 1em; border: 1px solid #ccc; }}
    th {{ background: #f0f0f0; }}
    tr:hover {{ background: #fafafa; }}
  </style>
</head>
<body>
  <h1>Article index</h1>
  <p>This index allows easy viewing of each article HTML file in the repository via <a href="https://githack.com">githack.com</a>.</p>
  <table>
    <thead>
      <tr>
        <th>Type</th>
        <th>Source</th>
        <th>Title</th>
      </tr>
    </thead>
    <tbody>
{table_html}
    </tbody>
  </table>
</body>
</html>
"""

    Path(output_path).write_text(html, encoding='utf-8')
    print(f"Created {output_path} with {len(rows)} row(s)")


def main():
    rows = []

    # Process specific first so it appears first in the table
    process_directory('specificOLD', 'specific', 'Specific', rows)
    process_directory('generalOLD', 'general', 'General', rows)

    build_index(rows)


if __name__ == '__main__':
    main()