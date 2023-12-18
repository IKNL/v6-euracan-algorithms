# Clear the environment completely
rm(list = ls(all.names = TRUE))
devtools::load_all("./vtg.preprocessing/src")
devtools::load_all("./vtg.survfit/src")
# This seems to be equivalent to "import x as y"
library(namespace)
tryCatch({
    invisible(registerNamespace('vtg', loadNamespace('vtg')))
}, error = function(e) {
    vtg::writeln("Package 'vantage.infrastructure' already loaded.")
})

library(vtg.survfit)

d1 <- read.csv("C:\\data\\euracan-node-a.csv")
dataset=list(d1, d1, d1)
###exapl

# formula = Surv(time, status) ~ trt
#formula = Surv(time,, status) ~ trt
formula = 'Surv(surv, deadOS) ~ b04_sex'

conf.int=0.95
conf.type='log'
timepoints=NULL
plotCI=F
tmax=NA

subset_rules <- data.frame(
    subset=c("b04_sex!=999")
)
#timepoints = seq(0,1000,20)

survfit.mock <- function(dataset,formula,conf.type,conf.int,timepoints,plotCI,tmax){
    client=vtg::MockClient$new(datasets = dataset,pkgname = 'vtg.survfit')
    result=vtg.survfit::dsurvfit(client = client,
                                 formula=formula,
                                 conf.int = conf.int,
                                 conf.type = conf.type,
                                 timepoints = timepoints,
                                 plotCI = plotCI,
                                 tmax=tmax,
                                 subset_rules = subset_rules)
    return(result)
}

res <- survfit.mock(dataset = dataset,
             formula = formula,
             conf.int = conf.int,
             conf.type = conf.type,
             timepoints = timepoints,
             plotCI = plotCI,
             tmax=tmax)

library(survival)
vars <- all.vars(as.formula(formula))
d2 <- vtg.preprocessing::extend_data(d1)
d3 <- vtg.preprocessing::subset_data(d2,subset_rules)
res_local <- survival::survfit(
    formula = as.formula(formula),
    data = na.omit(d3[,vars]),
    conf.type = conf.type,
)