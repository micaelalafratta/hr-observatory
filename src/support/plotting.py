"""
plotting.py
Chart functions used across all notebooks.
Every function receives data, draws one chart, and returns the figure
so the notebook can display it or save it with save_fig().
"""
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import seaborn as sns
import pandas as pd
import numpy as np
from pathlib import Path

# ── Global chart style ────────────────────────────────────────────────────────
# Applied once when this file is imported. Affects all charts in the session.
sns.set_theme(style="whitegrid", palette="muted", font_scale=1.1)
plt.rcParams.update({
    "figure.dpi":        150,   # screen resolution
    "savefig.dpi":       150,   # saved file resolution
    "savefig.bbox":      "tight",  # crop whitespace when saving
    "axes.spines.top":   False,    # remove top border from all charts
    "axes.spines.right": False,    # remove right border from all charts
})


# ── Saving ────────────────────────────────────────────────────────────────────

def save_fig(fig: plt.Figure, name: str, figures_dir: Path) -> None:
    """Save a figure as PNG to outputs/figures/. Creates the folder if needed."""
    figures_dir.mkdir(parents=True, exist_ok=True)
    fig.savefig(figures_dir / f"{name}.png")
    print(f"Saved: {figures_dir / name}.png")


# ── KPI charts ────────────────────────────────────────────────────────────────

def plot_kpi_distributions(df: pd.DataFrame, kpis: list, kpi_colors: dict) -> plt.Figure:
    """
    One histogram per KPI, side by side.
    Each histogram shows the distribution of scores plus
    vertical lines for the mean (dashed) and median (dotted).
    """
    fig, axes = plt.subplots(1, len(kpis), figsize=(5 * len(kpis), 4))

    for ax, col in zip(axes, kpis):
        color = kpi_colors.get(col, "#534AB7")
        data  = df[col].dropna()

        ax.hist(
            data,
            bins=11,              # one bin per score value (0-10)
            range=(-0.5, 10.5),   # centre each bar on its integer score
            color=color,
            alpha=0.6,
            edgecolor="white",
            linewidth=0.5,
        )
        ax.axvline(data.mean(),   color=color,  linestyle="--",
                   linewidth=1.5, label=f"Mean   {data.mean():.1f}")
        ax.axvline(data.median(), color="gray", linestyle=":",
                   linewidth=1.5, label=f"Median {data.median():.1f}")

        ax.set_title(col, fontweight="bold")
        ax.set_xlabel("Score (0-10)")
        ax.set_ylabel("Number of responses")
        ax.legend(fontsize=9)
        # Force tick marks at every integer (0, 1, 2 ... 10)
        ax.xaxis.set_major_locator(mticker.MultipleLocator(1))

    fig.tight_layout()
    return fig


def plot_boxplots(df: pd.DataFrame, cols: list, title: str) -> plt.Figure:
    """
    Horizontal boxplots for a list of columns.
    Good for comparing spread and spotting outliers across many variables at once.
    """
    data = [df[col].dropna().values for col in cols]

    fig, ax = plt.subplots(figsize=(8, len(cols) * 0.6 + 1))
    ax.boxplot(data, vert=False, labels=cols, patch_artist=True,
               boxprops=dict(facecolor="#EEEDFE", color="#534AB7"),
               medianprops=dict(color="#D85A30", linewidth=2),
               whiskerprops=dict(color="#534AB7"),
               capprops=dict(color="#534AB7"),
               flierprops=dict(marker="o", markersize=3, alpha=0.4))
    ax.set_xlim(-0.5, 10.5)
    ax.set_xlabel("Score (0-10)")
    ax.set_title(title, fontweight="bold")
    fig.tight_layout()
    return fig


# ── Segmentation charts ───────────────────────────────────────────────────────

def plot_segment_comparison(df: pd.DataFrame, segment_col: str,
                             kpis: list) -> plt.Figure:
    """
    Grouped bar chart: mean KPI score for each segment.

    .T transposes the table so KPIs are on the x-axis and
    segments appear as separate coloured bars.
    """
    means = df.groupby(segment_col)[kpis].mean().round(2)

    fig, ax = plt.subplots(figsize=(9, 4))
    means.T.plot(kind="bar", ax=ax, width=0.7, edgecolor="white")

    ax.set_ylim(0, 10)
    ax.set_ylabel("Mean score (0-10)")
    ax.set_title(f"KPI comparison by {segment_col}", fontweight="bold")
    ax.set_xticklabels(kpis, rotation=0)
    # Place legend outside the chart so it doesn't cover bars
    ax.legend(title=segment_col, bbox_to_anchor=(1, 1), loc="upper left")

    fig.tight_layout()
    return fig


# ── Correlation and driver charts ─────────────────────────────────────────────

def plot_correlation_heatmap(df: pd.DataFrame, cols: list) -> plt.Figure:
    """
    Heatmap showing Spearman correlation between columns.

    Spearman is used instead of Pearson because survey scores
    are ordinal (ranked integers), not truly continuous numbers.
    Values range from -1 (opposite) through 0 (no relation) to +1 (same direction).
    """
    corr = df[cols].corr(method="spearman")

    fig, ax = plt.subplots(figsize=(10, 8))
    sns.heatmap(
        corr,
        annot=True,       # show the number inside each cell
        fmt=".2f",        # 2 decimal places
        cmap="RdYlGn",    # red = negative, yellow = neutral, green = positive
        center=0,         # white = zero correlation
        linewidths=0.4,
        ax=ax,
        annot_kws={"size": 9},
    )
    ax.set_title("Spearman correlation matrix", fontweight="bold")
    fig.tight_layout()
    return fig


def plot_driver_importance(coef_series: pd.Series, title: str = "Driver importance") -> plt.Figure:
    """
    Horizontal bar chart of driver importance, sorted from least to most important.

    coef_series: a pandas Series where the index is the attribute name
                 and the value is its regression coefficient.

    The bars are sorted by absolute value (strength of effect regardless of direction).
    Purple = positive driver (higher score → higher satisfaction).
    Coral  = negative driver (higher score → lower satisfaction, unusual but possible).
    """
    # Sort by absolute value so the most important driver is at the top
    sorted_abs = coef_series.abs().sort_values()

    # Pick bar colour based on whether the original coefficient is positive or negative
    colors = [
        "#534AB7" if coef_series[attr] >= 0 else "#D85A30"
        for attr in sorted_abs.index
    ]

    # Make the figure taller when there are more bars so they don't crowd
    fig, ax = plt.subplots(figsize=(8, max(3, len(sorted_abs) * 0.5)))

    ax.barh(sorted_abs.index, sorted_abs.values, color=colors, edgecolor="white")
    ax.set_xlabel("|Standardised coefficient|")
    ax.set_title(title, fontweight="bold")

    fig.tight_layout()
    return fig
