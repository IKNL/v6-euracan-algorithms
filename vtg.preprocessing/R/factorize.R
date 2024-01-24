#' Convert character variables to factors
#'
#' @param data data.frame
#'
#' @return data.frame
#'
#' @export
factorize <- function(data) {
  return(dplyr::mutate_if(data, is.character, as.factor))
}