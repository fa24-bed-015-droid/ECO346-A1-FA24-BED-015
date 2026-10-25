# Question 3 (and the redesign of Question 4): earnings against age with band means.
# Run from the repository root:  Rscript scripts/03_scatter.R
library(ggplot2)
library(svglite)

person <- read.csv("data/pslm_person_subset.csv")
hh     <- read.csv("data/pslm_hh_subset.csv")
d <- merge(person, hh[, c("hhid", "hhweight", "prov_code", "urban_rural")], by = "hhid")
d <- d[d$prov_code == 4 & d$urban_rural == 2 &
       d$age >= 15 & d$age <= 64 & !is.na(d$earn_annual) & d$earn_annual > 0, ]

# Five-year bands [15,20), ..., [60,65), plotted at the midpoint 17, 22, ..., 62
d$band_start <- (d$age %/% 5) * 5
bands <- do.call(rbind, lapply(split(d, d$band_start), function(g)
  data.frame(band  = paste0(g$band_start[1], "-", g$band_start[1] + 4),
             mid   = g$band_start[1] + 2,
             n     = nrow(g),
             wmean = sum(g$hhweight * g$earn_annual) / sum(g$hhweight))))
bands$thin <- bands$n < 30
bands$wmean_r <- round(bands$wmean)

print(bands[, c("band", "n", "wmean_r")], row.names = FALSE)
write.csv(data.frame(band = bands$band, n = bands$n, wmean = bands$wmean_r),
          "figures/band_table_R.csv", row.names = FALSE)   # read by the Python script to check agreement

top <- bands[which.max(bands$wmean), ]
rs <- function(x) paste0("Rs ", format(round(x), big.mark = ",", scientific = FALSE, trim = TRUE))

set.seed(346)
p <- ggplot(d, aes(age, earn_annual)) +
  geom_jitter(width = 0.4, height = 0, alpha = 0.35, size = 1.3, colour = "#1f4e79") +
  geom_line(data = bands, aes(mid, wmean), colour = "#c0392b", linewidth = 0.8) +
  geom_point(data = bands, aes(mid, wmean, fill = thin), shape = 21, size = 3.5,
             stroke = 1.2, colour = "#c0392b") +
  scale_fill_manual(values = c(`FALSE` = "#c0392b", `TRUE` = "white"), guide = "none") +
  annotate("text", x = top$mid - 1, y = top$wmean * 2.6, hjust = 1, size = 3.4,
           label = paste0("Highest band mean: ", top$band, ", ", rs(top$wmean),
                          "\n(thin band, n = ", top$n, ")")) +
  annotate("segment", x = top$mid - 1, xend = top$mid, y = top$wmean * 2.3, yend = top$wmean * 1.1,
           colour = "grey40") +
  scale_x_continuous(breaks = seq(15, 64, 5)) +
  coord_cartesian(xlim = c(14.5, 64.5)) +
  scale_y_log10(limits = c(1e4, 1e7), breaks = 10^(4:7),
                labels = c("Rs 10,000", "Rs 100,000", "Rs 1,000,000", "Rs 10,000,000")) +
  labs(title = paste0("Urban Balochistan earnings rise with age, but the ", top$band,
                      " peak rests on only ", top$n, " workers"),
       x = "Age (years)", y = "Annual earnings (log scale)",
       caption = paste0("Source: PSLM 2019-20, person file merged with household file. Sample: Balochistan urban earners aged 15-64 with earn_annual > 0 (n = ",
                        nrow(d), ").\nBand means (large markers) weighted by hhweight; hollow markers = bands with fewer than 30 observations.")) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 11), plot.title.position = "plot",
        plot.caption = element_text(hjust = 0, size = 8), plot.caption.position = "plot",
        panel.grid.minor = element_blank())

dir.create("figures", showWarnings = FALSE)
ggsave("figures/scatter.svg", p, width = 9, height = 5.5)
