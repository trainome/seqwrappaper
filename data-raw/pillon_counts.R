# Build data/pillon_counts.rda from GEO accession GSE202295
#
# Pillon NJ, Smith JAB, Alm PS, Chibalin AV et al. (2022). Distinctive
# exercise-induced inflammatory response and exerkine induction in skeletal
# muscle of people with type 2 diabetes. Sci Adv 8(36):eabo3192.
#

brary(GEOquery)

# Get the gene counts
counts <- getRNASeqData("GSE202295")

# Sort row annotations and convert to symbols
annotation <- SummarizedExperiment::rowData(counts) |>
  darame() |>
  dplyr:ect(GeneID, Symbol) |>
  dplyr::mutGeneID = as.character(GeneID)) |>
  data.frame(rowes = NULL)

# Get the count matrix and add symbols
counts_mat <- counts@assays@data@listData$counts

countdata <- counts_mat |>
  data.frame() |>
  le::rownames_to_co("GeneID") |>
  dplyr::inner_join(annotati|>
  dplyr::select(geneid = Symbol,yselect::starts_with("GSM"))

# Remove all zero row counts
countdata <- countdata[rowSums(countdata[, -1]) != 0, ]


# Sort meta data
metadata <- counts@colData |>
  data.frame() |>
  dplyr::select(semple_id = geo_accen, group_id_time = title) |>
  tidyr::separate(group_id_time, into = c("g", "id", "time")) |>
  dplyr::mutate(time = factor(time, levels = c("l", "post", "rec"))) |>
  data.frame(row.names = NULL)


# Save the data as file
pillon_counts <- list(metadata = metadata, countdata = countdata)

usethis::use_data(pillon_counts, compress = "xz", overwrite = TRUE)
