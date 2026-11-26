// Simple numbering for non-book documents
#let equation-numbering = "(1)"
#let callout-numbering = "1"
#let subfloat-numbering(n-super, subfloat-idx) = {
  numbering("1a", n-super, subfloat-idx)
}

// Theorem configuration for theorion
// Simple numbering for non-book documents (no heading inheritance)
#let theorem-inherited-levels = 0

// Theorem numbering format (can be overridden by extensions for appendix support)
// This function returns the numbering pattern to use
#let theorem-numbering(loc) = "1.1"

// Default theorem render function
#let theorem-render(prefix: none, title: "", full-title: auto, body) = {
  if full-title != "" and full-title != auto and full-title != none {
    strong[#full-title.]
    h(0.5em)
  }
  body
}
// Some definitions presupposed by pandoc's typst output.
#let content-to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(content-to-string).join("")
  } else if content.has("body") {
    content-to-string(content.body)
  } else if content == [ ] {
    " "
  }
}

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms.item: it => block(breakable: false)[
  #text(weight: "bold")[#it.term]
  #block(inset: (left: 1.5em, top: -0.4em))[#it.description]
]

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let fields = old_block.fields()
  let _ = fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => {
          let subfloat-idx = quartosubfloatcounter.get().first() + 1
          subfloat-numbering(n-super, subfloat-idx)
        })
        show figure.where(kind: kind): set figure.caption(position: position)
        show figure.where(kind: kind): set figure(outlined: false)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => block({
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          })

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let children = old_title_block.body.body.children
  let old_title = if children.len() == 1 {
    children.at(0)  // no icon: title at index 0
  } else {
    children.at(1)  // with icon: title at index 1
  }

  // TODO use custom separator if available
  // Use the figure's counter display which handles chapter-based numbering
  // (when numbering is a function that includes the heading counter)
  let callout_num = it.counter.display(it.numbering)
  let new_title = if empty(old_title) {
    [#kind #callout_num]
  } else {
    [#kind #callout_num: #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block,
    block_with_new_content(
      old_title_block.body,
      if children.len() == 1 {
        new_title  // no icon: just the title
      } else {
        children.at(0) + new_title  // with icon: preserve icon block + new title
      }))

  align(left, block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1)))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color,
        width: 100%,
        inset: 8pt)[#if icon != none [#text(icon_color, weight: 900)[#icon] ]#title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}


// syntax highlighting functions from skylighting:
/* Function definitions for syntax highlighting generated by skylighting: */
#let EndLine() = raw("\n")
#let Skylighting(fill: none, number: false, start: 1, sourcelines) = {
   let blocks = []
   let lnum = start - 1
   let bgcolor = rgb("#f1f3f5")
   for ln in sourcelines {
     if number {
       lnum = lnum + 1
       blocks = blocks + box(width: if start + sourcelines.len() > 999 { 30pt } else { 24pt }, text(fill: rgb("#aaaaaa"), [ #lnum ]))
     }
     blocks = blocks + ln + EndLine()
   }
   block(fill: bgcolor, width: 100%, inset: 8pt, radius: 2pt, blocks)
}
#let AlertTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let AnnotationTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let AttributeTok(s) = text(fill: rgb("#657422"),raw(s))
#let BaseNTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let BuiltInTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let CharTok(s) = text(fill: rgb("#20794d"),raw(s))
#let CommentTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let CommentVarTok(s) = text(style: "italic",fill: rgb("#5e5e5e"),raw(s))
#let ConstantTok(s) = text(fill: rgb("#8f5902"),raw(s))
#let ControlFlowTok(s) = text(weight: "bold",fill: rgb("#003b4f"),raw(s))
#let DataTypeTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let DecValTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let DocumentationTok(s) = text(style: "italic",fill: rgb("#5e5e5e"),raw(s))
#let ErrorTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let ExtensionTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let FloatTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let FunctionTok(s) = text(fill: rgb("#4758ab"),raw(s))
#let ImportTok(s) = text(fill: rgb("#00769e"),raw(s))
#let InformationTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let KeywordTok(s) = text(weight: "bold",fill: rgb("#003b4f"),raw(s))
#let NormalTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let OperatorTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let OtherTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let PreprocessorTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let RegionMarkerTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let SpecialCharTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let SpecialStringTok(s) = text(fill: rgb("#20794d"),raw(s))
#let StringTok(s) = text(fill: rgb("#20794d"),raw(s))
#let VariableTok(s) = text(fill: rgb("#111111"),raw(s))
#let VerbatimStringTok(s) = text(fill: rgb("#20794d"),raw(s))
#let WarningTok(s) = text(style: "italic",fill: rgb("#5e5e5e"),raw(s))



#let article(
  title: none,
  subtitle: none,
  authors: none,
  keywords: (),
  date: none,
  abstract-title: none,
  abstract: none,
  thanks: none,
  cols: 1,
  lang: "en",
  region: "US",
  font: none,
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: none,
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  mathfont: none,
  codefont: none,
  linestretch: 1,
  sectionnumbering: none,
  linkcolor: none,
  citecolor: none,
  filecolor: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  lof: false,
  lof-title: none,
  lot: false,
  lot-title: none,
  doc,
) = {
  // Set document metadata for PDF accessibility
  set document(title: title, keywords: keywords)
  set document(
    author: authors.map(author => content-to-string(author.name)).join(", ", last: " & "),
  ) if authors != none and authors != ()
  set par(
    justify: true,
    leading: linestretch * 0.65em
  )
  set text(lang: lang,
           region: region,
           size: fontsize)
  set text(font: font) if font != none
  show math.equation: set text(font: mathfont) if mathfont != none
  show raw: set text(font: codefont) if codefont != none

  set heading(numbering: sectionnumbering)

  show link: set text(fill: rgb(content-to-string(linkcolor))) if linkcolor != none
  show ref: set text(fill: rgb(content-to-string(citecolor))) if citecolor != none
  show link: this => {
    if filecolor != none and type(this.dest) == label {
      text(this, fill: rgb(content-to-string(filecolor)))
    } else {
      text(this)
    }
   }

  let has-title-block = title != none or (authors != none and authors != ()) or date != none or abstract != none
  if has-title-block {
    place(
      top,
      float: true,
      scope: "parent",
      clearance: 4mm,
      block(below: 1em, width: 100%)[

        #if title != none {
          align(center, block(inset: 2em)[
            #set par(leading: heading-line-height) if heading-line-height != none
            #set text(font: heading-family) if heading-family != none
            #set text(weight: heading-weight)
            #set text(style: heading-style) if heading-style != "normal"
            #set text(fill: heading-color) if heading-color != black

            #text(size: title-size)[#title #if thanks != none {
              footnote(thanks, numbering: "*")
              counter(footnote).update(n => n - 1)
            }]
            #(if subtitle != none {
              parbreak()
              text(size: subtitle-size)[#subtitle]
            })
          ])
        }

        #if authors != none and authors != () {
          let count = authors.len()
          let ncols = calc.min(count, 3)
          grid(
            columns: (1fr,) * ncols,
            row-gutter: 1.5em,
            ..authors.map(author =>
                align(center)[
                  #author.name \
                  #author.affiliation \
                  #author.email
                ]
            )
          )
        }

        #if date != none {
          align(center)[#block(inset: 1em)[
            #date
          ]]
        }

        #if abstract != none {
          block(inset: 2em)[
          #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
          ]
        }
      ]
    )
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if lof {
    block(above: 0em, below: 2em)[
    #outline(title: lof-title, target: figure.where(kind: "quarto-float-fig"));
    ]
  }

  if lot {
    block(above: 0em, below: 2em)[
    #outline(title: lot-title, target: figure.where(kind: "quarto-float-tbl"));
    ]
  }

  doc
}

#set table(
  inset: 6pt,
  stroke: none
)
#show figure.caption: set text(size: 9pt)
#show outline: it => {
  v(2em)  // Add vertical space before TOC
  it
}
#let brand-color = (:)
#let brand-color-background = (:)
#let brand-logo = (:)

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
  columns: 1,
)

#show: doc => article(
  title: [seqwrap: an R package for flexible iterative fitting of high-dimensional data],
  subtitle: [Supplementary material],
  authors: (
    ( name: [Chidimma Echebiri],
      affiliation: [University of Inland Norway],
      email: [chidimma.echebiri\@inn.no] ),
    ( name: [Rafi Ahmad],
      affiliation: [University of Inland Norway],
      email: [rafi.ahmad\@inn.no] ),
    ( name: [Stian Ellefsen],
      affiliation: [University of Inland Norway],
      email: [stian.ellefsen\@inn.no] ),
    ( name: [Daniel Hammarström],
      affiliation: [University of Inland Norway],
      email: [daniel.hammarstrom\@inn.no] ),
    ),
  toc: true,
  toc_title: [Table of contents],
  toc_depth: 3,
  doc,
)

= Installing seqwrap
<installing-seqwrap>
The latest version of is available from #link("https://CRAN.R-project.org/package=seqwrap")[CRAN]. To install seqwrap:

#block[
#Skylighting(([#CommentTok("# Installing from CRAN");],
[#FunctionTok("install.packages");#NormalTok("(");#StringTok("\"seqwrap\"");#NormalTok(")");],));
]
To install the developmental version from GitHub:

#block[
#Skylighting(([#CommentTok("# Installing from Github");],
[#NormalTok("pak");#SpecialCharTok("::");#FunctionTok("pkg_install");#NormalTok("(");#StringTok("\"trainome/seqwrap\"");#NormalTok(")");],));
]
= Fitting models with seqwrap
<fitting-models-with-seqwrap>
The seqwrap package is designed to iterate over multiple targets in a high-dimensional data set to fit a user-defined regression model using a user-selected model fitting function. Each target may represent, e.g., a gene, an exon, a protein, a methylation site, or any other outcome from a high-throughput omics platform. Each target is measured across a set of samples, with a metadata set describing study covariates. In the basic case, data and metadata are combined in each iteration to fit the selected model for a specific target.

Dungan et al. @dungan2022 evaluated a senolytic treatment (dasatinib and quercetin) in mouse skeletal muscle subjected to mechanical overload through synergist ablation. The study included sham surgery and a vehicle control, allowing analysis of the effect of senolytic treatment and the interaction between mechanical overloading and senolytic treatment. RNA-seq was performed on 20 animals (5 per group). The data has been downloaded from the gene expression omnibus (#link("https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE195707")[GSE195707]) and are made available in the seqwrap package under #NormalTok("dungan_counts");. We will load the data and filter low-expression genes.

#block[
#Skylighting(([#CommentTok("# Load packages");],
[#FunctionTok("library");#NormalTok("(tidyverse)");],
[#FunctionTok("library");#NormalTok("(seqwrap)");],
[#FunctionTok("library");#NormalTok("(edgeR)");],
[#FunctionTok("library");#NormalTok("(gt)");],
[],
[#CommentTok("# Load data ");],
[#NormalTok("metadata ");#OtherTok("<-");#NormalTok(" seqwrap");#SpecialCharTok("::");#NormalTok("dungan_counts");#SpecialCharTok("$");#NormalTok("metadata");],
[#NormalTok("counts ");#OtherTok("<-");#NormalTok(" seqwrap");#SpecialCharTok("::");#NormalTok("dungan_counts");#SpecialCharTok("$");#NormalTok("countdata");],));
]
The metadata contains the sample ID corresponding to columns in the counts data set. We are using #NormalTok("seq_sample_id"); as the column name here. The first rows of the prepared metadata are displayed in #ref(<tbl-meta-dungan>, supplement: [Table]).

#figure([
#{set text(font: ("Segoe UI", "Arial", "Segoe UI Emoji", "Segoe UI Symbol") , size: 9pt);table(
  columns: 3,
  align: (left,center,center,),
  table.header(table.cell(align: bottom + left, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    seq\_sample\_id], table.cell(align: bottom + center, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    treatment], table.cell(align: bottom + center, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    surgery],),
  table.hline(),
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[OS14d5], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Senolytic], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Overload],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[OS14d6], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Senolytic], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Overload],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[OSS4], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Senolytic], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Sham],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[OSS5], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Senolytic], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Sham],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[OV14D5], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Vehicle], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Overload],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[OV14D6], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Vehicle], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Overload],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[OVS4], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Vehicle], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Sham],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[OVS5], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Vehicle], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Sham],
)}
], caption: figure.caption(
position: top, 
[
Selected rows from the Dungan et al.~metadata data frame.
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-meta-dungan>


The count data matrix can be manipulated as a data frame, with the first column indicating the targets (in this case, gene symbols). Importantly, additional column names have names corresponding to the #NormalTok("seq_sample_id"); variable in the metadata. As an example, the first rows of the count data frame are shown for the same samples as in the metadata data frame (see #ref(<tbl-dungan-counts>, supplement: [Table])). seqwrap expects that targets are unique so before going further we should validate this in the data. When doing so we find that five targets have duplicate rows in the data set, for simplicity, we will remove them.

#figure([
#{set text(font: ("Segoe UI", "Arial", "Segoe UI Emoji", "Segoe UI Symbol") , size: 9pt);table(
  columns: 9,
  align: (left,right,right,right,right,right,right,right,right,),
  table.header(table.cell(align: bottom + left, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    gene\_name], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    OS14d5], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    OS14d6], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    OSS4], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    OSS5], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    OV14D5], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    OV14D6], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    OVS4], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    OVS5],),
  table.hline(),
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Gnai3], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[858], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[773], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[280], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[295], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[700], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[357], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[380], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[236],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Cdc45], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[63], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[71], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[45], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[43], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[61], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[39], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[53], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[54],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[H19], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[63437], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[69156], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[4539], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[4694], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[75553], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[63084], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[3565], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[4981],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Narf], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1935], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2033], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2573], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2415], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2275], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1807], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2999], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2543],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Cav2], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[730], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[701], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[491], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[400], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[584], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[441], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[548], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[320],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Klf6], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1300], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1232], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[356], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[327], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[820], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[458], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[530], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[518],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Scmh1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[672], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[635], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[738], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[547], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[599], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[464], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[826], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[637],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Cox5a], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[5384], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[6501], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[7794], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[6355], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[7189], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[5354], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[8651], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[8478],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Tbx2], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[91], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[103], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[59], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[55], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[131], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[107], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[59], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[35],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Tbx4], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[43], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[77], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[25], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[33], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[65], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[45], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[37], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[27],
)}
], caption: figure.caption(
position: top, 
[
Selected rows from the Dungan et al.~counts data frame.
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-dungan-counts>


#block[
#Skylighting(([#CommentTok("# Find targets with more than a unique row in the data");],
[#NormalTok("rm_targets ");#OtherTok("<-");#NormalTok(" counts ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("  ");#FunctionTok("summarise");#NormalTok("(");#AttributeTok(".by =");#NormalTok(" gene_name, ");],
[#NormalTok("            ");#AttributeTok("n =");#NormalTok(" ");#FunctionTok("n");#NormalTok("()) ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("  ");#FunctionTok("filter");#NormalTok("(n ");#SpecialCharTok(">");#NormalTok(" ");#DecValTok("1");#NormalTok(") ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("  ");#FunctionTok("pull");#NormalTok("(gene_name)");],
[],
[#CommentTok("# Filter out non-uniqe rows");],
[#NormalTok("counts ");#OtherTok("<-");#NormalTok(" counts ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("  ");#FunctionTok("filter");#NormalTok("(");#SpecialCharTok("!");#NormalTok("(gene_name ");#SpecialCharTok("%in%");#NormalTok(" rm_targets))");],));
]
The data suggests a negative binomial model where the linear predictor can be used to assess the difference between senolytic treatment and control (treat; $beta_(g\,1)$), mechanical overloading compared to sham surgery (mov; $beta_(g\,2)$), and their interaction ($beta_(g\,3)$) for gene #emph[g] (#emph[g] = 1, …, #emph[m], here #emph[m] = 12273) and observation #emph[i] (#emph[i] = 1, …, #emph[n], here #emph[n] = 20 rows of the metadata; #ref(<eq-m1>, supplement: [Equation])). We want to control for differences in sequencing depth by including an offset (#emph[s]#sub[i]). We will use the TMM method @robinson2010 to calculate the effective library size.

#math.equation(block: true, numbering: equation-numbering, [ $ y_(g\,i) & tilde.op "NB2"\(mu_(g\,i)\,theta_g\)\
log\(mu_(g\,i)\) & = beta_(g\,0) + beta_(g\,1) upright("treat")_i + beta_(g\,2) upright("mov")_i + beta_(g\,3)\(upright("treat")_i times upright("mov")_i\)+ log\(s_i\) $ ])<eq-m1>

Below, we are using the edgeR package to calculate the library size normalization factor. Effective library sizes are then expressed as relative to the median effective library and log transformed.

#block[
#Skylighting(([#CommentTok("# Use EdgeR to calculate the TMM");],
[#NormalTok("y ");#OtherTok("<-");#NormalTok(" edgeR");#SpecialCharTok("::");#FunctionTok("DGEList");#NormalTok("(counts[,");#SpecialCharTok("-");#DecValTok("1");#NormalTok("])");],
[#NormalTok("y ");#OtherTok("<-");#NormalTok(" edgeR");#SpecialCharTok("::");#FunctionTok("calcNormFactors");#NormalTok("(y)");],));
#block[
#Skylighting(([#NormalTok("calcNormFactors has been renamed to normLibSizes");],));
]
#Skylighting(([#CommentTok("# Combine the data into metadata");],
[#NormalTok("metadata ");#OtherTok("<-");#NormalTok(" metadata ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("  ");#FunctionTok("inner_join");#NormalTok("(");],
[#NormalTok("    y");#SpecialCharTok("$");#NormalTok("samples ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("  tibble");#SpecialCharTok("::");#FunctionTok("rownames_to_column");#NormalTok("(");#StringTok("\"seq_sample_id\"");#NormalTok(")");],
[#NormalTok("  ) ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("   ");#FunctionTok("mutate");#NormalTok("(");],
[#NormalTok("     ");#AttributeTok("efflibsize =");#NormalTok(" (lib.size ");#SpecialCharTok("*");#NormalTok(" norm.factors) ");#SpecialCharTok("/");#NormalTok(" ");#FunctionTok("median");#NormalTok("(lib.size ");#SpecialCharTok("*");#NormalTok(" norm.factors),");],
[#NormalTok("     ");#AttributeTok("efflibsize =");#NormalTok(" ");#FunctionTok("log");#NormalTok("(efflibsize)");],
[#NormalTok("   ) ");],));
#block[
#Skylighting(([#NormalTok("Joining with `by = join_by(seq_sample_id)`");],));
]
]
#NormalTok("seqwrap_compose()"); is used to combine the data, metadata and the selected modelling function with its arguments into a #NormalTok("swobject");. A negative binomial model can be fitted using e.g., #NormalTok("glmmTMB()"); from the glmmTMB package (#NormalTok("glmmTMB::glmmTMB()");) or #NormalTok("MASS::glm.nb()");, here we will use #NormalTok("glmmTMB()"); as it can be extended in subsequent modelling steps.

The specified #NormalTok("glmmTMB()"); function (#NormalTok("modelfun"); slot) needs a formula and a family function, these are supplied in the arguments slot. The count data are supplied in the #NormalTok("data"); slot and the metadata in the #NormalTok("metadata"); slot. Notice that we use the namespace operator (#NormalTok("::");) to specify selected functions to avoid difficulties in parallel processing. The #NormalTok("samplename"); indicates the column name in the metadata that gives sample names.

#block[
#Skylighting(([#NormalTok("m1");#FloatTok(".1");#NormalTok(" ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap_compose");#NormalTok("(");],
[#NormalTok("  ");#AttributeTok("modelfun =");#NormalTok(" glmmTMB");#SpecialCharTok("::");#NormalTok("glmmTMB,");],
[#NormalTok("  ");#AttributeTok("data =");#NormalTok(" counts, ");],
[#NormalTok("  ");#AttributeTok("metadata =");#NormalTok(" metadata, ");],
[#NormalTok("  ");#AttributeTok("arguments =");#NormalTok(" ");#FunctionTok("list");#NormalTok("(");#AttributeTok("formula =");#NormalTok(" y ");#SpecialCharTok("~");#NormalTok(" treatment ");#SpecialCharTok("*");#NormalTok(" surgery ");#SpecialCharTok("+");#NormalTok(" ");#FunctionTok("offset");#NormalTok("(efflibsize), ");],
[#NormalTok("                ");#AttributeTok("family =");#NormalTok(" glmmTMB");#SpecialCharTok("::");#NormalTok("nbinom2),");],
[#NormalTok("  ");#AttributeTok("samplename =");#NormalTok(" ");#StringTok("\"seq_sample_id\"");],
[#NormalTok("  )");],));
]
Next, we will run the model using #NormalTok("seqwrap()");. We recommend using #NormalTok("subset"); to specify a smaller number of targets when prototyping the model. Here, we will assess whether the model output matches expectations. By specifying #NormalTok("return_models = TRUE");, all model objects will be returned in the results object, which can be inspected if needed. Here we are using a single core for fitting the models, specified in the #NormalTok("cores"); argument.

#block[
#Skylighting(([#NormalTok("m1");#FloatTok(".1");#NormalTok("_temp ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap");#NormalTok("(");],
[#NormalTok("  m1");#FloatTok(".1");#NormalTok(", ");],
[#NormalTok("  ");#AttributeTok("cores =");#NormalTok(" ");#DecValTok("1");#NormalTok(", ");],
[#NormalTok("  ");#AttributeTok("subset =");#NormalTok(" ");#DecValTok("1");#SpecialCharTok(":");#DecValTok("24");#NormalTok(", ");],
[#NormalTok("  ");#AttributeTok("return_models =");#NormalTok(" ");#ConstantTok("TRUE");#NormalTok(", ");],
[#NormalTok("  ");#AttributeTok("verbose =");#NormalTok(" ");#ConstantTok("FALSE");],
[#NormalTok(")");],));
#block[
#Skylighting(([#NormalTok("Warning: You are saving 24 model objects which could be very memory intensive. If this");],
[#NormalTok("was intended, ignore this warning.");],));
]
]
#NormalTok("seqwrap()"); will warn us that we are saving model objects. As we only use 24 targets (i.e., 24 model objects are saved in the environment) in prototyping we can ignore this warning.

Following iterative fitting using #NormalTok("seqwrap()");, we can summarize the models using #NormalTok("seqwrap_summarise()");, which produces a list of two summaries. Below, we are saving the summaries in an object for later access. Running the #NormalTok("seqwrap_summarise()"); function also gives us an overview of the model and successfully summarized targets.

In the #NormalTok("summaries"); slot, model parameter values are returned (see #ref(<tbl-dungan-sum-temp>, supplement: [Table])). These are produced using #NormalTok("broom.mixed::tidy()"); which is a general function to retrieve model parameters from many regression model packages in R.

In the #NormalTok("evaluations"); slot, each model is evaluated using tests from the #link("https://cran.r-project.org/web/packages/DHARMa/vignettes/DHARMa.html")[DHARMa package] (see #ref(<tbl-dungan-eval-temp>, supplement: [Table])).

#block[
#Skylighting(([#NormalTok("m1");#FloatTok(".1");#NormalTok("_temp_sum ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap_summarise");#NormalTok("(m1");#FloatTok(".1");#NormalTok("_temp, ");#AttributeTok("verbose =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(")");],));
]
#figure([
#{set text(font: ("Segoe UI", "Arial", "Segoe UI Emoji", "Segoe UI Symbol") , size: 7.5pt);table(
  columns: 8,
  align: (left,left,left,left,right,right,right,right,),
  table.header(table.cell(align: bottom + left, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    target], table.cell(align: bottom + left, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    effect], table.cell(align: bottom + left, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    component], table.cell(align: bottom + left, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    term], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    estimate], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    std.error], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    statistic], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    p.value],),
  table.hline(),
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Axin2], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[fixed], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[cond], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[\(Intercept)], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[ 5.438], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.048], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[113.314], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Axin2], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[fixed], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[cond], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[treatmentSenolytic], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[−0.199], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.069], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[ −2.897], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.004],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Axin2], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[fixed], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[cond], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[surgeryOverload], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[−0.27 ], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.069], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[ −3.939], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[8.177~×~10#super[−5]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Axin2], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[fixed], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[cond], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[treatmentSenolytic:surgeryOverload], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[ 0.174], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.097], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[  1.788], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.074],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Brat1], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[fixed], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[cond], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[\(Intercept)], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[ 4.99 ], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.051], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[ 98.437], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Brat1], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[fixed], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[cond], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[treatmentSenolytic], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[−0.048], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.071], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[ −0.67 ], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.503],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Brat1], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[fixed], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[cond], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[surgeryOverload], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[ 0.209], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.068], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[  3.069], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.002],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Brat1], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[fixed], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[cond], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[treatmentSenolytic:surgeryOverload], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[ 0.003], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.096], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[  0.03 ], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.976],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Cav2], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[fixed], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[cond], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[\(Intercept)], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[ 6.072], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.047], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[128.043], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Cav2], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[fixed], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[cond], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[treatmentSenolytic], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[ 0.072], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.067], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[  1.079], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.281],
)}
], caption: figure.caption(
position: top, 
[
The first ten rows from summarised preliminary models (model summaries).
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-dungan-sum-temp>


#figure([
#{set text(font: ("Segoe UI", "Arial", "Segoe UI Emoji", "Segoe UI Symbol") , size: 9pt);table(
  columns: 7,
  align: (left,left,center,right,left,center,right,),
  table.header(table.cell(align: bottom + left, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    target], table.cell(align: bottom + left, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    engine], table.cell(align: bottom + center, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    converged], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    code], table.cell(align: bottom + left, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    message], table.cell(align: bottom + center, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    singular], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    iterations],),
  table.hline(),
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Axin2], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[glmmTMB], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[TRUE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[relative convergence (4)], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[FALSE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[34],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Brat1], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[glmmTMB], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[TRUE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[relative convergence (4)], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[FALSE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[30],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Cav2], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[glmmTMB], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[TRUE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[relative convergence (4)], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[FALSE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[31],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Ccnd2], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[glmmTMB], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[TRUE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[relative convergence (4)], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[FALSE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[25],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Cdc45], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[glmmTMB], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[TRUE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[relative convergence (4)], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[FALSE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[30],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Cox5a], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[glmmTMB], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[TRUE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[relative convergence (4)], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[FALSE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[43],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Dlat], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[glmmTMB], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[TRUE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[relative convergence (4)], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[FALSE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[39],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Drp2], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[glmmTMB], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[TRUE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[relative convergence (4)], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[FALSE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[22],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Fer], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[glmmTMB], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[TRUE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[relative convergence (4)], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[FALSE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[31],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Fgf6], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[glmmTMB], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[TRUE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[relative convergence (4)], table.cell(align: horizon + center, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[FALSE], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[27],
)}
], caption: figure.caption(
position: top, 
[
The first ten rows from summarised preliminary models (model evaluations). Values are p-values from the DHARMa package (see #link("https://cran.r-project.org/web/packages/DHARMa/vignettes/DHARMa.html")[here for details]).
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-dungan-eval-temp>


== Specifying summary and evaluation functions
<specifying-summary-and-evaluation-functions>
We can specify custom functions for evaluating or summarizing the model object. seqwrap allows for two slots (summaries and evaluations). Each function should take the model object as an argument, and for compatibility with #NormalTok("seqwrap_summarise()");, return a data frame. For our next step, we would like to retrieve the dispersion parameter from each model. We will place this parameter in the evaluation function. We can extract the dispersion parameter on the log scale from the glmmTMB model object. We will construct a function around the extraction and include the observed counts from the data:

#block[
#Skylighting(([#NormalTok("dispersion_fun ");#OtherTok("<-");#NormalTok(" ");#ControlFlowTok("function");#NormalTok("(x) {");],
[#NormalTok("  ");],
[#NormalTok("    out ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("data.frame");#NormalTok("(");],
[#NormalTok("      ");#AttributeTok("dispersion =");#NormalTok("  ");#FunctionTok("data.frame");#NormalTok("(");#FunctionTok("summary");#NormalTok("(x");#SpecialCharTok("$");#NormalTok("sdr))[");#StringTok("\"betadisp\"");#NormalTok(",");#DecValTok("1");#NormalTok("],");],
[#NormalTok("      ");#AttributeTok("dispersion.se =");#NormalTok(" ");#FunctionTok("data.frame");#NormalTok("(");#FunctionTok("summary");#NormalTok("(x");#SpecialCharTok("$");#NormalTok("sdr))[");#StringTok("\"betadisp\"");#NormalTok(",");#DecValTok("2");#NormalTok("],");],
[#NormalTok("      ");#AttributeTok("log_mu =");#NormalTok(" ");#FunctionTok("log");#NormalTok("(");#FunctionTok("mean");#NormalTok("(x");#SpecialCharTok("$");#NormalTok("frame");#SpecialCharTok("$");#NormalTok("y))");],
[#NormalTok("      )");],
[#NormalTok("  ");],
[#NormalTok("    ");#FunctionTok("return");#NormalTok("(out)");],
[#NormalTok("  ");],
[#NormalTok("}");],));
]
Using our preliminary models, we can validate the function for one model.

#block[
#Skylighting(([#FunctionTok("dispersion_fun");#NormalTok("(m1");#FloatTok(".1");#NormalTok("_temp");#SpecialCharTok("@");#NormalTok("models[[");#DecValTok("1");#NormalTok("]])");],));
#block[
#Skylighting(([#NormalTok("  dispersion dispersion.se   log_mu");],
[#NormalTok("1   5.043444     0.5786351 5.228967");],));
]
]
The output is, as expected, a data frame with three columns. The dispersion parameter is expected to be on the log scale. To validate this we can directly access the estimated dispersion parameter from the model object using #NormalTok("sigma()");, which return the dispersion parameter on the natural scale.

#block[
#Skylighting(([#FunctionTok("log");#NormalTok("(");#FunctionTok("sigma");#NormalTok("(m1");#FloatTok(".1");#NormalTok("_temp");#SpecialCharTok("@");#NormalTok("models[[");#DecValTok("1");#NormalTok("]]))");],));
#block[
#Skylighting(([#NormalTok("[1] 5.043444");],));
]
]
For this particular task, seqwrap includes the function #NormalTok("dispersion_evaluation()"); which can be used to extract dispersion parameters from a glmmTMB model object containing a negative binomial model.

#block[
#Skylighting(([#NormalTok("seqwrap");#SpecialCharTok("::");#FunctionTok("dispersion_evaluation");#NormalTok("(m1");#FloatTok(".1");#NormalTok("_temp");#SpecialCharTok("@");#NormalTok("models[[");#DecValTok("1");#NormalTok("]])");],));
#block[
#Skylighting(([#NormalTok("# A tibble: 1 × 3");],
[#NormalTok("  dispersion dispersion.se log_mu");],
[#NormalTok("       <dbl>         <dbl>  <dbl>");],
[#NormalTok("1       5.04         0.579   5.23");],));
]
]
The reason for making your own summary or evaluation function could be, e.g., to extract custom contrasts or collect specific optimizer convergence diagnostics. Using a custom function, we could incorporate functionality from packages like marginaleffects @arel-bundock_how_2024 or DHARMa @DHARMa.

== Running the full model
<running-the-full-model>
When we are happy with preliminary performance on a subset of targets, we can initialize #NormalTok("seqwrap()"); to iterate over all targets. We are updating the previous model with the evaluation function directly in #NormalTok("seqwrap()");. Notice that we also remove the #NormalTok("subset"); and set #NormalTok("return_models"); to #NormalTok("FALSE");. Saving all model objects will be too memory-consuming.

#NormalTok("seqwrap()"); will give us a message about the expected update frequency of the progress bar and how many targets we are fitting (if #NormalTok("verbose = TRUE");).

We should expect some errors from modelling many thousands of targets. As seen in the note from #NormalTok("seqwrap()");, some models are associated with warnings from the modelling algorithm and/or errors from the evaluation function.

#block[
#Skylighting(([#NormalTok("m1");#FloatTok(".2");#NormalTok("_results ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap");#NormalTok("(");],
[#NormalTok("  m1");#FloatTok(".1");#NormalTok(",");],
[#NormalTok("  ");#AttributeTok("eval_fun =");#NormalTok(" dispersion_evaluation,");],
[#NormalTok("  ");#AttributeTok("cores =");#NormalTok(" parallel");#SpecialCharTok("::");#FunctionTok("detectCores");#NormalTok("(), ");],
[#NormalTok("  ");#AttributeTok("return_models =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(",");],
[#NormalTok("  ");#AttributeTok("verbose =");#NormalTok(" ");#ConstantTok("TRUE");],
[#NormalTok(")");],));
#block[
#Skylighting(());
]
#block[
#Skylighting(([#NormalTok("── seqwrap ─────────────────────────────────────────────────────────────────────");],));
]
#block[
#Skylighting(([#NormalTok("Initiating clusters for parallel processing with 12 cores");],
[#NormalTok("Fitting 12273 targets in 48 chunks of up to 256 targets");],
[#NormalTok("The progress bar updates 4 times (once per 12 chunks completed), in steps of");],
[#NormalTok("about 25%; use a smaller `chunk_size` for more frequent updates");],
[#NormalTok("Merging and modelling data");],
[#NormalTok("nov 26 2026 14:51:39: Completed model fitting and evaluation. Elapsed time was");],
[#NormalTok("1.26 minutes");],
[#NormalTok("ℹ Some targets had associated errors or warnings");],
[],
[#NormalTok("• Fitting algorithm (errors): n = 0 (0%)");],
[#NormalTok("• Fitting algorithm (warnings): n = 111 (1%)");],
[#NormalTok("• Summary function (errors): n = 0 (0%)");],
[#NormalTok("• Summary function (warnings): n = 0 (0%)");],
[#NormalTok("• Evaluation function (errors): n = 0 (0%)");],
[#NormalTok("• Evaluation function (warnings): n = 53 (0%)");],));
]
]
Errors can be inspected by accessing the errors slot. From the inspection below, warnings are at least to some extent related to model convergence.

#block[
#Skylighting(([#NormalTok("warnings ");#OtherTok("<-");#NormalTok(" m1");#FloatTok(".2");#NormalTok("_results");#SpecialCharTok("@");#NormalTok("errors ");#SpecialCharTok("|>");],
[#NormalTok("  ");#CommentTok("# one row per condition: keep warnings raised at the fit stage");],
[#NormalTok("  ");#FunctionTok("filter");#NormalTok("(stage ");#SpecialCharTok("==");#NormalTok(" ");#StringTok("\"fit\"");#NormalTok(", type ");#SpecialCharTok("==");#NormalTok(" ");#StringTok("\"warning\"");#NormalTok(") ");#SpecialCharTok("|>");],
[#NormalTok("  ");#CommentTok("# save in object");],
[#NormalTok("  ");#FunctionTok("pull");#NormalTok("(message)");],
[],
[#NormalTok("warnings[");#DecValTok("1");#NormalTok("]");],));
#block[
#Skylighting(([#NormalTok("                                                                                     1010001B22Rik ");],
[#NormalTok("\"Model convergence problem; non-positive-definite Hessian matrix. See vignette('troubleshooting')\" ");],));
]
]
== Using target data for prior information in glmmTMB
<using-target-data-for-prior-information-in-glmmtmb>
A major benefit of canonical R packages for RNA-seq data modelling is the sharing of information between targets through shrinkage and empirical Bayes strategies. We suggest (see the main text) using priors in glmmTMB as convenient way of flexibly regularize models using an empirical Bayes strategy. In glmmTMB, the #NormalTok("priors"); argument can be used to set priors on parameters. We will use the estimated parameters from the first model to set up the priors.

First, we need to extract the parameters. From the evaluation function we get the average log count and the dispersion parameter estimate. From the summaries, we will get the other parameters (summarized in #ref(<fig-dungan-estimates>, supplement: [Figure S])).

#block[
#Skylighting(([#NormalTok("m1");#FloatTok(".2");#NormalTok("_sum ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap_summarise");#NormalTok("(m1");#FloatTok(".2");#NormalTok("_results, ");#AttributeTok("verbose =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(")");],));
]
#figure([
#box(image("supplement_files/figure-typst/fig-dungan-estimates-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Estimates from modelling the Dungan data. The dispersion trend is visualized using the default #NormalTok("ggplot");2::geom\_smooth\`.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-dungan-estimates>


Except for the dispersion values, we can easily summarize parameter values by their mean and standard deviation. A more elaborate summary of the dispersion values could include an estimate of the mean (log) dispersion, conditional on the average log counts. As the dispersion prior will be slightly different for each target (based on the observed counts), we will combine priors into target-specific data frames and store them as a list. #NormalTok("seqwrap()"); will make target-specific list elements available in each iteration, making it possible to build the prior data frame for #NormalTok("glmmTMB()");.

To make this process more user friendly seqwrap (version \> 0.8.1) includes a helper function for putting a list of priors together.

#block[
#Skylighting(([#CommentTok("# Summarise parameters from the main output and organizes a ");],
[#CommentTok("# list of target-specific priors");],
[#NormalTok("Prior_list ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap_priors");#NormalTok("(m1");#FloatTok(".2");#NormalTok("_results, ");#AttributeTok("data =");#NormalTok(" counts)");],));
]
We can inspect the resulting prior by printing the list object

#block[
#Skylighting(([#NormalTok("Prior_list");],));
#block[
#Skylighting(());
]
#block[
#Skylighting(([#NormalTok("── seqwrap priors ──────────────────────────────────────────────────────────────");],));
]
#block[
#Skylighting(([#NormalTok("Priors for 12273 targets, estimated from 12273 fitted targets.");],
[],
[],
[#NormalTok("── Fixed effects (class \"fixef\") ");],
[],
[#NormalTok("• treatmentSenolytic: normal(0, 0.137)");],
[#NormalTok("• surgeryOverload: normal(0, 0.587)");],
[#NormalTok("• treatmentSenolytic:surgeryOverload: normal(0, 0.164)");],
[],
[],
[#NormalTok("── Dispersion (class \"fixef_disp\") ");],
[],
[#NormalTok("• normal(trend, 2.296) with the location read from a loess curve of log");],
[#NormalTok("  dispersion against log mean count");],
[#NormalTok("ℹ Pass this object as `targetdata` to `seqwrap_compose()` and refer");],
[#NormalTok("to `prior`, `class` and `coef` in `arguments`.");],));
]
]
We can also visually inspect the prior using the plot function.

#Skylighting(([#FunctionTok("plot");#NormalTok("(Prior_list)");],));
#figure([
#box(image("supplement_files/figure-typst/fig-prior-dungan-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Empirical Bayes priors estimated from the Dungan data set.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-prior-dungan>


Again, we will combine data, metadata, and arguments using #NormalTok("seqwrap_compose()");. We are now also adding the priors to the arguments. The variables used in the priors data frame are made available from the target-specific list referenced in #NormalTok("targetdata = Prior_list");. Using #NormalTok("arguments = alist(..."); avoids evaluation of the list so that the data frame is not evaluated before being used in each iteration. Priors have been built corresponding what is expected by #NormalTok("glmmTMB()"); (see #link("https://glmmtmb.github.io/glmmTMB/articles/priors.html")[Priors in glmmTMB]).

#block[
#Skylighting(([#NormalTok("m1");#FloatTok(".3");#NormalTok(" ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap_compose");#NormalTok("(");],
[#NormalTok("  ");#AttributeTok("modelfun =");#NormalTok(" glmmTMB");#SpecialCharTok("::");#NormalTok("glmmTMB,");],
[#NormalTok("  ");#AttributeTok("data =");#NormalTok(" counts, ");],
[#NormalTok("  ");#AttributeTok("metadata =");#NormalTok(" metadata, ");],
[#NormalTok("  ");#AttributeTok("eval_fun =");#NormalTok(" dispersion_evaluation, ");],
[#NormalTok("  ");#AttributeTok("arguments =");#NormalTok("  ");#FunctionTok("alist");#NormalTok("(");],
[#NormalTok("    ");#AttributeTok("formula =");#NormalTok(" y ");#SpecialCharTok("~");#NormalTok(" treatment ");#SpecialCharTok("*");#NormalTok(" surgery ");#SpecialCharTok("+");#NormalTok(" ");#FunctionTok("offset");#NormalTok("(efflibsize), ");],
[#NormalTok("    ");#AttributeTok("family =");#NormalTok(" glmmTMB");#SpecialCharTok("::");#NormalTok("nbinom2,");],
[#NormalTok("      ");#AttributeTok("priors =");#NormalTok(" ");#FunctionTok("data.frame");#NormalTok("(");],
[#NormalTok("        ");#AttributeTok("prior =");#NormalTok(" prior,");],
[#NormalTok("        ");#AttributeTok("class =");#NormalTok(" class,");],
[#NormalTok("        ");#AttributeTok("coef =");#NormalTok(" coef)), ");],
[#NormalTok("  ");#AttributeTok("targetdata =");#NormalTok(" Prior_list");],
[#NormalTok(")");],
[],
[],
[#NormalTok("m1");#FloatTok(".3");#NormalTok("_temp ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap");#NormalTok("(");],
[#NormalTok("  m1");#FloatTok(".3");#NormalTok(", ");],
[#NormalTok("  ");#AttributeTok("subset =");#NormalTok(" ");#DecValTok("1");#SpecialCharTok(":");#DecValTok("24");#NormalTok(", ");],
[#NormalTok("  ");#AttributeTok("return_models =");#NormalTok(" ");#ConstantTok("TRUE");#NormalTok(", ");],
[#NormalTok("  ");#AttributeTok("verbose =");#NormalTok(" ");#ConstantTok("FALSE");],
[#NormalTok(")");],));
#block[
#Skylighting(([#NormalTok("Warning: You are saving 24 model objects which could be very memory intensive. If this");],
[#NormalTok("was intended, ignore this warning.");],));
]
#Skylighting(([#FunctionTok("summary");#NormalTok("(m1");#FloatTok(".3");#NormalTok("_temp");#SpecialCharTok("@");#NormalTok("models[[");#DecValTok("1");#NormalTok("]])");],));
#block[
#Skylighting(([#NormalTok(" Family: nbinom2  ( log )");],
[#NormalTok("Formula:          y ~ treatment * surgery + offset(efflibsize)");],
[#NormalTok("Data: list(y = c(194L, 186L, 217L, 183L, 168L, 180L, 160L, 158L, 183L,  ");],
[#NormalTok("198L, 183L, 183L, 168L, 200L, 176L, 254L, 232L, 186L, 169L, 154L ");],
[#NormalTok("), treatment = structure(c(2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L,  ");],
[#NormalTok("2L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L), levels = c(\"Vehicle\",  ");],
[#NormalTok("\"Senolytic\"), class = \"factor\"), surgery = structure(c(2L, 2L,  ");],
[#NormalTok("2L, 2L, 2L, 1L, 1L, 1L, 1L, 1L, 2L, 2L, 2L, 2L, 2L, 1L, 1L, 1L,  ");],
[#NormalTok("1L, 1L), levels = c(\"Sham\", \"Overload\"), class = \"factor\"), efflibsize = c(0.166155699457707,  ");],
[#NormalTok("0.196470816938507, 0.0682347925124099, 0.0387654466787985, 0.0392563629230484,  ");],
[#NormalTok("-0.0785846626255147, -0.225337792488665, -0.000892800687716758,  ");],
[#NormalTok("0.000892004305606193, -0.0490532038569703, 0.144822834668174,  ");],
[#NormalTok("-0.0984341203861923, -0.0169305794837407, 0.049199853171865,  ");],
[#NormalTok("0.100216656584421, 0.0604222716589449, -0.167592705247281, -0.28188788975239,  ");],
[#NormalTok("-0.182898895921145, -0.191409863872739))");],
[],
[#NormalTok("      AIC       BIC    logLik -2*log(L)  df.resid ");],
[#NormalTok("    189.6     194.6     -89.8     179.6        15 ");],
[],
[],
[#NormalTok("Dispersion parameter for nbinom2 family ():  144 ");],
[],
[#NormalTok("Conditional model:");],
[#NormalTok("                                   Estimate Std. Error z value Pr(>|z|)    ");],
[#NormalTok("(Intercept)                         5.40965    0.04560  118.62  < 2e-16 ***");],
[#NormalTok("treatmentSenolytic                 -0.14235    0.06024   -2.36 0.018123 *  ");],
[#NormalTok("surgeryOverload                    -0.23064    0.06436   -3.58 0.000339 ***");],
[#NormalTok("treatmentSenolytic:surgeryOverload  0.09744    0.08297    1.17 0.240232    ");],
[#NormalTok("---");],
[#NormalTok("Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1");],
[],
[#NormalTok("Priors:");],
[#NormalTok("fixef(treatmentSenolytic) ~ normal(0, 0.137) ");],
[#NormalTok("fixef(surgeryOverload) ~ normal(0, 0.587) ");],
[#NormalTok("fixef(treatmentSenolytic:surgeryOverload) ~ normal(0, 0.164) ");],
[#NormalTok("fixef_disp(1) ~ normal(4.946, 2.296) ");],));
]
]
Running the prototyping seems to work, the new set of models contains the prior information. We will proceed with the full data set.

#block[
#Skylighting(([#NormalTok("m1");#FloatTok(".3");#NormalTok("_results ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap");#NormalTok("(");],
[#NormalTok("  m1");#FloatTok(".3");#NormalTok(", ");],
[#NormalTok("  ");#AttributeTok("cores =");#NormalTok(" parallel");#SpecialCharTok("::");#FunctionTok("detectCores");#NormalTok("(),");],
[#NormalTok("  ");#AttributeTok("return_models =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(", ");],
[#NormalTok("  ");#AttributeTok("verbose =");#NormalTok(" ");#ConstantTok("TRUE");],
[#NormalTok(")");],));
#block[
#Skylighting(());
]
#block[
#Skylighting(([#NormalTok("── seqwrap ─────────────────────────────────────────────────────────────────────");],));
]
#block[
#Skylighting(([#NormalTok("Initiating clusters for parallel processing with 12 cores");],
[#NormalTok("Fitting 12273 targets in 48 chunks of up to 256 targets");],
[#NormalTok("The progress bar updates 4 times (once per 12 chunks completed), in steps of");],
[#NormalTok("about 25%; use a smaller `chunk_size` for more frequent updates");],
[#NormalTok("Merging and modelling data");],
[#NormalTok("nov 26 2026 14:53:15: Completed model fitting and evaluation. Elapsed time was");],
[#NormalTok("1.44 minutes");],));
]
#Skylighting(([#NormalTok("m1");#FloatTok(".3");#NormalTok("_sum ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap_summarise");#NormalTok("(m1");#FloatTok(".3");#NormalTok("_results, ");#AttributeTok("verbose =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(")");],));
]
Regularization increases the number models without convergence issues, in fact all 12273 targets have evaluations and summaries.

The summary data frame is easily manipulated in subsequent analysis steps to, e.g., adjust p-values and create basic visualizations of the results (#ref(<fig-dungan-final-estimates>, supplement: [Figure S])). Here we use the #NormalTok("fdrtool()"); function from the fdrtool package to calculate a q-value for thresholding significant effects @strimmer2008.

#figure([
#box(image("supplement_files/figure-typst/fig-dungan-final-estimates-1.svg"))
], caption: figure.caption(
position: bottom, 
[
A visualization of results from the regularized model of the Dungan et al.~data.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-dungan-final-estimates>


The above example shows how to build models with seqwrap. Importantly, we make no claims about the validity of the final model but urge the user to assess assumptions in their data and models as part of a principled workflow.

= Comparing lmerSeq and seqwrap
<comparing-lmerseq-and-seqwrap>
lmerSeq is a package for fitting RNA-seq data using mixed-effects models assuming Gaussian errors on transformed count data. Here, we perform a basic comparison between lmerSeq @vestal_lmerseq_2022 and seqwrap, using a subset from the gene expression data set presented in the main text from Pillon et al. @pillon2022.

== Data preprocessing
<data-preprocessing>
Here the Pillion gene expression data is downloaded and transformed using VST transform from DESeq2 as suggested in @vestal_lmerseq_2022.

#block[
#Skylighting(([#CommentTok("# Need installation from github: https://github.com/stop-pre16/lmerSeq");],
[#FunctionTok("library");#NormalTok("(lmerSeq) ");],
[#FunctionTok("library");#NormalTok("(DESeq2)");],
[#FunctionTok("library");#NormalTok("(edgeR)");],
[],
[#FunctionTok("library");#NormalTok("(dplyr)");],
[#FunctionTok("library");#NormalTok("(tidyverse)");],
[#FunctionTok("library");#NormalTok("(seqwrap)");],
[#FunctionTok("library");#NormalTok("(purrr)");],
[#FunctionTok("library");#NormalTok("(glmmSeq)");],
[#FunctionTok("library");#NormalTok("(ggplot2)");],
[],
[#CommentTok("# Load the data from seqwrappaper package");],
[#NormalTok("dat ");#OtherTok("<-");#NormalTok(" seqwrappaper");#SpecialCharTok("::");#NormalTok("pillon_counts");],
[],
[],
[#CommentTok("# Filter low expressed genes and combine after filtering");],
[#NormalTok("keep ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("filterByExpr");#NormalTok("(");],
[#NormalTok("  dat");#SpecialCharTok("$");#NormalTok("countdata[,");#SpecialCharTok("-");#DecValTok("1");#NormalTok("],");],
[#NormalTok("  ");#AttributeTok("min.count =");#NormalTok(" ");#DecValTok("10");#NormalTok(",");],
[#NormalTok("  ");#AttributeTok("min.total.count =");#NormalTok(" ");#DecValTok("15");#NormalTok(",");],
[#NormalTok("  ");#AttributeTok("large.n =");#NormalTok(" ");#DecValTok("10");#NormalTok(",");],
[#NormalTok("  ");#AttributeTok("min.prop =");#NormalTok(" ");#FloatTok("0.7");#NormalTok(",");],
[#NormalTok("  ");#AttributeTok("group =");#NormalTok(" ");#FunctionTok("paste");#NormalTok("(dat");#SpecialCharTok("$");#NormalTok("metadata");#SpecialCharTok("$");#NormalTok("group, dat");#SpecialCharTok("$");#NormalTok("metadata");#SpecialCharTok("$");#NormalTok("time))");],
[],
[#NormalTok("countdat ");#OtherTok("<-");#NormalTok("  dat");#SpecialCharTok("$");#NormalTok("countdata[keep,]");],
[],
[#NormalTok("metadat ");#OtherTok("<-");#NormalTok(" dat");#SpecialCharTok("$");#NormalTok("metadata");],
[],
[],
[#CommentTok("# Check if sequence_ID matches.");],
[#FunctionTok("all");#NormalTok("(");#FunctionTok("colnames");#NormalTok("(countdat)[");#SpecialCharTok("-");#DecValTok("1");#NormalTok("] ");#SpecialCharTok("==");#NormalTok(" metadat");#SpecialCharTok("$");#NormalTok("seq_sample_id)");],));
#block[
#Skylighting(([#NormalTok("[1] TRUE");],));
]
#Skylighting(([#CommentTok("# Transform the count data using DESeq2's VST");],
[#NormalTok("dds ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("DESeqDataSetFromMatrix");#NormalTok("(");#AttributeTok("countData =");#NormalTok(" countdat[,");#SpecialCharTok("-");#DecValTok("1");#NormalTok("],");],
[#NormalTok("                              ");#AttributeTok("colData =");#NormalTok(" metadat,");],
[#NormalTok("                              ");#AttributeTok("design =");#NormalTok(" ");#SpecialCharTok("~");#NormalTok(" time ");#SpecialCharTok("*");#NormalTok(" group)");],
[],
[#NormalTok("dds ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("DESeq");#NormalTok("(dds)");],
[#NormalTok("vsd.fixed ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("varianceStabilizingTransformation");#NormalTok("(dds, ");#AttributeTok("blind=");#NormalTok("F)");],
[#NormalTok("vst_expr ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("assay");#NormalTok("(vsd.fixed)");],
[],
[],
[],
[],
[],
[#CommentTok("# Add as gene_ids to the VST-transformed counts");],
[#FunctionTok("rownames");#NormalTok("(vst_expr) ");#OtherTok("<-");#NormalTok(" countdat");#SpecialCharTok("$");#NormalTok("geneid");],
[],
[#CommentTok("# subset to only the first fifteen genes");],
[#NormalTok("vst_expr ");#OtherTok("<-");#NormalTok(" vst_expr[");#DecValTok("1");#SpecialCharTok(":");#DecValTok("15");#NormalTok(",]");],));
]
== Fitting models in lmerSeq
<fitting-models-in-lmerseq>
lmerSeq has a #NormalTok("lmerseq.fit()"); function for building and fitting the model.

#block[
#Skylighting(([#CommentTok("# fit the model using lmerseq");],
[#NormalTok("fit.lmerSeq ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("lmerSeq.fit");#NormalTok("(");#AttributeTok("form =");#NormalTok(" ");#SpecialCharTok("~");#NormalTok(" time ");#SpecialCharTok("*");#NormalTok(" group  ");#SpecialCharTok("+");#NormalTok(" (");#DecValTok("1");#SpecialCharTok("|");#NormalTok("id),");],
[#NormalTok("                           ");#AttributeTok("expr_mat =");#NormalTok(" vst_expr,");],
[#NormalTok("                           ");#AttributeTok("sample_data =");#NormalTok(" metadat,");],
[#NormalTok("                           ");#AttributeTok("parallel =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(",");],
[#NormalTok("                           ");#AttributeTok("REML =");#NormalTok(" ");#ConstantTok("TRUE");#NormalTok(")");],
[],
[],
[],
[#CommentTok("# Extract coefficients from the models ");],
[#NormalTok("coefs ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("c");#NormalTok("(");#StringTok("\"timepost\"");#NormalTok(", ");#StringTok("\"timerec\"");#NormalTok(", ");#StringTok("\"groupT2D\"");#NormalTok(", ");#StringTok("\"timepost:groupT2D\"");#NormalTok(", ");#StringTok("\"timerec:groupT2D\"");#NormalTok(")");],
[],
[#CommentTok("# Extract all coefficients from lmerseq models");],
[#NormalTok("lmerseq_summary ");#OtherTok("<-");#NormalTok(" coefs ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("  ");#FunctionTok("map_df");#NormalTok("(");#SpecialCharTok("~");#NormalTok(" ");#FunctionTok("lmerSeq.summary");#NormalTok("(");],
[#NormalTok("    ");#AttributeTok("lmerSeq_results =");#NormalTok(" fit.lmerSeq,");],
[#NormalTok("    ");#AttributeTok("coefficient =");#NormalTok(" .x,");],
[#NormalTok("    ");#AttributeTok("p_adj_method =");#NormalTok(" ");#StringTok("\"BH\"");#NormalTok(",");],
[#NormalTok("    ");#AttributeTok("ddf =");#NormalTok(" ");#StringTok("\"Satterthwaite\"");#NormalTok(",");],
[#NormalTok("    ");#AttributeTok("sort_results =");#NormalTok(" ");#ConstantTok("FALSE");],
[#NormalTok("  )");#SpecialCharTok("$");#NormalTok("summary_table ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("    ");#FunctionTok("mutate");#NormalTok("(");#AttributeTok("Coefficient =");#NormalTok(" .x)");],
[#NormalTok("  )");],));
]
== Fitting models in transformed data in seqwrap
<fitting-models-in-transformed-data-in-seqwrap>
Below we are building the same model with seqwrap. We are using #NormalTok("lmerTest::lmer()"); to get p-values from each model. lmerSeq filters targets from the output due to singular fit, here we add a small function that evaluates singular fits in the lme4-based model. We will use only models with non-singular fits in the comparison.

#block[
#Skylighting(([#CommentTok("# make data suitable for seqwrap as it accepts only data frames or lists");],
[#NormalTok("vst_expr_df ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("data.frame");#NormalTok("(vst_expr) ");#SpecialCharTok("%>%");],
[#NormalTok("  tibble");#SpecialCharTok("::");#FunctionTok("rownames_to_column");#NormalTok("(");#AttributeTok("var =");#NormalTok(" ");#StringTok("\"target\"");#NormalTok(")");],
[],
[#CommentTok("# Creating a evaluation function for finding singular fits");],
[#NormalTok("singular_eval ");#OtherTok("<-");#NormalTok(" ");#ControlFlowTok("function");#NormalTok("(x) {");],
[#NormalTok("  out ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("data.frame");#NormalTok("(");#AttributeTok("isSingular =");#NormalTok(" lme4");#SpecialCharTok("::");#FunctionTok("isSingular");#NormalTok("(x))");],
[#NormalTok("  ");#FunctionTok("return");#NormalTok("(out)");],
[#NormalTok("}");],
[],
[],
[],
[#CommentTok("# first validate input using seqwrap compose");],
[#NormalTok("seqwrap_val ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap_compose");#NormalTok("(");],
[#NormalTok("  ");#AttributeTok("data =");#NormalTok(" vst_expr_df,");],
[#NormalTok("  ");#AttributeTok("metadata =");#NormalTok(" metadat,");],
[#NormalTok("  ");#AttributeTok("samplename =");#NormalTok(" ");#StringTok("\"seq_sample_id\"");#NormalTok(",");],
[#NormalTok("  ");#AttributeTok("modelfun =");#NormalTok(" lmerTest");#SpecialCharTok("::");#NormalTok("lmer,");],
[#NormalTok("  ");#AttributeTok("arguments =");#NormalTok(" ");#FunctionTok("list");#NormalTok("(");],
[#NormalTok("    ");#AttributeTok("formula =");#NormalTok(" y ");#SpecialCharTok("~");#NormalTok(" time ");#SpecialCharTok("*");#NormalTok(" group  ");#SpecialCharTok("+");#NormalTok(" (");#DecValTok("1");#SpecialCharTok("|");#NormalTok("id)), ");],
[#NormalTok("  ");#AttributeTok("eval_fun =");#NormalTok(" singular_eval");],
[#NormalTok(")");],
[],
[],
[#NormalTok("seqwrap_model ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap");#NormalTok("(seqwrap_val,");],
[#NormalTok("                        ");#AttributeTok("return_models =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(",");],
[#NormalTok("                        ");#AttributeTok("cores =");#NormalTok(" parallel");#SpecialCharTok("::");#FunctionTok("detectCores");#NormalTok("(), ");],
[#NormalTok("                        ");#AttributeTok("verbose =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(")");],
[],
[],
[],
[#CommentTok("# Check for singular fits and list only targets without ");],
[#NormalTok("targets ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap_summarise");#NormalTok("(seqwrap_model, ");],
[#NormalTok("                             ");#AttributeTok("verbose =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(")");#SpecialCharTok("$");#NormalTok("evaluations ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("  ");#FunctionTok("filter");#NormalTok("(");#SpecialCharTok("!");#NormalTok("isSingular) ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("  ");#FunctionTok("pull");#NormalTok("(target)");],
[],
[],
[#NormalTok("seqwrap_summary_df ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap_summarise");#NormalTok("(seqwrap_model, ");],
[#NormalTok("                                        ");#AttributeTok("verbose =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(")");#SpecialCharTok("$");#NormalTok("summaries ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("  ");#FunctionTok("filter");#NormalTok("(target ");#SpecialCharTok("%in%");#NormalTok(" targets)");],));
]
== Comparing results from lmerSeq and seqwrap
<comparing-results-from-lmerseq-and-seqwrap>
Since both lmerSeq and seqwrap uses the same underlying model and data, the output estimates are the same. The estimates and p-values of both approaches are visualized in #ref(<fig-comp-visualisation>, supplement: [Figure S])

#block[
#Skylighting(([#NormalTok("Warning: Removed 5 rows containing missing values or values outside the scale range");],
[#NormalTok("(`geom_point()`).");],
[#NormalTok("Removed 5 rows containing missing values or values outside the scale range");],
[#NormalTok("(`geom_point()`).");],));
]
#figure([
#box(image("supplement_files/figure-typst/fig-comp-visualisation-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Comparing estimates from lmerSeq and seqwrap
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-comp-visualisation>


= Fitting the negative binomial and Poisson OLRE models using seqwrap
<fitting-the-negative-binomial-and-poisson-olre-models-using-seqwrap>
In the analyses presented in the main text, we used a negative binomial model as the point of departure for the analyses. The model was fitted in #NormalTok("seqwrap()"); using #NormalTok("glmmTMB()"); with the #NormalTok("nbinom2()"); family function. Below we show the code for fitting the model described in Eq. 1 (Negative binomial (non-informed)).

We used the TMM-method @robinson2010 for calculating the effective library size before adding it to the metadata as log-transformed library sizes relative to the median-sized library. We are using the DHARMa package @DHARMa in a custom evaluation function (#NormalTok("sigma_summary2");), which also include additional metrics.

#block[
#Skylighting(([#DocumentationTok("### Code chunk not evaluated ");#AlertTok("###");],
[],
[#CommentTok("# Set the number of cores");],
[#NormalTok("CORES ");#OtherTok("<-");#NormalTok(" parallel");#SpecialCharTok("::");#FunctionTok("detectCores");#NormalTok("()");],
[],
[],
[#CommentTok("# Load packages");],
[#FunctionTok("library");#NormalTok("(seqwrap)");],
[#FunctionTok("library");#NormalTok("(tidyverse)");],
[#FunctionTok("library");#NormalTok("(edgeR)");],
[],
[#CommentTok("# Loading the data. The Pillon 2022 data set is part of the seqwrap package as `pillon_counts`.");],
[#NormalTok("dat ");#OtherTok("<-");#NormalTok(" seqwrappaper");#SpecialCharTok("::");#NormalTok("pillon_counts");],
[],
[#CommentTok("# Filter low expressed genes and combine after filtering");],
[#NormalTok("keep ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("filterByExpr");#NormalTok("(");],
[#NormalTok("  dat");#SpecialCharTok("$");#NormalTok("countdata[,");#SpecialCharTok("-");#DecValTok("1");#NormalTok("],");],
[#NormalTok("  ");#AttributeTok("min.count =");#NormalTok(" ");#DecValTok("10");#NormalTok(",");],
[#NormalTok("  ");#AttributeTok("min.total.count =");#NormalTok(" ");#DecValTok("15");#NormalTok(",");],
[#NormalTok("  ");#AttributeTok("large.n =");#NormalTok(" ");#DecValTok("10");#NormalTok(",");],
[#NormalTok("  ");#AttributeTok("min.prop =");#NormalTok(" ");#FloatTok("0.7");#NormalTok(",");],
[#NormalTok("  ");#AttributeTok("group =");#NormalTok(" ");#FunctionTok("paste");#NormalTok("(dat");#SpecialCharTok("$");#NormalTok("metadata");#SpecialCharTok("$");#NormalTok("group, dat");#SpecialCharTok("$");#NormalTok("metadata");#SpecialCharTok("$");#NormalTok("time))");],
[],
[],
[],
[#NormalTok("countdat ");#OtherTok("<-");#NormalTok("  dat");#SpecialCharTok("$");#NormalTok("countdata[keep,]");],
[#NormalTok("metadat ");#OtherTok("<-");#NormalTok(" dat");#SpecialCharTok("$");#NormalTok("metadata");],
[],
[],
[#CommentTok("# Use EdgeR to calculate the TMM");],
[#NormalTok("y ");#OtherTok("<-");#NormalTok(" edgeR");#SpecialCharTok("::");#FunctionTok("DGEList");#NormalTok("(countdat[,");#SpecialCharTok("-");#DecValTok("1");#NormalTok("])");],
[#NormalTok("y ");#OtherTok("<-");#NormalTok(" edgeR");#SpecialCharTok("::");#FunctionTok("calcNormFactors");#NormalTok("(y)");],
[],
[#CommentTok("# Store effective library sizes ");],
[#NormalTok("libsize ");#OtherTok("<-");#NormalTok(" y");#SpecialCharTok("$");#NormalTok("samples ");#SpecialCharTok("|>");],
[#NormalTok("    ");#FunctionTok("rownames_to_column");#NormalTok("(");#AttributeTok("var =");#NormalTok(" ");#StringTok("\"seq_sample_id\"");#NormalTok(") ");#SpecialCharTok("|>");],
[#NormalTok("    ");#FunctionTok("select");#NormalTok("(");#SpecialCharTok("-");#NormalTok(" group)");],
[],
[#CommentTok("# Combine all meta data");],
[#NormalTok("metadat ");#OtherTok("<-");#NormalTok(" dat");#SpecialCharTok("$");#NormalTok("metadata ");#SpecialCharTok("|>");],
[#NormalTok("  ");#FunctionTok("inner_join");#NormalTok("(libsize, ");#AttributeTok("by =");#NormalTok(" ");#StringTok("\"seq_sample_id\"");#NormalTok(") ");#SpecialCharTok("|>");],
[#NormalTok("  ");#FunctionTok("mutate");#NormalTok("(");#AttributeTok("group =");#NormalTok(" ");#FunctionTok("factor");#NormalTok("(group, ");#AttributeTok("levels =");#NormalTok(" ");#FunctionTok("c");#NormalTok("(");#StringTok("\"NGT\"");#NormalTok(", ");#StringTok("\"T2D\"");#NormalTok(")),");],
[#NormalTok("         ");#AttributeTok("time =");#NormalTok(" ");#FunctionTok("factor");#NormalTok("(time, ");#AttributeTok("levels =");#NormalTok(" ");#FunctionTok("c");#NormalTok("(");#StringTok("\"basal\"");#NormalTok(", ");#StringTok("\"post\"");#NormalTok(", ");#StringTok("\"rec\"");#NormalTok(")),");],
[#NormalTok("         ");#AttributeTok("efflibsize =");#NormalTok(" (lib.size ");#SpecialCharTok("*");#NormalTok(" norm.factors)");#SpecialCharTok("/");#FunctionTok("median");#NormalTok("(lib.size ");#SpecialCharTok("*");#NormalTok(" norm.factors),");],
[#NormalTok("         ");#AttributeTok("ln_efflibsize =");#NormalTok(" ");#FunctionTok("log");#NormalTok("(efflibsize))");],
[],
[#CommentTok("# Setting up the evaluation function");],
[#NormalTok("sigma_summary2 ");#OtherTok("<-");#NormalTok(" ");#ControlFlowTok("function");#NormalTok("(x) {");],
[],
[#NormalTok("  ");#ControlFlowTok("if");#NormalTok("(");#FunctionTok("is.null");#NormalTok("(x");#SpecialCharTok("$");#NormalTok("fit");#SpecialCharTok("$");#NormalTok("convergence)) {");],
[#NormalTok("    conv ");#OtherTok("<-");#NormalTok(" ");#DecValTok("1");],
[#NormalTok("  } ");#ControlFlowTok("else");#NormalTok(" {");],
[#NormalTok("    conv ");#OtherTok("<-");#NormalTok(" x");#SpecialCharTok("$");#NormalTok("fit");#SpecialCharTok("$");#NormalTok("convergence[[");#DecValTok("1");#NormalTok("]]");],
[#NormalTok("  }");],
[],
[#NormalTok("  ");#CommentTok("# Saving SD of Obs Level Rand Eff in the Poisson model");],
[],
[#NormalTok("  tidy_coef ");#OtherTok("<-");#NormalTok(" broom.mixed");#SpecialCharTok("::");#FunctionTok("tidy");#NormalTok("(x)");],
[],
[#NormalTok("  ");#ControlFlowTok("if");#NormalTok(" (");#FunctionTok("any");#NormalTok("(tidy_coef");#SpecialCharTok("$");#NormalTok("group ");#SpecialCharTok("%in%");#NormalTok(" ");#StringTok("\"seq_sample_id\"");#NormalTok(")) {");],
[#NormalTok("    olre.sd ");#OtherTok("<-");#NormalTok(" tidy_coef ");#SpecialCharTok("|>");],
[#NormalTok("      dplyr");#SpecialCharTok("::");#FunctionTok("filter");#NormalTok("(group ");#SpecialCharTok("==");#NormalTok(" ");#StringTok("\"seq_sample_id\"");#NormalTok(") ");#SpecialCharTok("|>");],
[#NormalTok("      dplyr");#SpecialCharTok("::");#FunctionTok("pull");#NormalTok("(estimate)");],
[#NormalTok("  } ");#ControlFlowTok("else");#NormalTok(" { olre.sd ");#OtherTok("<-");#NormalTok(" ");#ConstantTok("NA");#NormalTok(" }");],
[],
[],
[],
[#NormalTok("  ");#CommentTok("# Combine all in a data frame");],
[#NormalTok("  out ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("data.frame");#NormalTok("(");#AttributeTok("dispersion =");#NormalTok("  ");#FunctionTok("data.frame");#NormalTok("(");#FunctionTok("summary");#NormalTok("(x");#SpecialCharTok("$");#NormalTok("sdr))[");#StringTok("\"betadisp\"");#NormalTok(",");#DecValTok("1");#NormalTok("],");],
[#NormalTok("                    ");#AttributeTok("dispersion.se =");#NormalTok(" ");#FunctionTok("data.frame");#NormalTok("(");#FunctionTok("summary");#NormalTok("(x");#SpecialCharTok("$");#NormalTok("sdr))[");#StringTok("\"betadisp\"");#NormalTok(",");#DecValTok("2");#NormalTok("],");],
[#NormalTok("                    ");#AttributeTok("olre.sd =");#NormalTok(" olre.sd,");],
[#NormalTok("                    ");#AttributeTok("log_mu =");#NormalTok(" ");#FunctionTok("mean");#NormalTok("(");#FunctionTok("predict");#NormalTok("(x, ");#AttributeTok("type =");#NormalTok(" ");#StringTok("\"link\"");#NormalTok(")),");],
[#NormalTok("                    ");#AttributeTok("convergence =");#NormalTok(" conv,");],
[#NormalTok("                    ");#AttributeTok("pdHess =");#NormalTok(" x");#SpecialCharTok("$");#NormalTok("sdr");#SpecialCharTok("$");#NormalTok("pdHess,");],
[#NormalTok("                    ");#AttributeTok("aic =");#NormalTok(" ");#FunctionTok("AIC");#NormalTok("(x))");],
[#NormalTok("  ");#FunctionTok("return");#NormalTok("(out)");],
[],
[#NormalTok("}");],
[],
[],
[],
[],
[#CommentTok("# Setting up the model");],
[#NormalTok("m1 ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap_compose");#NormalTok("(");],
[#NormalTok("  ");#AttributeTok("data =");#NormalTok(" countdat,");],
[#NormalTok("  ");#AttributeTok("metadata =");#NormalTok(" metadat,");],
[#NormalTok("  ");#AttributeTok("samplename =");#NormalTok(" ");#StringTok("\"seq_sample_id\"");#NormalTok(",");],
[#NormalTok("  ");#AttributeTok("modelfun =");#NormalTok(" glmmTMB");#SpecialCharTok("::");#NormalTok("glmmTMB,");],
[#NormalTok("  ");#AttributeTok("eval_fun =");#NormalTok(" sigma_summary2,");],
[#NormalTok("  ");#AttributeTok("arguments =");#NormalTok(" ");#FunctionTok("list");#NormalTok("(");],
[#NormalTok("    ");#AttributeTok("formula =");#NormalTok(" y ");#SpecialCharTok("~");#NormalTok(" time ");#SpecialCharTok("*");#NormalTok(" group ");#SpecialCharTok("+");#NormalTok(" ");#FunctionTok("offset");#NormalTok("(ln_efflibsize) ");#SpecialCharTok("+");#NormalTok(" (");#DecValTok("1");#SpecialCharTok("|");#NormalTok("id),");],
[#NormalTok("    ");#AttributeTok("family =");#NormalTok(" glmmTMB");#SpecialCharTok("::");#NormalTok("nbinom2)");],
[#NormalTok("  )");],
[],
[#NormalTok("m1_results ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap");#NormalTok("(m1,");],
[#NormalTok("                      ");#AttributeTok("return_models =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(",");],
[#NormalTok("                      ");#AttributeTok("cores =");#NormalTok(" CORES)");],));
]
The Poisson Observation-Level Random Effect (OLRE) model was fitted using #NormalTok("glmmTMB()"); using the #NormalTok("stats::poisson()"); family function. The same data and metadata as prepared above was used. The below code corresponds to Eq. 2 in the main text (Poisson OLRE (non-informed)). Notice that the sample id variable is used to introduce the observation-level random effect into the model.

#block[
#Skylighting(([#DocumentationTok("### Code chunk not evaluated ");#AlertTok("###");],
[#NormalTok("m2 ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap_compose");#NormalTok("(");],
[#NormalTok("  ");#AttributeTok("data =");#NormalTok(" countdat,");],
[#NormalTok("  ");#AttributeTok("metadata =");#NormalTok(" metadat,");],
[#NormalTok("  ");#AttributeTok("samplename =");#NormalTok(" ");#StringTok("\"seq_sample_id\"");#NormalTok(",");],
[#NormalTok("  ");#AttributeTok("modelfun =");#NormalTok(" glmmTMB");#SpecialCharTok("::");#NormalTok("glmmTMB,");],
[#NormalTok("  ");#AttributeTok("eval_fun =");#NormalTok(" sigma_summary2,");],
[#NormalTok("  ");#AttributeTok("targetdata =");#NormalTok(" ");#ConstantTok("NULL");#NormalTok(",");],
[#NormalTok("  ");#AttributeTok("arguments =");#NormalTok(" ");#FunctionTok("list");#NormalTok("(");],
[#NormalTok("    ");#AttributeTok("formula =");#NormalTok(" y ");#SpecialCharTok("~");#NormalTok(" time ");#SpecialCharTok("*");#NormalTok(" group ");#SpecialCharTok("+");#NormalTok(" ");],
[#NormalTok("      ");#FunctionTok("offset");#NormalTok("(ln_efflibsize) ");#SpecialCharTok("+");#NormalTok(" ");],
[#NormalTok("      (");#DecValTok("1");#SpecialCharTok("|");#NormalTok("id) ");#SpecialCharTok("+");],
[#NormalTok("      (");#DecValTok("1");#SpecialCharTok("|");#NormalTok("seq_sample_id),");],
[#NormalTok("      ");#AttributeTok("family =");#NormalTok(" stats");#SpecialCharTok("::");#NormalTok("poisson)");],
[#NormalTok("  )");],
[],
[],
[#NormalTok("m2_results ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap");#NormalTok("(");],
[#NormalTok("      m2,");],
[#NormalTok("      ");#AttributeTok("return_models =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(",");],
[#NormalTok("      ");#AttributeTok("verbose =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(",");],
[#NormalTok("      ");#AttributeTok("subset =");#NormalTok(" ");#DecValTok("1");#SpecialCharTok(":");#DecValTok("16");#NormalTok(",");],
[#NormalTok("      ");#AttributeTok("cores =");#NormalTok(" ");#DecValTok("1");#NormalTok(")");],));
]
We regularized models by adding priors based on non-informed models. The general strategy was outlined above for the Dungan data example. Here follows the code for the negative binomial model.

#block[
#Skylighting(([#DocumentationTok("### Code not evaluated ");#AlertTok("###");],
[],
[#CommentTok("# Prepare priors for the regularized version");],
[#NormalTok("Priors_list ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap_priors");#NormalTok("(m1_results, ");#AttributeTok("data =");#NormalTok(" countdat)");],
[],
[#CommentTok("# Fit regularized model ");],
[#NormalTok("  m1.reg ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap_compose");#NormalTok("(");],
[#NormalTok("    ");#AttributeTok("data =");#NormalTok("  countdat,");],
[#NormalTok("    ");#AttributeTok("metadata =");#NormalTok("  metadat,");],
[#NormalTok("    ");#AttributeTok("samplename =");#NormalTok(" ");#StringTok("\"seq_sample_id\"");#NormalTok(",");],
[#NormalTok("    ");#AttributeTok("modelfun =");#NormalTok(" glmmTMB");#SpecialCharTok("::");#NormalTok("glmmTMB,");],
[#NormalTok("    ");#AttributeTok("eval_fun =");#NormalTok(" sigma_summary2,");],
[#NormalTok("    ");#AttributeTok("targetdata =");#NormalTok("  Priors_list,");],
[#NormalTok("    ");#AttributeTok("arguments =");#NormalTok(" ");#FunctionTok("alist");#NormalTok("(");],
[#NormalTok("      ");#AttributeTok("formula =");#NormalTok("  y ");#SpecialCharTok("~");#NormalTok(" time ");#SpecialCharTok("*");#NormalTok(" group ");#SpecialCharTok("+");#NormalTok(" ");#FunctionTok("offset");#NormalTok("(ln_efflibsize) ");#SpecialCharTok("+");#NormalTok(" (");#DecValTok("1");#SpecialCharTok("|");#NormalTok("id),");],
[#NormalTok("      ");#AttributeTok("family =");#NormalTok(" glmmTMB");#SpecialCharTok("::");#NormalTok("nbinom2,");],
[#NormalTok("      ");#AttributeTok("priors =");#NormalTok(" ");#FunctionTok("data.frame");#NormalTok("(");],
[#NormalTok("        ");#AttributeTok("prior =");#NormalTok(" prior,");],
[#NormalTok("        ");#AttributeTok("class =");#NormalTok(" class,");],
[#NormalTok("        ");#AttributeTok("coef =");#NormalTok(" coef) ))");],
[],
[#NormalTok("  m1.reg_results ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap");#NormalTok("(");],
[#NormalTok("    m1.reg,");],
[#NormalTok("    ");#AttributeTok("return_models =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(",");],
[#NormalTok("    ");#AttributeTok("verbose =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(",");],
[#NormalTok("    ");#CommentTok("#  subset = 1:50, # for prototyping");],
[#NormalTok("    ");#AttributeTok("cores =");#NormalTok(" CORES)");],));
]
= Analyzing DNA methylation data
<analyzing-dna-methylation-data>
The following outlines a partial reanalysis of data on CpG methylation status in human skeletal muscle in response to resistance exercise training, followed by detraining and subsequent retraining @seaborne2018@seaborne2018b. Most of the relevant code is explicitly shown here. In contrast, the version of this case study included in the manuscript has been stripped of some details.

== Packages, raw data and preprocessing
<packages-raw-data-and-preprocessing>
#block[
#Skylighting(([#CommentTok("# Packages");],
[],
[#FunctionTok("library");#NormalTok("(GEOquery)      ");#CommentTok("# For accessing the raw data");],));
#block[
#Skylighting(([#NormalTok("Setting options('download.file.method.GEOquery'='auto')");],));
]
#block[
#Skylighting(([#NormalTok("Setting options('GEOquery.inmemory.gpl'=FALSE)");],));
]
#Skylighting(([#FunctionTok("library");#NormalTok("(minfi)         ");#CommentTok("# For pre-processing of raw data");],));
#block[
#Skylighting(([#NormalTok("Loading required package: Biostrings");],));
]
#block[
#Skylighting(([#NormalTok("Loading required package: XVector");],));
]
#block[
#Skylighting(([],
[#NormalTok("Attaching package: 'XVector'");],));
]
#block[
#Skylighting(([#NormalTok("The following object is masked from 'package:purrr':");],
[],
[#NormalTok("    compact");],));
]
#block[
#Skylighting(([],
[#NormalTok("Attaching package: 'Biostrings'");],));
]
#block[
#Skylighting(([#NormalTok("The following object is masked from 'package:base':");],
[],
[#NormalTok("    strsplit");],));
]
#block[
#Skylighting(([#NormalTok("Loading required package: bumphunter");],));
]
#block[
#Skylighting(([#NormalTok("Loading required package: foreach");],));
]
#block[
#Skylighting(([],
[#NormalTok("Attaching package: 'foreach'");],));
]
#block[
#Skylighting(([#NormalTok("The following objects are masked from 'package:purrr':");],
[],
[#NormalTok("    accumulate, when");],));
]
#block[
#Skylighting(([#NormalTok("Loading required package: iterators");],));
]
#block[
#Skylighting(([#NormalTok("Loading required package: parallel");],));
]
#block[
#Skylighting(([#NormalTok("Loading required package: locfit");],));
]
#block[
#Skylighting(([#NormalTok("locfit 1.5-9.12      2025-03-05");],));
]
#block[
#Skylighting(([],
[#NormalTok("Attaching package: 'locfit'");],));
]
#block[
#Skylighting(([#NormalTok("The following object is masked from 'package:purrr':");],
[],
[#NormalTok("    none");],));
]
#Skylighting(([#FunctionTok("library");#NormalTok("(dplyr)");],
[#FunctionTok("library");#NormalTok("(tidyr)");],
[#FunctionTok("library");#NormalTok("(gt)");],
[#FunctionTok("library");#NormalTok("(ggplot2)");],
[#FunctionTok("library");#NormalTok("(stringr)");],
[#FunctionTok("library");#NormalTok("(maxprobes)     ");#CommentTok("# For filtering cross-reactive probes ");],
[#FunctionTok("library");#NormalTok("(seqwrap)");],));
]
Raw data are downloaded from the #link("https://www.ncbi.nlm.nih.gov/geo/")[Gene Expression Omnibus] using the accession number #link("https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE114763")[GSE114763] as IDAT files. See the file #NormalTok("analysis/methylation-case-study-dataprep.R"); (available in the #link("https://github.com/trainome/seqwrappaper")[project repository]) for details on downloading and preparation of the data.

The data downloading process gives us a metadata set describing the participants (#ref(<tbl-meta-samples>, supplement: [Table])).

#figure([
#{set text(font: ("Segoe UI", "Arial", "Segoe UI Emoji", "Segoe UI Symbol") , size: 12pt);table(
  columns: 4,
  align: (right,right,right,right,),
  table.header(table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    Participant], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    Age (years)], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    Height (cm)], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    Weight (kg)],),
  table.hline(),
  table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[39], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[175.0], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[72.8],
  table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[19], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[182.2], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[72.2],
  table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[3], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[29], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[177.2], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[78.6],
  table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[4], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[27], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[196.0], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[117.8],
  table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[5], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[32], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[176.4], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[79.0],
  table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[6], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[20], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[174.4], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[74.0],
  table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[7], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[23], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[172.0], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[68.0],
  table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[8], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[32], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[171.5], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[97.8],
)}
], caption: figure.caption(
position: top, 
[
Sample metadata retreived from GEO (#link("https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE114763")[GSE114763]) corresponding to #cite(<seaborne2018b>, form: "prose").
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-meta-samples>


Checking available IDAT files gives us an overview over the available data over the time-points of the study (#ref(<tbl-metadata-count>, supplement: [Table])).

#Skylighting(([#NormalTok("idat_stems ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("list.files");#NormalTok("(idat_dir, ");#AttributeTok("pattern =");#NormalTok(" ");#StringTok("\"_Grn");#SpecialCharTok("\\\\");#StringTok(".idat$\"");#NormalTok(") ");#SpecialCharTok("|>");],
[#NormalTok("  stringr");#SpecialCharTok("::");#FunctionTok("str_remove");#NormalTok("(");#StringTok("\"_Grn");#SpecialCharTok("\\\\");#StringTok(".idat$\"");#NormalTok(")");],
[],
[#NormalTok("array_info ");#OtherTok("<-");#NormalTok(" tibble");#SpecialCharTok("::");#FunctionTok("tibble");#NormalTok("(");#AttributeTok("stem =");#NormalTok(" idat_stems) ");#SpecialCharTok("|>");],
[#NormalTok("  tidyr");#SpecialCharTok("::");#FunctionTok("separate");#NormalTok("(stem, ");#AttributeTok("into =");#NormalTok(" ");#FunctionTok("c");#NormalTok("(");#StringTok("\"geo_accession\"");#NormalTok(", ");#StringTok("\"slide\"");#NormalTok(", ");#StringTok("\"array\"");#NormalTok("),");],
[#NormalTok("                  ");#AttributeTok("sep =");#NormalTok(" ");#StringTok("\"_\"");#NormalTok(", ");#AttributeTok("remove =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(") ");#SpecialCharTok("|>");],
[#NormalTok("  dplyr");#SpecialCharTok("::");#FunctionTok("mutate");#NormalTok("(");#AttributeTok("Basename =");#NormalTok(" ");#FunctionTok("file.path");#NormalTok("(idat_dir, stem))");],
[],
[#NormalTok("metadata ");#OtherTok("<-");#NormalTok(" pheno_raw ");#SpecialCharTok("|>");],
[#NormalTok("      ");#CommentTok("# Removing outlier sample, see \"Quality Control of DNA Methylation Probes\"");],
[#NormalTok("      ");#CommentTok("# in @seaborne2018b");],
[#NormalTok("      ");#FunctionTok("filter");#NormalTok("(");#SpecialCharTok("!");#FunctionTok("grepl");#NormalTok("(");#StringTok("\"SkM_Epi_Mem_1:\"");#NormalTok(", title), ");],
[#NormalTok("             ");#SpecialCharTok("!");#FunctionTok("grepl");#NormalTok("(");#StringTok("\"SkM_Epi_Mem_39:\"");#NormalTok(", title)) ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("      ");],
[#NormalTok("  tibble");#SpecialCharTok("::");#FunctionTok("as_tibble");#NormalTok("() ");#SpecialCharTok("|>");],
[#NormalTok("  dplyr");#SpecialCharTok("::");#FunctionTok("select");#NormalTok("(geo_accession,");],
[#NormalTok("                title,");],
[#NormalTok("                participant,");],
[#NormalTok("                gender,");],
[#NormalTok("                age, ");],
[#NormalTok("                time) ");#SpecialCharTok("|>");],
[#NormalTok("  dplyr");#SpecialCharTok("::");#FunctionTok("mutate");#NormalTok("(");],
[#NormalTok("    ");#AttributeTok("label =");#NormalTok(" stringr");#SpecialCharTok("::");#FunctionTok("str_remove");#NormalTok("(title, ");#StringTok("\"^SkM_Epi_Mem_");#SpecialCharTok("\\\\");#StringTok("d+:");#SpecialCharTok("\\\\");#StringTok("s*\"");#NormalTok(")) ");#SpecialCharTok("|>");],
[#NormalTok("  dplyr");#SpecialCharTok("::");#FunctionTok("left_join");#NormalTok("(array_info, ");#AttributeTok("by =");#NormalTok(" ");#StringTok("\"geo_accession\"");#NormalTok(")");],
[],
[#FunctionTok("stopifnot");#NormalTok("(");#SpecialCharTok("!");#FunctionTok("anyNA");#NormalTok("(metadata");#SpecialCharTok("$");#NormalTok("time), ");#SpecialCharTok("!");#FunctionTok("anyNA");#NormalTok("(metadata");#SpecialCharTok("$");#NormalTok("participant))");],
[],
[#CommentTok("# 38 arrays: 8 participants x 5 time points with missing values for on ");],
[#CommentTok("# participant.");],
[],
[#NormalTok("metadata ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("      ");#FunctionTok("summarise");#NormalTok("(");#AttributeTok(".by =");#NormalTok(" ");#FunctionTok("c");#NormalTok("(time, participant), ");],
[#NormalTok("                ");#AttributeTok("n =");#NormalTok(" ");#FunctionTok("n");#NormalTok("()) ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("      ");#FunctionTok("pivot_wider");#NormalTok("(");#AttributeTok("names_from =");#NormalTok(" time, ");#AttributeTok("values_from =");#NormalTok(" n) ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("      ");#FunctionTok("select");#NormalTok("(");#AttributeTok("Participant =");#NormalTok(" participant, ");],
[#NormalTok("             ");#AttributeTok("Baseline =");#NormalTok(" ");#StringTok("`");#AttributeTok("1_baseline");#StringTok("`");#NormalTok(", ");],
[#NormalTok("             ");#AttributeTok("Acute =");#NormalTok(" ");#StringTok("`");#AttributeTok("2_acute");#StringTok("`");#NormalTok(", ");],
[#NormalTok("             ");#AttributeTok("Loading =");#NormalTok(" ");#StringTok("`");#AttributeTok("3_loading");#StringTok("`");#NormalTok(", ");],
[#NormalTok("             ");#AttributeTok("Unloading =");#NormalTok(" ");#StringTok("`");#AttributeTok("4_unloading");#StringTok("`");#NormalTok(", ");],
[#NormalTok("             ");#AttributeTok("Reloading =");#NormalTok(" ");#StringTok("`");#AttributeTok("5_reloading");#StringTok("`");#NormalTok(") ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("      ");#FunctionTok("gt");#NormalTok("() ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("      ");#FunctionTok("tab_spanner");#NormalTok("(");#AttributeTok("label =");#NormalTok(" ");#StringTok("\"Sample time-points\"");#NormalTok(", ");#AttributeTok("columns =");#NormalTok(" ");#StringTok("\"Baseline\"");#SpecialCharTok(":");#StringTok("\"Reloading\"");#NormalTok(")");],));
#figure([
#{set text(font: ("Segoe UI", "Arial", "Segoe UI Emoji", "Segoe UI Symbol") , size: 12pt);table(
  columns: (16.67%, 16.67%, 16.67%, 16.67%, 16.67%, 16.67%),
  align: (right,right,right,right,right,right,),
  table.header(table.cell(align: bottom + right, rowspan: 2, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    Participant], table.cell(align: center, colspan: 5, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    #block[
    Sample time-points
    ]],
    table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    Baseline], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    Acute], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    Loading], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    Unloading], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    Reloading],),
  table.hline(),
  table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[001], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1],
  table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[002], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1],
  table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[003], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1],
  table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[004], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1],
  table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[005], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1],
  table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[006], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1],
  table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[007], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1],
  table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[008], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[1], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[NA], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[NA],
)}
], caption: figure.caption(
position: top, 
[
Samples per time-point and participant.
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-metadata-count>


We will use the minfi package @aryee2014 to read the raw data and perform quality control, filtering and normalization. As a first step, array-level filtering is done using detection p-values where methylated and unmethylated positions are compared to negative control positions. This comparison produces a p-value used to identify problematic genomic positions. As shown below (#ref(<fig-array-qc>, supplement: [Figure S])), array-level aggregates show mean values \< 0.01.

In the code below, IDAT file names (e.g., GSM3149860\_201496860025\_R01C01) are combined with the file tree in #NormalTok("Basename");. #NormalTok("minfi::read.metharray()"); iterates over all file names in this vector and imports the data.

#Skylighting(([#NormalTok("rgset ");#OtherTok("<-");#NormalTok(" minfi");#SpecialCharTok("::");#FunctionTok("read.metharray");#NormalTok("(metadata");#SpecialCharTok("$");#NormalTok("Basename, ");],
[#NormalTok("                               ");#AttributeTok("extended =");#NormalTok(" ");#ConstantTok("TRUE");#NormalTok(", ");],
[#NormalTok("                               ");#AttributeTok("force =");#NormalTok(" ");#ConstantTok("TRUE");#NormalTok(")");],
[],
[#CommentTok("# Check that orders correspond");],
[#FunctionTok("stopifnot");#NormalTok("(");#FunctionTok("identical");#NormalTok("(");#FunctionTok("colnames");#NormalTok("(rgset), ");#FunctionTok("basename");#NormalTok("(metadata");#SpecialCharTok("$");#NormalTok("Basename)))");],
[],
[#FunctionTok("colnames");#NormalTok("(rgset) ");#OtherTok("<-");#NormalTok(" metadata");#SpecialCharTok("$");#NormalTok("geo_accession");],
[],
[#CommentTok("# Perform detection check  ");],
[#NormalTok("det_p ");#OtherTok("<-");#NormalTok(" minfi");#SpecialCharTok("::");#FunctionTok("detectionP");#NormalTok("(rgset)");],));
#block[
#Skylighting(([#NormalTok("Loading required package: IlluminaHumanMethylationEPICmanifest");],));
]
#Skylighting(([#NormalTok("qc ");#OtherTok("<-");#NormalTok(" tibble");#SpecialCharTok("::");#FunctionTok("tibble");#NormalTok("(");],
[#NormalTok("  ");#AttributeTok("geo_accession =");#NormalTok(" ");#FunctionTok("colnames");#NormalTok("(det_p),");],
[#NormalTok("  ");#AttributeTok("mean_det_p    =");#NormalTok(" ");#FunctionTok("colMeans");#NormalTok("(det_p),");],
[#NormalTok("  ");#AttributeTok("frac_failed   =");#NormalTok(" ");#FunctionTok("colMeans");#NormalTok("(det_p ");#SpecialCharTok(">");#NormalTok(" ");#FloatTok("0.01");#NormalTok("))");],
[],
[#NormalTok("qc ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("      ");#FunctionTok("inner_join");#NormalTok("(pheno_raw ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("                       ");#FunctionTok("select");#NormalTok("(geo_accession, time)) ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("      ");#FunctionTok("ggplot");#NormalTok("(");#FunctionTok("aes");#NormalTok("(mean_det_p, frac_failed, ");#AttributeTok("color =");#NormalTok(" time)) ");#SpecialCharTok("+");#NormalTok(" ");],
[#NormalTok("      ");#FunctionTok("geom_point");#NormalTok("() ");#SpecialCharTok("+");],
[#NormalTok("      ");#FunctionTok("labs");#NormalTok("(");#AttributeTok("x =");#NormalTok(" ");#StringTok("\"Array-level mean detection p-value\"");#NormalTok(", ");],
[#NormalTok("           ");#AttributeTok("y =");#NormalTok(" ");#StringTok("\"Fraction of failed genomic positions (p > 0.01)\"");#NormalTok(", ");],
[#NormalTok("           ");#AttributeTok("color =");#NormalTok(" ");#StringTok("\"Time-point\"");#NormalTok(")");],));
#block[
#Skylighting(([#NormalTok("Joining with `by = join_by(geo_accession)`");],));
]
#figure([
#box(image("supplement_files/figure-typst/fig-array-qc-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Array-level quality control. Mean detection p-values and fraction of failed genomic positions per array subdivided by time-point.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-array-qc>


Next, we filter the data using the detection p-value criteria.

#block[
#Skylighting(([#CommentTok("# All samples pass quality control");],
[#NormalTok("keep_samples ");#OtherTok("<-");#NormalTok(" qc");#SpecialCharTok("$");#NormalTok("geo_accession[qc");#SpecialCharTok("$");#NormalTok("mean_det_p ");#SpecialCharTok("<");#NormalTok(" ");#FloatTok("0.01");#NormalTok("]");],
[#CommentTok("# length(keep_samples)");],
[#NormalTok("rgset    ");#OtherTok("<-");#NormalTok(" rgset[, keep_samples]");],
[#NormalTok("det_p    ");#OtherTok("<-");#NormalTok(" det_p[, keep_samples]");],
[#NormalTok("metadata ");#OtherTok("<-");#NormalTok(" metadata ");#SpecialCharTok("|>");#NormalTok(" dplyr");#SpecialCharTok("::");#FunctionTok("filter");#NormalTok("(geo_accession ");#SpecialCharTok("%in%");#NormalTok(" keep_samples)");],));
]
== Normalization and probe filtering
<normalization-and-probe-filtering>
Between-array quantile normalization, as implemented by #NormalTok("minfi::preprocessQuantile()"); @aryee2014, is used. An assumption about the data is the we do not expect genome-wide differences in methylation patterns between time-points. Probes are then removed if they (1) fail detection in any retained sample, (2) overlap common SNPs at the target CpG or single-base extension site, (3) appear on published lists of cross-reactive EPIC probes (using the #link("https://github.com/markgene/maxprobes/")[#NormalTok("maxprobes");] package), or (iv) map to the sex chromosomes (all male cohort).

The same pipeline is run by #NormalTok("analysis/R/methylation-case-study-dataprep.R");, which writes the result to #NormalTok("analysis/data/derived_data/seaborne-gset-quantile.RDS");. We use the resulting "gset" in the permutation study and for the full model run.

#block[
#Skylighting(([#CommentTok("# Between-array quantile normalization.");],
[#CommentTok("#");],
[#CommentTok("# ");#AlertTok("NOTE");#CommentTok(" THE RETURN CLASS. preprocessFunnorm(ratioConvert = FALSE) returned a");],
[#CommentTok("# GenomicMethylSet, which still carries the methylated and unmethylated");],
[#CommentTok("# intensities, so beta could be asked for as getBeta(gset, offset = 100).");],
[#CommentTok("# preprocessQuantile() returns a GenomicRatioSet built as");],
[#CommentTok("# GenomicRatioSet(Beta = NULL, M = log2(Meth / Unmeth)): there are no");],
[#CommentTok("# intensities in it and no offset anywhere, and getBeta() on such an object");],
[#CommentTok("# derives beta from M by the inverse logit and ignores `offset`.");],
[#CommentTok("# Everything downstream therefore derives beta from M explicitly.");],
[#NormalTok("gset ");#OtherTok("<-");#NormalTok(" minfi");#SpecialCharTok("::");#FunctionTok("preprocessQuantile");#NormalTok("(");],
[#NormalTok("  rgset,");],
[#NormalTok("  ");#AttributeTok("fixOutliers =");#NormalTok(" ");#ConstantTok("TRUE");#NormalTok(",");],
[#NormalTok("  ");#AttributeTok("quantileNormalize =");#NormalTok(" ");#ConstantTok("TRUE");#NormalTok(",");],
[#NormalTok("  ");#AttributeTok("stratified =");#NormalTok(" ");#ConstantTok("TRUE");#NormalTok(",");],
[#NormalTok("  ");#CommentTok("# All samples are male and the sex chromosomes are dropped below, so the sex");],
[#NormalTok("  ");#CommentTok("# prediction this would otherwise run has nothing to decide.");],
[#NormalTok("  ");#AttributeTok("sex =");#NormalTok(" ");#FunctionTok("rep");#NormalTok("(");#StringTok("\"M\"");#NormalTok(", ");#FunctionTok("ncol");#NormalTok("(rgset))");],
[#NormalTok(")");],));
#block[
#Skylighting(([#NormalTok("[preprocessQuantile] Mapping to genome.");],));
]
#block[
#Skylighting(([#NormalTok("Loading required package: IlluminaHumanMethylationEPICanno.ilm10b4.hg19");],));
]
#block[
#Skylighting(([#NormalTok("[preprocessQuantile] Fixing outliers.");],));
]
#block[
#Skylighting(([#NormalTok("[preprocessQuantile] Quantile normalizing.");],));
]
#Skylighting(([#FunctionTok("stopifnot");#NormalTok("(");#FunctionTok("is");#NormalTok("(gset, ");#StringTok("\"GenomicRatioSet\"");#NormalTok("))");],
[],
[#CommentTok("# Initial number of probes");],
[#NormalTok("nprobes_init ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("dim");#NormalTok("(gset)[");#DecValTok("1");#NormalTok("]");],
[],
[#DocumentationTok("## (i) detection");],
[#NormalTok("det_p  ");#OtherTok("<-");#NormalTok(" det_p[");#FunctionTok("match");#NormalTok("(minfi");#SpecialCharTok("::");#FunctionTok("featureNames");#NormalTok("(gset), ");#FunctionTok("rownames");#NormalTok("(det_p)), ]");],
[#NormalTok("keep   ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("rowSums");#NormalTok("(det_p ");#SpecialCharTok("<");#NormalTok(" ");#FloatTok("0.01");#NormalTok(") ");#SpecialCharTok("==");#NormalTok(" ");#FunctionTok("ncol");#NormalTok("(gset)");],
[#NormalTok("gset   ");#OtherTok("<-");#NormalTok(" gset[keep, ]");],
[],
[#CommentTok("# Number of probes after filtering");],
[#NormalTok("nprobes_detectionfilter ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("dim");#NormalTok("(gset)[");#DecValTok("1");#NormalTok("]");],
[],
[#DocumentationTok("## (ii) SNP-affected probes ");],
[#NormalTok("gset ");#OtherTok("<-");#NormalTok(" minfi");#SpecialCharTok("::");#FunctionTok("dropLociWithSnps");#NormalTok("(gset, ");#AttributeTok("snps =");#NormalTok(" ");#FunctionTok("c");#NormalTok("(");#StringTok("\"SBE\"");#NormalTok(", ");#StringTok("\"CpG\"");#NormalTok("), ");#AttributeTok("maf =");#NormalTok(" ");#DecValTok("0");#NormalTok(")");],
[],
[#NormalTok("nprobes_snp ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("dim");#NormalTok("(gset)[");#DecValTok("1");#NormalTok("]");],
[],
[#DocumentationTok("## (iii) cross-reactive probes ");],
[#NormalTok("gset ");#OtherTok("<-");#NormalTok(" maxprobes");#SpecialCharTok("::");#FunctionTok("dropXreactiveLoci");#NormalTok("(gset)");],
[],
[#NormalTok("nprobes_cross ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("dim");#NormalTok("(gset)[");#DecValTok("1");#NormalTok("]");],
[],
[#DocumentationTok("## (iv) sex chromosomes ");],
[#NormalTok("anno ");#OtherTok("<-");#NormalTok(" minfi");#SpecialCharTok("::");#FunctionTok("getAnnotation");#NormalTok("(gset)");],
[#NormalTok("gset ");#OtherTok("<-");#NormalTok(" gset[");#SpecialCharTok("!");#NormalTok("anno");#SpecialCharTok("$");#NormalTok("chr ");#SpecialCharTok("%in%");#NormalTok(" ");#FunctionTok("c");#NormalTok("(");#StringTok("\"chrX\"");#NormalTok(", ");#StringTok("\"chrY\"");#NormalTok("), ]");],
[],
[#NormalTok("nprobes_final ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("dim");#NormalTok("(gset)[");#DecValTok("1");#NormalTok("]");],
[],
[#CommentTok("# The check the beta arm depends on. M is what a GenomicRatioSet stores; beta");],
[#CommentTok("# is the inverse logit of it, which is inside the OPEN interval (0, 1) for");],
[#CommentTok("# every finite M. This is what replaces the guarantee the Illumina offset used");],
[#CommentTok("# to provide, and it is asserted rather than assumed: a non-finite M would come");],
[#CommentTok("# from an intensity of exactly zero surviving fixOutliers, and would reach the");],
[#CommentTok("# beta family as a response of exactly 0 or 1, which it cannot take.");],
[#NormalTok("m_check    ");#OtherTok("<-");#NormalTok(" minfi");#SpecialCharTok("::");#FunctionTok("getM");#NormalTok("(gset)");],
[#NormalTok("beta_check ");#OtherTok("<-");#NormalTok(" ");#DecValTok("2");#SpecialCharTok("^");#NormalTok("m_check ");#SpecialCharTok("/");#NormalTok(" (");#DecValTok("1");#NormalTok(" ");#SpecialCharTok("+");#NormalTok(" ");#DecValTok("2");#SpecialCharTok("^");#NormalTok("m_check)");],
[],
[#FunctionTok("stopifnot");#NormalTok("(");#FunctionTok("all");#NormalTok("(");#FunctionTok("is.finite");#NormalTok("(m_check)), ");#FunctionTok("all");#NormalTok("(beta_check ");#SpecialCharTok(">");#NormalTok(" ");#DecValTok("0");#NormalTok(" ");#SpecialCharTok("&");#NormalTok(" beta_check ");#SpecialCharTok("<");#NormalTok(" ");#DecValTok("1");#NormalTok("))");],
[],
[#CommentTok("# The observed distance from the boundary, reported below.");],
[#NormalTok("beta_min ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("min");#NormalTok("(beta_check)");],
[#NormalTok("beta_max ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("max");#NormalTok("(beta_check)");],
[#NormalTok("m_range  ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("range");#NormalTok("(m_check)");],
[],
[#FunctionTok("rm");#NormalTok("(m_check, beta_check)");],));
]
865859 normalized probes were filtered based on detection which retained 857874, after SNP-overlap (n = 828684), cross-reactivity (n = 787887) and sex-chromosome mapping filtering, n = 770441 remained in the data set.

== Calculation of methylation quantities
<calculation-of-methylation-quantities>
An Illumina array detecting methylation values produces arbitrary signals for the unmethylated (U) and methylated (M) portion of the i#super[th] genomic position. Converting these two values to a methylation score can be done using the calculation of a β value.

$ beta_i = frac(M_i, M_i + U_i) $ A bias constant c, is added to the denominator to avoid large variations in the β score when probe intensities are low @bibikova2006. A common choice is $c = 100$ @bibikova2006, which is also the default in the #NormalTok("minfi"); package when #NormalTok("type = \"illumina\"");. However, the successful choice of c is noted to depend on the pre-processing of the data (see #NormalTok("?minfi::getBeta");). Since we are using the #NormalTok("minfi::preprocessQuantile()"); function we get the M values directly ($M = log_2\(upright("Meth")\/upright("Unmeth")\)$) without the involvement of the c constant. The β values are instead derived from the normalized M values using the inverse logit:

$ beta_i = frac(2^(M_i), 1 + 2^(M_i)) $ Here β is restricted to the interval $\(0\,1\)$ and although this is an intuitive metric for understanding the methylation status at a specific genomic site (e.g., as a percentage methylation), it is an inconvenient quantity for a statistical model that expects normally distributed errors @laird2010@du2010. Indeed, when applying a Gaussian model to identify differentially methylated genomic sites, a logit transformation of the β-values (M values) results in more favorable diagnostics @du2010.

The observed M-values in the data set span -7.28 to 7.36, giving β values between 0.00638 and 0.993937, i.e.~0.00638 and 0.00606 away from the two boundaries making it possible to use beta regression to model β values. We can move back and forth between M and β values, to get M from β we use:

$ M = log_2 (frac(beta, 1 - beta)) $

The relationship between the two transformations can be visualized as shown in #ref(<fig-beta-mval>, supplement: [Figure S]).

#figure([
#box(image("supplement_files/figure-typst/fig-beta-mval-1.svg"))
], caption: figure.caption(
position: bottom, 
[
The logit transform of β values gives M-values.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-beta-mval>


In conclusions, two potential routes for modeling methylation values exists. We can model M values as having normally distributed errors (Gaussian model), or we could model the β values using beta regression. Next we evaluate these model choices.

== Inferential error rates across models
<inferential-error-rates-across-models>
We will compare the models using type I error rate and power determined from permutation of within-participant relabeled data. This relabeling establishes a null distribution for statistical tests performed using the within-participant design. The design keeps the within-participant correlation. Our approach is similar to what was described in @gadbury2008.

We will perform the experiment on permuted data from a subset of genomic sites distributed across different strata of β values.

A fixed number of sites is sampled from each β-value stratum. Within every permutation, a random subset of those sites receives a known effect (adding a known average effect) while the remainder are left untouched (null-sites). Sites without an effect estimate the type I error rate, sites with an added effect are used to estimate power.

We will use the M-value scale to add the effect to permuted data with effect assignment redrawn in every permutation. The β-values are derived from the manipulated M-values. A shift of δ M units is exactly the fixed-effect parameter of the Gaussian model and proportionally to δ×log(2) for the linear-predictor shift of the β model with the logit link. This means that no model is favored by the parameterization. Our approach differs here from #cite(<gadbury2008>, form: "prose"). We fix the effect sizes while #cite(<gadbury2008>, form: "prose") uses empirical effect sizes from the data. Our simplified approach enables comparisons between model fitting procedures at known effect sizes and signs across strata of β values.

In the code chunk below, a single site is used to show the workflow. M values are taken from the #NormalTok("gset"); object and β values are derived from them. We are using a randomly selected row of the M value matrix and join the values with the meta data. Within each participant, time is re-sampled to create a permuted time factor. Using the permuted time factor, an average effect (δ = 0.3) is added to all observations belonging to the permuted time-point #NormalTok("3_loading");. Data are back-transformed to the β scale and both model types are fitted.

We will use a set of different inferential alternatives to establish the most appropriate model and test for our data set. In small samples, linear mixed model parameter p-values from the Wald test are anti-conservative @luke2017. When the restricted maximum likelihood (REML) is used in place of maximum likelihood and small sample size-corrections are used (Kenward-Roger or Satterthwaite approximations of degrees of freedom) the type I error rates are controlled at the nominal level @luke2017. However, for the generalized linear mixed model (GLMM) with link functions, such as beta regression, the restricted maximum likelihood is not clearly defined @maestrini2024. When comparing different REML implementations, #cite(<maestrini2024>, form: "prose") found that GLMM fitted with REML leads to a reduction in small sample bias and that the use of REML probably should be more widely adopted. The choice of algorithm can be made based on software availability @maestrini2024. REML is implemented also for GLMM in the glmmTMB package with the option #NormalTok("REML=TRUE");. For Gaussian models, the results from #NormalTok("glmmTMB"); replicates the results of #NormalTok("lme4::lmer");. However, the documentation also says that performance of REML in non-Gaussian models should be verified by simulations (see #NormalTok("?glmmTMB::glmmTMB");).

In addition to REML for mitigation of small sample bias, the Satterthwaite correction is widely adopted in Gaussian mixed-effects models to approximate the denominator degrees of freedom for t-tests of parameter estimates @kuznetsova2017. Similarly to REML estimation for GLMM's, the Satterthwaite approximation is indicated for use "at your own risk" (see #NormalTok("?glmmTMB::dof_satt");).

#block[
#Skylighting(([#CommentTok("# Illustrating data preparation and model settings for a set of ");],
[#CommentTok("# candidate models for the methylation data set.");],
[],
[#CommentTok("# Prepare data.");],
[#CommentTok("#");],
[#CommentTok("# We first load M values and derive beta derived from them.");],
[#NormalTok("m_vals ");#OtherTok("<-");#NormalTok(" minfi");#SpecialCharTok("::");#FunctionTok("getM");#NormalTok("(gset)");],
[#NormalTok("beta_vals ");#OtherTok("<-");#NormalTok(" ");#DecValTok("2");#SpecialCharTok("^");#NormalTok("m_vals ");#SpecialCharTok("/");#NormalTok(" (");#DecValTok("1");#NormalTok(" ");#SpecialCharTok("+");#NormalTok(" ");#DecValTok("2");#SpecialCharTok("^");#NormalTok("m_vals)");],
[],
[#CommentTok("# Setting the seed for site selection and time permutation");],
[#FunctionTok("set.seed");#NormalTok("(");#DecValTok("1");#NormalTok(")");],
[],
[#CommentTok("# Selecting a random site for testing");],
[#NormalTok("y ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("data.frame");#NormalTok("(");#AttributeTok("y =");#NormalTok(" m_vals[");#FunctionTok("sample");#NormalTok("(");#DecValTok("1");#SpecialCharTok(":");#FunctionTok("nrow");#NormalTok("(m_vals), ");#DecValTok("1");#NormalTok("),]) ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("      tibble");#SpecialCharTok("::");#FunctionTok("rownames_to_column");#NormalTok("(");#AttributeTok("var =");#NormalTok(" ");#StringTok("\"geo_accession\"");#NormalTok(" ) ");],
[],
[#CommentTok("# Organizing the data into a format suitable for single model ");],
[#CommentTok("# fit. ");],
[#NormalTok("dat ");#OtherTok("<-");#NormalTok(" metadata ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("      dplyr");#SpecialCharTok("::");#FunctionTok("select");#NormalTok("(geo_accession, participant, time) ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("      ");#FunctionTok("inner_join");#NormalTok("(y) ");#SpecialCharTok("|>");],
[#NormalTok("      ");#CommentTok("# Permutation of time within participant");],
[#NormalTok("      ");#FunctionTok("group_by");#NormalTok("(participant) ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("      ");#FunctionTok("mutate");#NormalTok("(");#AttributeTok("time_permute =");#NormalTok(" ");#FunctionTok("sample");#NormalTok("(time, ");#AttributeTok("replace =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(")) ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("      ");#FunctionTok("ungroup");#NormalTok("() ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("      ");#FunctionTok("mutate");#NormalTok("(");#AttributeTok("msim =");#NormalTok(" ");#FunctionTok("if_else");#NormalTok("(time_permute ");#SpecialCharTok("==");#NormalTok(" ");#StringTok("\"3_loading\"");#NormalTok(", ");],
[#NormalTok("             y ");#SpecialCharTok("+");#NormalTok(" ");#FloatTok("0.3");#NormalTok(", y), ");],
[#NormalTok("             ");#AttributeTok("betasim =");#NormalTok(" ");#FunctionTok("plogis");#NormalTok("(msim ");#SpecialCharTok("*");#NormalTok(" ");#FunctionTok("log");#NormalTok("(");#DecValTok("2");#NormalTok("))) ");],));
#block[
#Skylighting(([#NormalTok("Joining with `by = join_by(geo_accession)`");],));
]
#Skylighting(([#CommentTok("# A general purpose summary function for ML/REML fits.");],
[#CommentTok("#");],
[#CommentTok("# This function is similar to the `summary_fun` in");],
[#CommentTok("# analysis/R/methylation-error-permutation.R). ");],
[#NormalTok("temp_summary_fun ");#OtherTok("<-");#NormalTok(" ");#ControlFlowTok("function");#NormalTok("(m) {");],
[],
[#NormalTok("      ");#CommentTok("# Wald p-value (restricted to paremeter 3_loading)");],
[#NormalTok("      wald_p ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("coef");#NormalTok("(");#FunctionTok("summary");#NormalTok("(m))");#SpecialCharTok("$");#NormalTok("cond[");#StringTok("\"time_permute3_loading\"");#NormalTok(", ");#StringTok("\"Pr(>|z|)\"");#NormalTok("]");],
[#NormalTok("      ");#CommentTok("# Wald p-value Satterthwaite");],
[#NormalTok("      wald_p_satter ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("coef");#NormalTok("(");#FunctionTok("summary");#NormalTok("(m, ");#AttributeTok("ddf =");#NormalTok(" ");#StringTok("\"satterthwaite\"");#NormalTok("))");#SpecialCharTok("$");#NormalTok("cond[");#StringTok("\"time_permute3_loading\"");#NormalTok(", ");#StringTok("\"Pr(>|t|)\"");#NormalTok("]");],
[],
[#NormalTok("      ");#FunctionTok("data.frame");#NormalTok("(");#AttributeTok("wald_p =");#NormalTok(" wald_p,");],
[#NormalTok("                 ");#AttributeTok("wald_p_satter =");#NormalTok(" wald_p_satter)");],
[],
[#NormalTok("}");],
[],
[],
[#CommentTok("# Storing fits in a list ");],
[#NormalTok("fits ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("list");#NormalTok("()");],
[],
[#CommentTok("# Maximum likelihood M-values");],
[#NormalTok("fits[[");#DecValTok("1");#NormalTok("]] ");#OtherTok("<-");#NormalTok(" glmmTMB");#SpecialCharTok("::");#FunctionTok("glmmTMB");#NormalTok("(msim ");#SpecialCharTok("~");#NormalTok(" time_permute ");#SpecialCharTok("+");#NormalTok(" (");#DecValTok("1");#SpecialCharTok("|");#NormalTok("participant), ");],
[#NormalTok("                          ");#AttributeTok("data =");#NormalTok(" dat)");],
[],
[],
[#CommentTok("# Maximum likelihood beta regression");],
[#NormalTok("fits[[");#DecValTok("2");#NormalTok("]] ");#OtherTok("<-");#NormalTok(" glmmTMB");#SpecialCharTok("::");#FunctionTok("glmmTMB");#NormalTok("(betasim ");#SpecialCharTok("~");#NormalTok(" time_permute ");#SpecialCharTok("+");#NormalTok(" (");#DecValTok("1");#SpecialCharTok("|");#NormalTok("participant), ");],
[#NormalTok("                          ");#AttributeTok("data =");#NormalTok(" dat, ");],
[#NormalTok("                          ");#AttributeTok("family =");#NormalTok(" glmmTMB");#SpecialCharTok("::");#NormalTok("beta_family)");],
[],
[#CommentTok("# REML M-values");],
[#NormalTok("fits[[");#DecValTok("3");#NormalTok("]]");#OtherTok("<-");#NormalTok(" glmmTMB");#SpecialCharTok("::");#FunctionTok("glmmTMB");#NormalTok("(msim ");#SpecialCharTok("~");#NormalTok(" time_permute ");#SpecialCharTok("+");#NormalTok(" (");#DecValTok("1");#SpecialCharTok("|");#NormalTok("participant), ");],
[#NormalTok("                           ");#AttributeTok("REML =");#NormalTok(" ");#ConstantTok("TRUE");#NormalTok(",");],
[#NormalTok("                          ");#AttributeTok("data =");#NormalTok(" dat)");],
[],
[#CommentTok("# REML beta regression");],
[#NormalTok("fits[[");#DecValTok("4");#NormalTok("]] ");#OtherTok("<-");#NormalTok(" glmmTMB");#SpecialCharTok("::");#FunctionTok("glmmTMB");#NormalTok("(betasim ");#SpecialCharTok("~");#NormalTok(" time_permute ");#SpecialCharTok("+");#NormalTok(" (");#DecValTok("1");#SpecialCharTok("|");#NormalTok("participant), ");],
[#NormalTok("                          ");#AttributeTok("data =");#NormalTok(" dat, ");],
[#NormalTok("                          ");#AttributeTok("REML =");#NormalTok(" ");#ConstantTok("TRUE");#NormalTok(",");],
[#NormalTok("                          ");#AttributeTok("family =");#NormalTok(" glmmTMB");#SpecialCharTok("::");#NormalTok("beta_family)");],
[],
[],
[],
[#NormalTok("out ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("lapply");#NormalTok("(fits,temp_summary_fun) ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("      ");#FunctionTok("bind_rows");#NormalTok("() ");#SpecialCharTok("|>");#NormalTok(" ");],
[#NormalTok("      ");#FunctionTok("mutate");#NormalTok("(");#AttributeTok("model =");#NormalTok(" ");#FunctionTok("c");#NormalTok("(");#StringTok("\"M-values\"");#NormalTok(",");],
[#NormalTok("                       ");#StringTok("\"B-values\"");#NormalTok(",");],
[#NormalTok("                       ");#StringTok("\"M-values\"");#NormalTok(",");],
[#NormalTok("                       ");#StringTok("\"B-values\"");#NormalTok("), ");],
[#NormalTok("             ");#AttributeTok("estimator =");#NormalTok(" ");#FunctionTok("c");#NormalTok("(");#StringTok("\"ML\"");#NormalTok(", ");#StringTok("\"ML\"");#NormalTok(", ");#StringTok("\"REML\"");#NormalTok(", ");#StringTok("\"REML\"");#NormalTok("))");],));
]
#figure([
#{set text(font: ("Segoe UI", "Arial", "Segoe UI Emoji", "Segoe UI Symbol") , size: 12pt);table(
  columns: (25%, 25%, 25%, 25%),
  align: (left,left,right,right,),
  table.header(table.cell(align: bottom + left, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    Model], table.cell(align: bottom + left, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    Estimator], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    Wald z/t-test], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    Wald t-test w.Satterthwaite DDF],),
  table.hline(),
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[M-values], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[ML], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.0003546736], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.001233616],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[B-values], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[ML], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.0004632532], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.001490941],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[M-values], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[REML], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.0008788749], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.002648474],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[B-values], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[REML], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.0010989003], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[0.003044312],
)}
], caption: figure.caption(
position: top, 
[
P-values from a set of model specifications for a specific CpG site
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-prel-results-meth>


#block[
#Skylighting(([#CommentTok("# Illustrating the ");],
[#NormalTok("es_mmod ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("coef");#NormalTok("(");#FunctionTok("summary");#NormalTok("(fits[[");#DecValTok("3");#NormalTok("]]))");#SpecialCharTok("$");#NormalTok("cond[");#StringTok("\"time_permute3_loading\"");#NormalTok(",");#StringTok("\"Estimate\"");#NormalTok("]");],
[#NormalTok("es_betamod");#OtherTok("<-");#NormalTok(" ");#FunctionTok("coef");#NormalTok("(");#FunctionTok("summary");#NormalTok("(fits[[");#DecValTok("4");#NormalTok("]]))");#SpecialCharTok("$");#NormalTok("cond[");#StringTok("\"time_permute3_loading\"");#NormalTok(",");#StringTok("\"Estimate\"");#NormalTok("]");],
[],
[#NormalTok("es_betamod ");#OtherTok("<-");#NormalTok(" es_betamod ");#SpecialCharTok("/");#NormalTok(" ");#FunctionTok("log");#NormalTok("(");#DecValTok("2");#NormalTok(")");],));
]
The different model specifications produces different p-values (#ref(<tbl-prel-results-meth>, supplement: [Table])), although, we will need the full permutation experiment to determine any systematic differences. The transformation of the estimates follow the same logic as the transformation of the raw data. The estimated effects (0.27 and 0.27) for the model on M-values and β values respectively are comparable but will differ due to compression in the β values model.

The source code for the full permutation experiment can be found in the script #NormalTok("analysis/R/methylation-error-permutation.R"); in the #link("https://github.com/trainome/seqwrappaper")[project repository].

= Simulation results from the RNA-seq analysis
<simulation-results-from-the-rna-seq-analysis>
Below follows supplementary results from the simulation study presented in the main text.

#figure([
#box(image("supplement_files/figure-typst/fig-genecounts-simulated-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Number of simulated gene targets (true negative and true positives) across dispersion scenarios and sample sizes.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-genecounts-simulated>


#figure([
#box(image("supplement_files/figure-typst/fig-convergence-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Number of models that provided estimates as a percentage of all potential targets. In (A), a strict criteria was used for convergence for the Gaussian model of transformed counts where models with singular fits where excluded as suggested by Vestal et al.~(2022). In (B) all converged models are included.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-convergence>


#figure([
#box(image("supplement_files/figure-typst/fig-pdist-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Distribution of unadjusted p-values from all null-effects in models of simulated data. Non-uniform distributions indicate mis-specified models, i.e.~models that do not capture variation in the data. Models are the negative binomial (NB), regularized negative binomial (NB-R), the Gaussian model of transformed counts (Gaussian), the Poisson observation-level random effect model (POLRE) and the regularized Poisson observation-level random effect model (POLRE-R).
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-pdist>


#figure([
#box(image("supplement_files/figure-typst/fig-cor-sim-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Average correlations between simulated population effects and estimates as a function of sample size in two parameters (Main and interaction effects) and two dispersion scenarios.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-cor-sim>


= Supplementary tables
<supplementary-tables>
#figure([
#{set text(font: ("Segoe UI", "Arial", "Segoe UI Emoji", "Segoe UI Symbol") , size: 7.5pt);table(
  columns: 5,
  align: (left,left,left,left,left,),
  table.header(table.cell(align: bottom + left, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    Gene ontology ID], table.cell(align: bottom + left, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    Description], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    Set size], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    NES], table.cell(align: bottom + right, fill: rgb("#ffffff"))[#set text(size: 1.0em , weight: "regular" , fill: rgb("#333333"));
    FDR],),
  table.hline(),
  table.cell(align: horizon + left, colspan: 5, fill: rgb("#ffffff"), stroke: (bottom: (paint: rgb("#d3d3d3"), thickness: 1.5pt), top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[#set text(size: 1.0em , fill: rgb("#333333"));
  Negative binomial (non-informed)],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[GO:0030199], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[Collagen Fibril Organization], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[60], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[2.51], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[3.97~×~10#super[−9]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[GO:0045229], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[External Encapsulating Structure Organization], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[212], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.37], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[3.97~×~10#super[−9]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[GO:0006119], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Oxidative Phosphorylation], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[114], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[-3.39], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[3.97~×~10#super[−9]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[GO:0019646], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Aerobic Electron Transport Chain], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[72], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[-3.38], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[3.97~×~10#super[−9]],
  table.cell(align: horizon + left, colspan: 5, fill: rgb("#ffffff"), stroke: (bottom: (paint: rgb("#d3d3d3"), thickness: 1.5pt), top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[#set text(size: 1.0em , fill: rgb("#333333"));
  Regularized Negative binomial],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[GO:0030199], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[Collagen Fibril Organization], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[60], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[2.57], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[2.91~×~10#super[−9]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[GO:0043299], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Leukocyte Degranulation], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[56], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.54], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.91~×~10#super[−9]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[GO:0006119], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Oxidative Phosphorylation], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[114], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[-3.98], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.91~×~10#super[−9]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[GO:0019646], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Aerobic Electron Transport Chain], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[72], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[-3.97], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.91~×~10#super[−9]],
  table.cell(align: horizon + left, colspan: 5, fill: rgb("#ffffff"), stroke: (bottom: (paint: rgb("#d3d3d3"), thickness: 1.5pt), top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[#set text(size: 1.0em , fill: rgb("#333333"));
  Gaussian transformed counts],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[GO:0045229], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[External Encapsulating Structure Organization], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[192], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[3.07], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[2.17~×~10#super[−9]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[GO:0030198], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Extracellular Matrix Organization], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[191], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[3.00], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.17~×~10#super[−9]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[GO:0043062], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Extracellular Structure Organization], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[191], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[3.00], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.17~×~10#super[−9]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[GO:0006119], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Oxidative Phosphorylation], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[112], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[-3.35], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.17~×~10#super[−9]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[GO:0019646], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Aerobic Electron Transport Chain], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[71], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[-3.34], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.17~×~10#super[−9]],
  table.cell(align: horizon + left, colspan: 5, fill: rgb("#ffffff"), stroke: (bottom: (paint: rgb("#d3d3d3"), thickness: 1.5pt), top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[#set text(size: 1.0em , fill: rgb("#333333"));
  Poisson OLRE (non-informed)],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[GO:0045229], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[External Encapsulating Structure Organization], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[212], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[2.62], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[2.84~×~10#super[−9]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[GO:0030198], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Extracellular Matrix Organization], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[211], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.61], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.84~×~10#super[−9]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[GO:0043062], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Extracellular Structure Organization], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[211], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.61], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.84~×~10#super[−9]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[GO:0019646], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Aerobic Electron Transport Chain], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[72], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[-3.30], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.84~×~10#super[−9]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[GO:0030239], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Myofibril Assembly], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[63], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[-3.29], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.84~×~10#super[−9]],
  table.cell(align: horizon + left, colspan: 5, fill: rgb("#ffffff"), stroke: (bottom: (paint: rgb("#d3d3d3"), thickness: 1.5pt), top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[#set text(size: 1.0em , fill: rgb("#333333"));
  Regularized Poisson OLRE],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[GO:0045229], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[External Encapsulating Structure Organization], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[212], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[2.85], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 1.5pt)))[2.19~×~10#super[−9]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[GO:0030198], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Extracellular Matrix Organization], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[211], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.82], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.19~×~10#super[−9]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[GO:0043062], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Extracellular Structure Organization], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[211], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.82], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.19~×~10#super[−9]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[GO:0006119], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Oxidative Phosphorylation], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[114], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[-3.72], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.19~×~10#super[−9]],
  table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[GO:0019646], table.cell(align: horizon + left, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[Aerobic Electron Transport Chain], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[72], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[-3.69], table.cell(align: horizon + right, stroke: (top: (paint: rgb("#d3d3d3"), thickness: 0.75pt)))[2.19~×~10#super[−9]],
)}
], caption: figure.caption(
position: top, 
[
Gene set enrichment analysis of fold-changes in all models. For each model the top (and bottom) ranked gene sets were selected based on -log#sub[10]\(FDR) × NES. The sign of the normalized effect size (NES) indicate enrichment at top (positive fold-change in T2D vs.~control) and bottom (negative fold change) ranked genes.
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-gsea>


= Comparing elapsed time
<comparing-elapsed-time>
Choosing the most appropriate modeling strategy for high-dimensional data can entail a high computational cost. #NormalTok("seqwrap()"); records the elapsed time for fitting a set of models. This estimate can assist in selecting modeling strategies. To retrieve the elapsed time:

#block[
#Skylighting(([#CommentTok("# Example of elapsed time using different modeling strategies. ");],
[#FunctionTok("library");#NormalTok("(seqwrap)");],
[],
[#FunctionTok("set.seed");#NormalTok("(");#DecValTok("1");#NormalTok(") ");],
[#NormalTok("dat ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("simcounts");#NormalTok("(");#AttributeTok("n_genes =");#NormalTok(" ");#DecValTok("100");#NormalTok(")");],
[],
[#CommentTok("# Store data sets");],
[#NormalTok("d ");#OtherTok("<-");#NormalTok(" dat");#SpecialCharTok("$");#NormalTok("data");],
[#NormalTok("md ");#OtherTok("<-");#NormalTok(" dat");#SpecialCharTok("$");#NormalTok("metadata");],
[],
[],
[#NormalTok("mod1 ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap_compose");#NormalTok("(");#AttributeTok("data =");#NormalTok(" d, ");],
[#NormalTok("                ");#AttributeTok("metadata =");#NormalTok(" md, ");],
[#NormalTok("                ");#AttributeTok("modelfun =");#NormalTok(" stats");#SpecialCharTok("::");#NormalTok("lm, ");],
[#NormalTok("                ");#AttributeTok("arguments =");#NormalTok(" ");#FunctionTok("list");#NormalTok("(");#AttributeTok("formula =");#NormalTok(" y ");#SpecialCharTok("~");#NormalTok(" x), ");],
[#NormalTok("                ");#AttributeTok("samplename =");#NormalTok(" ");#StringTok("\"sample\"");#NormalTok(")");],
[],
[#NormalTok("mod2 ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap_compose");#NormalTok("(");#AttributeTok("data =");#NormalTok(" d, ");],
[#NormalTok("                ");#AttributeTok("metadata =");#NormalTok(" md, ");],
[#NormalTok("                ");#AttributeTok("modelfun =");#NormalTok(" lme4");#SpecialCharTok("::");#NormalTok("lmer, ");],
[#NormalTok("                ");#AttributeTok("arguments =");#NormalTok(" ");#FunctionTok("list");#NormalTok("(");#AttributeTok("formula =");#NormalTok(" y ");#SpecialCharTok("~");#NormalTok(" x ");#SpecialCharTok("+");#NormalTok(" (");#DecValTok("1");#SpecialCharTok("|");#NormalTok("cluster)), ");],
[#NormalTok("                ");#AttributeTok("samplename =");#NormalTok(" ");#StringTok("\"sample\"");#NormalTok(")");],
[],
[#NormalTok("mod3 ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap_compose");#NormalTok("(");#AttributeTok("data =");#NormalTok(" d, ");],
[#NormalTok("                ");#AttributeTok("metadata =");#NormalTok(" md, ");],
[#NormalTok("                ");#AttributeTok("modelfun =");#NormalTok(" glmmTMB");#SpecialCharTok("::");#NormalTok("glmmTMB, ");],
[#NormalTok("                ");#AttributeTok("arguments =");#NormalTok(" ");#FunctionTok("list");#NormalTok("(");#AttributeTok("formula =");#NormalTok(" y ");#SpecialCharTok("~");#NormalTok(" x ");#SpecialCharTok("+");#NormalTok(" (");#DecValTok("1");#SpecialCharTok("|");#NormalTok("cluster)), ");],
[#NormalTok("                ");#AttributeTok("samplename =");#NormalTok(" ");#StringTok("\"sample\"");#NormalTok(")");],
[],
[#NormalTok("results1 ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap");#NormalTok("(mod1, ");#AttributeTok("verbose =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(")");],
[#NormalTok("results2 ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap");#NormalTok("(mod2, ");#AttributeTok("verbose =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(")");],
[#NormalTok("results3 ");#OtherTok("<-");#NormalTok(" ");#FunctionTok("seqwrap");#NormalTok("(mod3, ");#AttributeTok("verbose =");#NormalTok(" ");#ConstantTok("FALSE");#NormalTok(")");],
[],
[#NormalTok("results1");#SpecialCharTok("@");#NormalTok("elapsed_time");],));
#block[
#Skylighting(([#NormalTok("   user  system elapsed ");],
[#NormalTok("   0.01    0.00    1.78 ");],));
]
#Skylighting(([#NormalTok("results2");#SpecialCharTok("@");#NormalTok("elapsed_time");],));
#block[
#Skylighting(([#NormalTok("   user  system elapsed ");],
[#NormalTok("   0.02    0.02    3.99 ");],));
]
#Skylighting(([#NormalTok("results3");#SpecialCharTok("@");#NormalTok("elapsed_time");],));
#block[
#Skylighting(([#NormalTok("   user  system elapsed ");],
[#NormalTok("   0.01    0.02    7.75 ");],));
]
]
Below, we are comparing three different algorithms, #NormalTok("lme4::glmer.nb()");, #NormalTok("glmmTMB()"); and #NormalTok("glmmTMB()"); using a non-default optimizer. Using a subset gives indications on which algorithm is the fastest (#ref(<fig-timing>, supplement: [Figure S])). Differnt modeling packages are expected to have different computational costs depending on the model definition and the data @brooks_glmmtmb_nodate. Options within packages can also influence elapsed times, see e.g., the #link("https://cran.r-project.org/web/packages/lme4/vignettes/lmerperf.html")[lme4 performance tips] vignette.

#figure([
#box(image("supplement_files/figure-typst/fig-timing-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Comparing elapsed time between three different algorithms using the same basic model (negative binomial on simulate count data with 8 clusters and 2 observations each).
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-timing>





#set bibliography(style: "resources/bmc-biology.csl")

#bibliography(("resources/bibliography.bib"))

