# Question 4 (first half): R's default scatterplot, nothing added.
# Run from the repository root:  Rscript scripts/01_default.R
library(ggplot2)
library(svglite)

person <- read.csv("data/pslm_person_subset.csv")
hh     <- read.csv("data/pslm_hh_subset.csv")
d <- merge(person, hh[, c("hhid", "hhweight", "prov_code", "urban_rural")], by = "hhid")

# Variant 7 = Balochistan (prov_code 4), urban (urban_rural 2); earners aged 15-64
d <- d[d$prov_code == 4 & d$urban_rural == 2 &
       d$age >= 15 & d$age <= 64 & !is.na(d$earn_annual) & d$earn_annual > 0, ]

p <- ggplot(d, aes(age, earn_annual)) + geom_point()
dir.create("figures", showWarnings = FALSE)
ggsave("figures/default.svg", p)
