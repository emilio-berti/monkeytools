#' @title Draw causal graph (DAG)
#'
#' @param d data.frame, with columns 'from' and 'to'.
#'
#' @details An arrow is drawn between column 'from' and 'to', indicating
#' the potential causal relationship among variables.
#'
#' @return nothing.
#'
#' @examples
#' \donttest{
#' d <- data.frame(
#'  from = c("Rain", "Sun", "Latitude", "Latitude"),
#'  to = c("Mental health", "Mental health", "Rain", "Sun")
#' )
#' draw_dag(d)
#' }
draw_dag <- function(d) {
  d$from <- gsub(" ", "_", d$from)
  d$to <- gsub(" ", "_", d$to)
  # redirect sink to temporary file
  tmp <- tempfile()
  sink(tmp)
  g <- '
    cat("digraph {\n graph []\n node [shape = plaintext]\n edge []\n")
    for (i in seq_len(nrow(d))) cat(d$from[i], "->", d$to[i], "\n")
    cat("}\n")
  '
  eval(parse(text = g)) #write to tempfile
  sink() #restore default sink
  dag <- paste0(readLines(tmp), collapse = "\n")
  DiagrammeR::grViz(dag)
}
