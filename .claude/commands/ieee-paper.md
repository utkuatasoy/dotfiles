# IEEE LaTeX Paper Helper

Generate IEEE-formatted LaTeX components for academic papers.

---

## Usage

```bash
/ieee-paper <component> [options]
```

### Components

| Component | Description |
|-----------|-------------|
| `template` | Full paper template with all packages |
| `figure` | Single figure with [H] placement |
| `figure-wide` | Full-width figure for two-column layout |
| `subfigures` | Multiple subfigures in grid |
| `table` | Basic table with booktabs |
| `table-wide` | Resizable wide table |
| `table-comparison` | Comparison table with bold/underline |
| `algorithm` | Pseudocode algorithm block |
| `equation` | Mathematical equation |
| `bibitem` | Bibliography entry |
| `author` | Author block (single/multiple) |
| `abstract` | Abstract and keywords template |

---

## Examples

```bash
/ieee-paper template
/ieee-paper figure filename.png "Caption text" fig:label
/ieee-paper table 4 "Col1,Col2,Col3,Col4" "Table caption" tab:label
/ieee-paper bibitem arxiv "Author" "Title" "2024" "2401.12345"
/ieee-paper subfigures 2x3 "fig1.png,fig2.png,fig3.png,fig4.png,fig5.png,fig6.png"
```

---

## What This Command Does

Based on the `$ARGUMENTS`, generate the appropriate LaTeX code:

### 1. Template (`template`)
Generate complete IEEE paper template with:
- IEEEtran document class
- All required packages (float, graphicx, hyperref, subcaption, booktabs, cite, amsmath, algorithmic, etc.)
- Author block placeholder
- Standard sections (Introduction, Related Work, Methodology, Experiments, Conclusion)
- Bibliography template

### 2. Figure (`figure <filename> "<caption>" <label>`)
```latex
\begin{figure}[H]
\centering
\includegraphics[width=\columnwidth]{<filename>}
\caption{<caption>}
\label{<label>}
\end{figure}
```

### 3. Wide Figure (`figure-wide <filename> "<caption>" <label>`)
```latex
\begin{figure*}[!t]
\centering
\includegraphics[width=0.75\textwidth]{<filename>}
\caption{<caption>}
\label{<label>}
\end{figure*}
```

### 4. Subfigures (`subfigures <rows>x<cols> "<files>" "<captions>" "<main_caption>" <label>`)
Generate grid of subfigures with:
- Automatic width calculation (0.3\columnwidth for 3 cols, 0.45\columnwidth for 2 cols)
- `\hfill` between columns
- `\vspace{5mm}` between rows
- Individual captions (a), (b), (c)...
- Overall caption and label

### 5. Table (`table <cols> "<headers>" "<caption>" <label>`)
```latex
\begin{table}[H]
\centering
\caption{<caption>}
\label{<label>}
\begin{tabular}{@{}<alignment>@{}}
\toprule
<headers with \textbf{}> \\
\midrule
% Data rows here
\bottomrule
\end{tabular}
\end{table}
```

### 6. Wide Table (`table-wide <cols> "<headers>" "<caption>" <label>`)
Same as table but wrapped in `\resizebox{0.5\textwidth}{!}{...}`

### 7. Comparison Table (`table-comparison`)
Table with highlighting instructions:
- `\textbf{}` for best results
- `\underline{}` for second-best
- Citation column with `\cite{}`
- Year column

### 8. Algorithm (`algorithm "<name>" <label>`)
```latex
\begin{algorithm}
\caption{<name>}
\label{<label>}
\begin{algorithmic}[1]
\REQUIRE Input description
\ENSURE Output description
\STATE Initialize
\FOR{condition}
    \STATE Process
\ENDFOR
\RETURN Result
\end{algorithmic}
\end{algorithm}
```

### 9. Equation (`equation "<formula>" <label>`)
```latex
\begin{equation}
    <formula>
    \label{<label>}
\end{equation}
```

### 10. Bibliography Items (`bibitem <type> ...`)

**ArXiv:** `bibitem arxiv "<authors>" "<title>" "<year>" "<arxiv_id>"`
```latex
\bibitem{<key>}
<authors>, ``<title>,'' \textit{arXiv preprint arXiv:<arxiv_id>}, <year>. doi: \url{https://doi.org/10.48550/arXiv.<arxiv_id>}
```

**Conference:** `bibitem conf "<authors>" "<title>" "<conf>" "<year>" "<pages>"`
```latex
\bibitem{<key>}
<authors>, ``<title>,'' in \textit{Proc. <conf>}, <year>, pp. <pages>.
```

**Journal:** `bibitem journal "<authors>" "<title>" "<journal>" "<vol>" "<pages>" "<year>"`
```latex
\bibitem{<key>}
<authors>, ``<title>,'' \textit{<journal>}, vol.~<vol>, pp.~<pages>, <year>.
```

### 11. Author Block (`author <count>`)
Generate author block template for specified number of authors with:
- `\IEEEauthorblockN{}` for names
- `\IEEEauthorblockA{}` for affiliations
- `\IEEEauthorrefmark{}` for linking
- Email with `\href{mailto:...}{...}`

### 12. Abstract (`abstract`)
```latex
\begin{abstract}
% 150-250 words covering:
% (1) Problem/motivation
% (2) Approach/method
% (3) Key results
% (4) Main contribution
\end{abstract}

\begin{IEEEkeywords}
Keyword One, Keyword Two, Keyword Three, Keyword Four, Keyword Five
\end{IEEEkeywords}
```

---

## Quick Reference

### Figure Placement Options
- `[H]` - Exact placement (requires float package)
- `[h!]` - Strong preference for here
- `[t]` - Top of page
- `[b]` - Bottom of page
- `[!t]` - Top, override restrictions (use for `figure*`)

### Table Column Alignment
- `l` - left
- `c` - center
- `r` - right
- `@{}` - remove padding

### Common Widths
- `\columnwidth` - single column width
- `\textwidth` - full page width
- `0.3\columnwidth` - for 3 subfigures
- `0.45\columnwidth` - for 2 subfigures
- `0.75\textwidth` - for wide figures

### Text Formatting
- `\textbf{}` - bold (best results)
- `\underline{}` - underline (second-best)
- `\textit{}` - italic (paper/journal titles)
- `\textit{et al.}` - "and others"

### Cross-References
- `Figure~\ref{fig:label}`
- `Table~\ref{tab:label}`
- `Equation~\ref{eq:label}` or `(\ref{eq:label})`
- `Section~\ref{sec:label}`
- `~\cite{key}` or `~\cite{key1, key2}`

---

## Output

Return ONLY the requested LaTeX code block, properly formatted and ready to copy-paste into the document.
