##
## Exploring different ways of making the journey time index
## - two versions of PCA and simplying adding up the total times
##
## First load data, as in `load postcodes...r`
##
library(ggplot2)
library(factoextra)
library(caret)

##
## PCA to create index
## - the PCA index without the Box-Cox transformation gives essentially the same results as just adding up the travel times and using that as the index
##
# PCA using base R
journeys.pca = journeys %>% 
  # column_to_rownames("la_code") %>%   # doesn't work because "E13000002" appears twice (as Inner London and Outer London)
  select(-la_code) %>% 
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

# PCA using caret - Box-Cox transform the variables first
trans = preProcess(journeys %>% select(-la_code) %>% as.matrix(),
                   method=c("BoxCox", "center", "scale", "pca"))
journeys.pca2 = predict(trans, journeys %>% select(-la_code) %>% as.matrix()) %>% 
  as_data_frame()

# copy journey time index (principal component 1) into journeys data frame
journeys.idx = as_data_frame(journeys.pca$x)
journeys$isol_idx = journeys.idx$PC1
journeys$isol_idx2 = journeys.pca2$PC1

cor(journeys$isol_idx, journeys$isol_idx2)
cor(journeys$isol_idx, journeys$isol_total)

# also make a simple index from the total minutes
journeys = journeys %>% 
  mutate(isol_total = gpptt + hospptt + hospcart + foodptt + townptt)


##
## merge travel time index by local authority codes
##
postcodes = postcodes %>% 
  left_join(journeys, by=c("laua" = "la_code"))

# how well does the PC1 coordinate correlate with rural/urban classifications?
ggplot(postcodes, aes(x=`Rural or Urban?`, y=isol_idx)) + geom_boxplot()
ggplot(postcodes, aes(x=`Rural or Urban?`, y=isol_idx2)) + geom_boxplot()
ggplot(postcodes, aes(x=`Rural or Urban?`, y=isol_total)) + geom_boxplot()  # 

pc_sub = postcodes %>% 
  select(`Rural or Urban?`, isol_idx, isol_idx2, isol_total) %>% 
  na.omit() %>% 
  mutate(rural = ifelse(`Rural or Urban?` == "Rural", 1, 0))

m1 = glm(rural ~ isol_idx, data=pc_sub, family=binomial())
m2 = glm(rural ~ isol_idx2, data=pc_sub, family=binomial())
m3 = glm(rural ~ isol_total, data=pc_sub, family=binomial())

MuMIn::model.sel(m1, m2, m3)

##
##--> the PCA index using Box-Cox tranformation gives best-fitting model
##
