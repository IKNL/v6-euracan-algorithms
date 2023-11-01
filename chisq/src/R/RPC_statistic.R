#' @export
#'
RPC_statistic <- function(data, col, E, data.class){

    data <- na.omit(data)
    columns.in.data <- which(colnames(data) %in% col)
    # access correct rows & column...
    if(data.class == "DF"){
        local.E <- E[dimnames(E)[[1]] %in% data$id, columns.in.data]
        return(sum(
            abs(
                data[,columns.in.data] - local.E
            )^2 / local.E
        ))
    }else if(data.class == "X_y_case"){
        data <- table(data[,columns.in.data])
        local.E <- E[dimnames(E)[[1]] %in% dimnames(data)[[1]],
                     dimnames(E)[[2]] %in% dimnames(data)[[2]]]
        # local.E <- E[dimnames(data)[[1]], dimnames(data)[[2]]]
        return(sum(
            abs(
                data - local.E
            ) ^ 2 / local.E
        ))

    }else{
        data <- as.vector(data[, columns.in.data])
        local.E <- E[length(data)]
        return(sum(
            abs(
                data - local.E
            ) ^ 2 / local.E
        ))
    }
}
