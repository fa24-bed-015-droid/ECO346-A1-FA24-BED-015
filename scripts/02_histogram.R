# Question 2: weighted histogram of annual earnings on a log10 scale.
# Run from the repository root:  Rscript scripts/02_histogram.R
library(ggplot2)
library(svglite)

person <- read.csv("data/pslm_person_subset.csv")
hh     <- read.csv("data/pslm_hh_subset.csv")
d <- merge(person, hh[, c("hhid", "hhweight", "prov_code", "urban_rural")], by = "hhid")
d <- d[d$prov_code == 4 & d$urban_rural == 2 &
       d$age >= 15 & d$age <= 64 & !is.na(d$earn_annual) & d$earn_annual > 0, ]

# Weighted quantile, exactly as defined in the brief: smallest x whose
# cumulative weight share reaches or exceeds p (not R's quantile()).
wq <- function(x, w, p) {
  o <- order(x); x <- x[o]; w <- w[o]
  x[which(cumsum(w) / sum(w) >= p - 1e-12)[1]]
}

n_earners  <- nrow(d)
w_median   <- wq(d$earn_annual, d$hhweight, 0.5)
u_median   <- wq(d$earn_annual, rep(1, n_earners), 0.5)
w_p10      <- wq(d$earn_annual, d$hhweight, 0.1)
w_p90      <- wq(d$earn_annual, d$hhweight, 0.9)
ratio      <- round(w_p90 / w_p10, 2)

d$lx <- log10(d$earn_annual)
in_range <- d$lx >= 4 & d$lx <= 7
n_excluded <- sum(!in_range)
h <- d[in_range, ]

# Bins 0.1 wide from 4.0 to 7.0 (30 bins); a value of exactly 7.0 goes in the last bin
bin <- pmin(floor((h$lx - 4) / 0.1 + 1e-9), 29)
wsum <- tapply(h$hhweight, factor(bin, levels = 0:29), sum)
wsum[is.na(wsum)] <- 0
bins <- data.frame(lo = 4 + 0.1 * (0:29), hi = 4 + 0.1 * (1:30),
                   dens = as.numeric(wsum) / sum(h$hhweight) / 0.1)   # density per log10 unit

rs <- function(x) paste0("Rs ", format(x, big.mark = ",", scientific = FALSE, trim = TRUE))

cat("Earners:", n_earners, "\nWeighted median:", w_median, "\nUnweighted median:", u_median,
    "\nWeighted p10:", w_p10, "\nWeighted p90:", w_p90, "\np90/p10:", ratio,
    "\nExcluded:", n_excluded, "\n")

ymax <- max(bins$dens)
p <- ggplot(bins) +
  geom_rect(aes(xmin = lo, xmax = hi, ymin = 0, ymax = dens), fill = "#1f4e79", colour = "white") +
  geom_vline(xintercept = log10(c(w_median, w_p90)), linetype = "dashed") +
  annotate("text", x = log10(w_median) - 0.03, y = ymax * 1.02, hjust = 1,
           label = paste("Weighted median", rs(w_median)), size = 3.4) +
  annotate("text", x = log10(w_p90) + 0.03, y = ymax * 1.02, hjust = 0,
           label = paste("90th percentile", rs(w_p90)), size = 3.4) +
  scale_x_continuous(breaks = 4:7, limits = c(4, 7),
                     labels = c("Rs 10,000", "Rs 100,000", "Rs 1,000,000", "Rs 10,000,000")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(title = paste0("Half of urban Balochistan's earners make under ", rs(w_median),
                      " a year; the top tenth make over ", rs(w_p90)),
       x = "Annual earnings (log scale)", y = "Density per log10 unit",
       caption = paste0("Source: PSLM 2019-20, person file merged with household file. Sample: Balochistan urban earners aged 15-64 with earn_annual > 0 (n = ",
                        n_earners, ").\nWeighted by hhweight. Earners outside Rs 10,000-10,000,000 excluded: ", n_excluded, ".")) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 11), plot.title.position = "plot",
        plot.caption = element_text(hjust = 0, size = 8), plot.caption.position = "plot",
        panel.grid.minor = element_blank())

dir.create("figures", showWarnings = FALSE)
ggsave("figures/histogram.svg", p, width = 9, height = 5.5)
