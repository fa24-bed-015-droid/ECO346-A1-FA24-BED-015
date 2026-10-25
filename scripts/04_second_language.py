# Question 5: recompute the band table of Question 3 and redraw the figure in Python.
# Run from the repository root:  python scripts/04_second_language.py
import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter, FixedLocator, NullLocator

# Variant 7 = Balochistan (prov_code 4), urban (urban_rural 2)
PROV, AREA = 4, 2

person = pd.read_csv("data/pslm_person_subset.csv")
hh = pd.read_csv("data/pslm_hh_subset.csv")
df = person.merge(hh[["hhid", "hhweight", "prov_code", "urban_rural"]], on="hhid", how="left")

earners = df[(df.prov_code == PROV) & (df.urban_rural == AREA)
             & (df.age >= 15) & (df.age <= 64) & (df.earn_annual > 0)].copy()

# Five-year bands [15,20), [20,25), ..., [60,65); plotted at 17, 22, ..., 62
earners["band_start"] = (earners.age // 5) * 5
rows = []
for start, d in earners.groupby("band_start"):
    rows.append({
        "band": f"{start}-{start + 4}",
        "mid": start + 2,
        "n": len(d),
        "wmean": round(float((d.hhweight * d.earn_annual).sum() / d.hhweight.sum())),
    })
bands = pd.DataFrame(rows)
bands["thin"] = bands.n < 30
print(bands.to_string(index=False))

os.makedirs("figures", exist_ok=True)
bands[["band", "n", "wmean"]].to_csv("figures/band_table_python.csv", index=False)

# Compare with the table written by the R script (03_scatter.R), if it exists
r_path = "figures/band_table_R.csv"
if os.path.exists(r_path):
    r = pd.read_csv(r_path)
    same = (r["band"].values == bands["band"].values).all() and \
           (r["n"].values == bands["n"].values).all() and \
           (r["wmean"].round().values == bands["wmean"].values).all()
    print("R and Python band tables agree to the rupee:", same)

# ---- Figure ----
rng = np.random.default_rng(346)                      # jitter: uniform, at most +/-0.4 years
x = earners.age.values + rng.uniform(-0.4, 0.4, len(earners))
y = earners.earn_annual.values

fig, ax = plt.subplots(figsize=(9, 5.5))
ax.scatter(x, y, s=14, color="#1f4e79", alpha=0.35, linewidths=0, zorder=1)
ax.plot(bands.mid, bands.wmean, color="#c0392b", lw=1.6, zorder=2)
full, thin = bands[~bands.thin], bands[bands.thin]
ax.scatter(full.mid, full.wmean, s=70, color="#c0392b", zorder=3)
ax.scatter(thin.mid, thin.wmean, s=70, facecolors="white", edgecolors="#c0392b",
           linewidths=1.8, zorder=3)

top = bands.loc[bands.wmean.idxmax()]
ax.annotate(f"Highest band mean: {top.band}, Rs {int(top.wmean):,}\n(thin band, n = {int(top.n)})",
            xy=(top.mid, top.wmean), xytext=(top.mid - 1, top.wmean * 2.6),
            ha="right", fontsize=9, arrowprops=dict(arrowstyle="-", color="grey"))

ax.set_yscale("log")
ax.set_ylim(1e4, 1e7)
ax.yaxis.set_major_locator(FixedLocator([1e4, 1e5, 1e6, 1e7]))
ax.yaxis.set_minor_locator(NullLocator())
ax.yaxis.set_major_formatter(FuncFormatter(lambda v, _: f"Rs {int(v):,}"))   # default is 10^4 notation
ax.set_xlim(14.5, 64.5)
ax.set_xlabel("Age (years)")
ax.set_ylabel("Annual earnings (log scale)")
ax.spines[["top", "right"]].set_visible(False)

mean_mid = bands.loc[bands.band == "45-49", "wmean"].iloc[0]
ax.set_title(f"Urban Balochistan earnings rise with age, but the {top.band} peak rests on only {int(top.n)} workers",
             loc="left", fontsize=11)
fig.text(0.01, 0.01,
         f"Source: PSLM 2019-20, person file merged with household file. Sample: Balochistan urban earners aged 15-64 "
         f"with earn_annual > 0 (n = {len(earners)}).\nWeighted by hhweight (band means). Hollow markers: bands with "
         f"fewer than 30 observations.", fontsize=7.5, ha="left", va="bottom")
fig.tight_layout(rect=(0, 0.07, 1, 1))
fig.savefig("figures/scatter_python.svg")
print("saved figures/scatter_python.svg")
