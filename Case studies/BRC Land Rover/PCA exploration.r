##
## Exploring different ways of making the journey time index
## - two versions of PCA and simplying adding up the total times
##
## First load data, as in `load postcodes...r` -- run that code up to line 105
##
library(ggplot2)
library(corrplot)
library(factoextra)
library(caret)

journeys.data = journeys %>% 
  select(-la_code)

journeys.data_z = scale(journeys.data) %>% as_data_frame()

##
## explore travel times
##
# bivariate correlations
corrplot(cor(journeys.data), order = "hclust", tl.col='black', tl.cex=.75) 

# histograms of each journey time variable
journeys.data %>% 
  tidyr::gather("var", "value") %>% 
  ggplot(aes(x=value)) + geom_histogram(binwidth = 1) + facet_wrap("var", scales="free_x")

##
## PCA to create index
## - the PCA index without the Box-Cox transformation gives essentially the same results as just adding up the travel times and using that as the index
##
# PCA using base R
journeys.pca = journeys.data %>% 
  prcomp(., center=T, scale=T)

print(journeys.pca)
plot(journeys.pca, type="l")
summary(journeys.pca)

# explore results of PCA
fviz_eig(journeys.pca)

fviz_pca_ind(journeys.pca,
             col.ind = "cos2", # Color by the quality of representation
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = F     # Avoid text overlapping
)

fviz_pca_var(journeys.pca,
             col.var = "contrib", # Color by contributions to the PC
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     # Avoid text overlapping
)

# copy journey time index (principal component 1) into journeys data frame
journeys.idx = as_data_frame(journeys.pca$x)
journeys$isol_idx = journeys.idx$PC1

##
## PCA using caret - Box-Cox transform the variables first
##
trans = preProcess(journeys %>% select(-la_code) %>% as.matrix(),
                   method=c("BoxCox", "center", "scale", "pca"))
journeys.pca2 = predict(trans, journeys %>% select(-la_code) %>% as.matrix()) %>% 
  as_data_frame()

# copy journey time index (principal component 1) into journeys data frame
journeys$isol_idx2 = journeys.pca2$PC1

##
## factor analysis
##
journeys.fa = factanal(journeys.data_z, factors=1, rotation="varimax", scores="regression")

journeys.fa$loadings

# Plot loadings against one another
load = journeys.fa$loadings[,1:2]
plot(load, type="n") # set up plot 
text(load, labels=names(journeys.data_z), cex=.7) # add variable names

# manually calculate scores
# source 1: https://stat.ethz.ch/pipermail/r-help/2002-April/020278.html
# source 2: https://stackoverflow.com/a/4146131
# journeys.scores = as.matrix(journeys.data_z) %*% solve(journeys.fa$correlation) %*% loadings(journeys.fa)  

# copy journey time index (principal component 1) into journeys data frame
journeys$isol_idx_fa = journeys.fa$scores[,1]

##
## make a simple index from the total minutes
##
journeys = journeys %>% 
  mutate(isol_total = gpptt + hospptt + hospcart + foodptt + townptt)


##
## merge travel time index by local authority codes
##
postcodes = postcodes %>% 
  left_join(journeys, by=c("laua" = "la_code"))

##
## explore the different indices 
##
journeys %>% 
  select(isol_idx_fa, isol_idx, isol_idx2, isol_total) %>% 
  cor()

# how well does each index correlate with rural/urban classifications?
p1 = ggplot(postcodes, aes(x=`Rural or Urban?`, y=isol_idx))    + geom_boxplot() + ggtitle("PCA (untransformed)")
p2 = ggplot(postcodes, aes(x=`Rural or Urban?`, y=isol_idx2))   + geom_boxplot() + ggtitle("PCA (transformed)")
p3 = ggplot(postcodes, aes(x=`Rural or Urban?`, y=isol_idx_fa)) + geom_boxplot() + ggtitle("Factor analysis")
p4 = ggplot(postcodes, aes(x=`Rural or Urban?`, y=isol_total))  + geom_boxplot() + ggtitle("Total times")

gridExtra::grid.arrange(p1, p2, p3, p4, ncol=2)

# how well does each index predict whether a postcode is somewhere rural?
pc_sub = postcodes %>% 
  select(`Rural or Urban?`, isol_idx, isol_idx2, isol_idx_fa, isol_total) %>% 
  na.omit() %>% 
  mutate(rural = ifelse(`Rural or Urban?` == "Rural", 1, 0))

m1 = glm(rural ~ isol_idx,    data=pc_sub, family=binomial())
m2 = glm(rural ~ isol_idx2,   data=pc_sub, family=binomial())
m3 = glm(rural ~ isol_idx_fa, data=pc_sub, family=binomial())
m4 = glm(rural ~ isol_total,  data=pc_sub, family=binomial())

MuMIn::model.sel(m1, m2, m3, m4)

##
##--> the PCA index using Box-Cox tranformation gives best-fitting model
##
