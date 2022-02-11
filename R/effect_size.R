#' @title Sample superiority effect size
#'
#' @param x numeric vector, first sample.
#' @param y numeric vector, second sample.
superiority <- function(x, y){
  if (any(is.na(x)) | any(is.na(y))) {
    nas <- unique(c(which(is.na(x)), which(is.na(y))))
    x <- x[-nas]
    y <- y[-nas]
  }
  # all favorable pairs
  P <- sum(sapply(x, function(x) sum(x > y)))
  # all unfavorable pairs
  N <- sum(sapply(x, function(x) sum(x < y)))
  # all ties
  E <- sum(sapply(x, function(x) sum(x == y)))
  # total
  Tot <- P + N + E
  # rank biserial correlation
  r <- (P - N) / (Tot)
  # sample superiority
  prob <- P / Tot
  return(list(
    fav.pairs = P,
    tot.pairs = Tot,
    ties = E,
    rank.corr = r,
    P = prob)
  )
}

#' @title Interpret effect size
#'
#' @param x numeric, an effect size measure.
#' @param method string, how to interpret x, default as Cohen's d.
magnitude <- function(x, method = "Cohen"){
  if (method == "Cohen") {
    ans <- cut(x,
        breaks = c(0, .2, .5, .8, 1.2, 2.0, Inf),
        labels = c("No difference",
                   "Small",
                   "Medium",
                   "Large",
                   "Very Large",
                   "Huge"),
        right = FALSE)
  }
  else if (method == "superiority") {
    ans <- cut(x,
               breaks = c(0, .56, .64, .71, .80, .92, 1.1),
               labels = c("No difference",
                          "Small",
                          "Medium",
                          "Large",
                          "Very Large",
                          "Huge"),
               right = FALSE)
  } else {
    stop("Specified method not valid. Options: 'Cohen', 'superiority'")
  }
  return(ans)
}

#' @title Cohen's d effect size
#'
#' @param x numeric vector, first sample.
#' @param y numeric vector, second sample.
cohen <- function(x, y) {
  if (any(is.na(x))) {
    nas <- which(is.na(x))
    x <- x[-nas]
  }
  if (any(is.na(y))) {
    nas <- which(is.na(y))
    y <- y[-nas]
  }
  ans <- (mean(x) - mean(y)) / pooled(x, y)
  if (ans < 0) {
    message("Mean(x) < Mean(y) - taking the opposite of effect size")
    ans <- -ans
  }
  return(ans)
}
#' @title Pooled standard deviation
#'
#' @param x numeric, first sample.
#' @param y numeric, second sample.
pooled <- function(x, y) {
  if (any(is.na(x))) {
    nas <- which(is.na(x))
    x <- x[-nas]
  }
  if (any(is.na(y))) {
    nas <- which(is.na(y))
    y <- y[-nas]
  }
  n.x <- length(x)
  n.y <- length(y)
  var.x <- stats::var(x)
  var.y <- stats::var(y)
  ans <- ((n.x - 1) * var.x + (n.y - 1) * var.y) / (n.x + n.y + 2)
  ans <- sqrt(ans)
  return(ans)
}
