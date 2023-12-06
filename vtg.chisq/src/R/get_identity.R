#'
#' @export
#'
get_identity <- function() {
  # Read the contents of file input.txt into 'input_data'
  token_file <- Sys.getenv("TOKEN_FILE", unset = NA)
  if (is.na(token_file)) {
    vtg::log$warn("TOKEN_FILE environment variable not set. Are you mocking?")
    return(list(
      node_id = "mock_node",
      organization_id = "mock_organization"
    ))
  }

  vtg::log$debug(glue::glue("Loading token from '{token_file}'"))
  token <- readChar(token_file, file.info(token_file)$size)

  strings <- unlist(strsplit(token, ".", fixed=TRUE))
  JSON <- rawToChar(base64enc::base64decode(strings[2]))

  jwt_token <- rjson::fromJSON(JSON)
  if("sub" %in% names(jwt_token)) {
    identity <- jwt_token$sub
  } else if ("identity" %in% names(jwt_token)) {
    identity <- jwt_token$identity
  } else {
    vtg::log$error("Could not find 'sub' or 'identity' in token.")
    return(-1L)
  }
  vtg::log$debug("Identity is '{identity}'")
  return(identity)
}