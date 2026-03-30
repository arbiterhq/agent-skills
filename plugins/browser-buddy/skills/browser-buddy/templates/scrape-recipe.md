# Scrape Recipe Template

Use this template as a starting point for scraping workflows.

## Steps

1. Open the target URL with appropriate wait strategy
2. Take an accessibility snapshot to understand the page structure
3. Identify the data containers (tables, lists, cards)
4. Use `agent-browser evaluate` with DOM queries to extract structured data
5. If paginated, find the "Next" control and loop
6. Close the browser session

## Example

```bash
# Open
agent-browser open "TARGET_URL" --wait-until networkidle

# Discover structure
agent-browser snapshot -i

# Extract data (customize the selector and field mapping)
agent-browser evaluate "JSON.stringify([...document.querySelectorAll('SELECTOR')].map(el => ({field1: el.querySelector('.class1')?.textContent, field2: el.querySelector('.class2')?.textContent})))"

# Close
agent-browser close
```
