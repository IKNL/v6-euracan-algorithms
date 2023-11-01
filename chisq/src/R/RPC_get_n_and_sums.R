#' @export
#'
RPC_get_n_and_sums <- function(data, col, threshold = 5L)
{
    n <- vtg.chisq::get_n(data, col, threshold = threshold)
    sums <- vtg.chisq::get_sums(data, col)
    return(list("n" = n, "sums" = sums))
}
