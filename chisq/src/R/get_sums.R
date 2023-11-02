#' @export
#'
get_sums <- function(data, col) {

  data <- na.omit(data[, col])

  if (length(unique(col)) != length(col)){
    vtg::log$critical("You have repeated column names...")
    stop("You have repeated column names...")
  }

  if (is.data.frame(data)) {
    vtg::log$info("Running chisq.test on dataframe...")
    data <- as.matrix(data)
    n <- sum(data)
    nr <- nrow(data)
    nc <- ncol(data)
    sr <- rowSums(data)
    sc <- colSums(data)

  } else {
    vtg::log$info("Running chisq.test on single column...")
    n <- sum(data)
    nr <- NULL
    nc <- NULL
    sr <- NULL
    sc <- NULL
  }
  return(list("n" = n, "nr" = nr, "nc" = nc, "sr" = sr, "sc" = sc))
}
