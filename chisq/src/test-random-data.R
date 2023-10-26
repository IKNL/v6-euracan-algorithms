set.seed(123L)
Data <- data.frame("X" = sample(6:25, size = 1000, replace = T),
                   "Y" = sample(c(6:20, NA), size= 1000, replace = T),
                   "Z" = sample(c(6:19, NA), size= 1000, replace = T))

d1 <- Data[(1:floor(nrow(Data) / 3)), ]
d2 <- Data[(floor(nrow(Data) / 3)+1: floor(nrow(Data) / 3) * 2),]
d3 <- Data[((floor(nrow(Data) / 3) * 2) +1) : nrow(Data) ,]
datasets <- list(d1, d2, d3)

data <- na.omit(rbind(d1, d2, d3))
col = c("X", "Y", "Z")

Rchisq <- chisq.test(data)

threshold = 1L
probs=NULL



chisq.mock <- function(dataset,col, threshold, probs){
    client=vtg::MockClient$new(datasets = datasets, pkgname = 'vtg.chisq')
    result=vtg.chisq::dchisq(client = client,
                             col=col,
                             threshold=threshold,
                             probs=probs)
    return(result)
}

res <- chisq.mock(dataset = datasets,
                  col=col,
                  threshold=threshold,
                  probs=probs)

res$statistic == Rchisq$statistic
res$parameter == Rchisq$parameter
res$pval == Rchisq$p.value