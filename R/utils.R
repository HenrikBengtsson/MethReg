#' Create Granges from name
#' @description Given a region name such as chr22:18267969-18268249, we will create a Granges
#' object
#' @importFrom tidyr separate
#' @importFrom GenomicRanges makeGRangesFromDataFrame
#' @param names A region name as "chr22:18267969-18268249" or a vector of region names.
#' @examples
#' regions.names <- c("chr22:18267969-18268249","chr23:18267969-18268249")
#' regions.gr <- make_granges_from_names(regions.names)
#' @export
make_granges_from_names <- function(names){
    names %>%
        data.frame %>%
        separate(col = ".",into = c("chr","start","end")) %>%
        makeGRangesFromDataFrame()
}


#' Create region name from Granges
#' @description Given a GRanges returns region name such as chr22:18267969-18268249
#' @importFrom stringr str_c
#' @importFrom dplyr %>%
#' @examples
#' regions.names <- c("chr22:18267969-18268249","chr23:18267969-18268249")
#' regions.gr <- make_granges_from_names(regions.names)
#' make_names_from_granges(regions.gr)
#' @noRd
make_names_from_granges <- function(region){
    str_c(
        region %>% seqnames %>% as.character,":",
        region %>% start %>% as.character,"-",
        region %>% end %>% as.character)
}


#' Change probes names to region names
#' @description Given a DNA methylation matrix with probes as row names,
#' map probes to genomic regions
#' @param dnam A DNA methylation matrix
#' @param genome Human genome of reference hg38 or hg19
#' @param arrayType DNA methylation array type (450k or EPIC)
#' @examples
#' data(dna.met.chr21)
#' dna.met.chr21.with.region.name <- map_probes_to_regions(dna.met.chr21)
#' @export
map_probes_to_regions <- function(dnam,
                                  genome = c("hg38","hg19"),
                                  arrayType = c("450k","EPIC")
){
    genome <- match.arg(genome)
    arrayType <- match.arg(arrayType)

    probe.info <- sesameDataGet(
        str_c(ifelse(arrayType == "450k","HM450","EPIC"),".",
              genome,".manifest")
    )
    rownames(dnam) <- make_names_from_granges(probe.info[rownames(dnam)])
    return(dnam)
}


#' @param genome Human genome of reference. Options: hg38, hg19.
#' @param ensembl.gene.id Gene ensembl ID. A character vectors
#' @description Given a GRanges returns region name such as chr22:18267969-18268249
#' @examples
#' data(gene.exp.chr21)
#' gene.symbols <- map_ensg_to_symbol(rownames(gene.exp.chr21))
#' @noRd
#' @importFrom biomaRt useEnsembl listDatasets getBM
map_ensg_to_symbol <- function(ensembl.gene.id, genome = "hg38")
{
    gene.location <- get_gene_information(genome)
    symbols <- gene.location[match(ensembl.gene.id,gene.location$ensembl_gene_id),]$external_gene_name
    return(symbols)
}

#' @param genome Human genome of reference. Options: hg38, hg19.
#' @param ensembl.gene.id Gene ensembl ID. A character vectors
#' @description Given a GRanges returns region name such as chr22:18267969-18268249
#' @examples
#' gene.symbols <- map_symbol_to_ensg("TP63"s)
#' @noRd
#' @importFrom biomaRt useEnsembl listDatasets getBM
map_symbol_to_ensg <- function(gene.symbol, genome = "hg38")
{
    gene.location <- get_gene_information(genome)
    ensembl_gene_id <- gene.location[match(gene.symbol,gene.location$external_gene_name),]$ensembl_gene_id
    return(ensembl_gene_id)
}

get_gene_information <- function(genome = "hg38"){
    tries <- 0L
    msg <- character()
    while (tries < 3L) {
        gene.location <- tryCatch({
            host <- ifelse(genome == "hg19", "grch37.ensembl.org",
                           "www.ensembl.org")
            mirror <- list(NULL, "useast", "uswest", "asia")[[tries +
                                                                  1]]
            ensembl <- tryCatch({
                message(ifelse(is.null(mirror),
                               paste0("Accessing ",
                                      host, " to get gene information"),
                               paste0("Accessing ",
                                      host, " (mirror ", mirror, ")")))
                useEnsembl("ensembl", dataset = "hsapiens_gene_ensembl",
                           host = host, mirror = mirror)
            }, error = function(e) {
                message(e)
                return(NULL)
            })
            attributes <- c("ensembl_gene_id","external_gene_name")
            db.datasets <- listDatasets(ensembl)
            description <- db.datasets[db.datasets$dataset == "hsapiens_gene_ensembl", ]$description
            message(paste0("Downloading genome information (try:", tries, ") Using: ", description))
            gene.location <- getBM(attributes = attributes,
                                   #filters = c("ensembl_gene_id"),
                                   #values = list(ensembl.gene.id),
                                   mart = ensembl)
            gene.location
        }, error = function(e) {
            msg <<- conditionMessage(e)
            tries <<- tries + 1L
            NULL
        })
        if (!is.null(gene.location))
            break
        if (tries == 3L) stop("failed to get URL after 3 tries:", "\n  error: ", msg)
    }
    return(gene.location)
}


check_data <- function(dnam, exp, metadata){
    if(ncol(dnam) != ncol(exp)){
        stop("DNA methylation and gene expression do not has the same number of samples")
    }

    if(!all(colnames(dnam) == colnames(exp))){
        stop("DNA methylation and gene expression do not has the column names")
    }

    if(!missing(metadata)){

        if(nrow(metadata) != ncol(exp)){
            stop("Metadata and data do not has the same number of samples")
        }

        if(all(rownames(metadata) != colnames(exp))){
            stop("Metadata and data do not has the same number of samples")
        }
    }

}