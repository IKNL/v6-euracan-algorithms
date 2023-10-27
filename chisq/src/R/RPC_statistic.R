#' @export
#'
RPC_statistic <- function(data, col, E){

    data <- na.omit(data[,col])
    # access correct rows & column...
    local.E <- E[dimnames(E)[[1]] %in% dimnames(data)[[1]],
                 dimnames(E)[[2]] %in% dimnames(data)[[2]]]
    return(sum((abs(data - local.E))^2/local.E))
}

data

test1 <- na.omit(d1[,col])
test2 <- na.omit(d2[,col])
test3 <- na.omit(d3[,col])

# dimnames of data are not correct -> order data... -> identify which values belong to cluster i
E.glob[dimnames(E.glob)[[1]] %in% dimnames(test3)[[1]],]

x <- data.frame(sample(c(1:10), 10, replace = T), row.names = NULL)
x[,2] <- c(1:nrow(x))

x[which(x[,2] == 4),]
