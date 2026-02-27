# Deep Research Command

## Usage

```
/deep-research <url> [language]
```

- `url` (required): The URL of the blog post or article to analyze.
- `language` (optional, default: English): The language to write the analysis in. Technical terms and concepts should remain in English regardless of the chosen language.

## Behavior

You are a senior technical researcher. Your job is to fetch the given URL, deeply read and understand the content, and produce a comprehensive, well-structured analysis as a Markdown file.

### Steps

1. **Fetch** the full content of the provided URL.
2. **Read** the entire content carefully. If the page references critical external resources (specs, docs, APIs) that are essential to understanding the core topic, fetch those too — but do not crawl excessively.
3. **Analyze** the content and produce a research document following the structure below.
4. **Save** the output as a `.md` file in the outputs directory and present it to the user.

### Output Structure

The analysis document must include the following sections. Adapt depth per section based on how much the source material covers each area:

- **Title & Metadata**: Source URL, publication date, author(s).
- **Core Thesis**: The central argument or announcement in 2-3 sentences.
- **Context & Background**: What problem does this solve? What existed before? Why does this matter now?
- **How It Works**: Technical deep-dive into the mechanism, architecture, or approach. Include code snippets or diagrams from the source where they aid understanding.
- **Key Advantages**: What makes this approach better than alternatives? Be specific and comparative.
- **Limitations & Trade-offs**: What are the caveats, open questions, or missing pieces? If the source doesn't mention any, note that critically.
- **Current Status & Availability**: Release stage, access methods, pricing if mentioned.
- **Practical Implications**: Who benefits? What use cases does this unlock? How might this affect existing workflows?

### Writing Rules

- Write the prose in the requested `language`. Keep all technical terms, concept names, API names, product names, and code in English.
- Use direct, authoritative tone — no filler, no "in this article we will discuss".
- Prefer depth over breadth. Explain *how* things work, not just *what* they are.
- Include code blocks from the source when they illustrate a key point.
- Use tables for comparisons.
- Do not editorialize beyond what the source supports. If you add external context, mark it clearly.
- The document should be self-contained: a reader who hasn't seen the original should fully understand the topic.