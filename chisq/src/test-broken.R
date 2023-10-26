rm(list = ls(all.names = TRUE))


library(vtg)
library(vtg.chisq)

# Generate some sample data
# set.seed(123L);

# Data <- data.frame("X" = sample(6:25, size = 1000, replace = T),
#                    "Y" = sample(c(6:20, NA), size= 1000, replace = T),
#                    "Z" = sample(c(6:19, NA), size= 1000, replace = T))

# d1 <- Data[(1:floor(nrow(Data) / 3)), ]
# d2 <- Data[(floor(nrow(Data) / 3)+1: floor(nrow(Data) / 3) * 2),]
# d3 <- Data[((floor(nrow(Data) / 3) * 2) +1) : nrow(Data) ,]


# load("src/data/d1.rda")
# load("src/data/d2.rda")
# load("src/data/d3.rda")

# datasets <- list(d1, d2, d3)

data <- lme4::Arabidopsis

#### TEST ####
col = c("total.fruits", "nutrient")
data <- data[,col]
# data <- na.omit(rbind(d1, d2, d3))
# Data_s <- Data[,col]
# data2 <- na.omit(data)

Rchisq <- chisq.test(data)

threshold = 1L
probs=NULL


chisq.mock <- function(dataset,col, threshold, probs){
    client=vtg::MockClient$new(datasets = dataset, pkgname = 'vtg.chisq')
    result=vtg.chisq::dchisq(client = client,
                                 col=col,
                                 threshold=threshold,
                                 probs=probs)
    return(result)
}

res <- chisq.mock(dataset = list(data),
                    col=col,
                    threshold=threshold,
                    probs=probs)
res$statistic == Rchisq$statistic
res$parameter == Rchisq$parameter
res$pval == Rchisq$p.value
