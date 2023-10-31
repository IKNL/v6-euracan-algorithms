rm(list = ls(all.names = TRUE))

load("src/data/d1.rda")
load("src/data/d2.rda")
load("src/data/d3.rda")


#
#   Build-in Chisq test
#
data <- na.omit(rbind(d1, d2, d3))
col <- c("X", "Y", "Z")
data <- na.omit(data)
central_result <- chisq.test(data)


#
#   Federated Chisq test
#
datasets <- list(d1, d2, d3)
threshold = 5L
probs=NULL

# Configure logginh

chisq.mock <- function(dataset, col, threshold, probs){

    client = vtg::MockClient$new(
        datasets = datasets,
        pkgname = 'vtg.chisq'
    )

    log <- lgr::get_logger("vtg/MockClient")
    log$set_threshold("debug")
    log <- lgr::get_logger("vtg/Client")
    log$set_threshold("debug")


    result=vtg.chisq::dchisq(client=client, col=col, threshold=threshold,
                             probs=probs)
    return(result)
}

federated_result <- chisq.mock(dataset=datasets, col=col, threshold=threshold,
                               probs=probs)

#
#   Compare results
#
federated_result$statistic == central_result$statistic
federated_result$parameter == central_result$parameter
federated_result$pval == central_result$p.value
