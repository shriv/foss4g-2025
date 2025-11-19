import pandas as pd
from clustergram import Clustergram
from scipy.cluster import hierarchy
import matplotlib.pyplot as plt


def clustering(percentiles_joined, num_clusters=20):
    standardized = (
        percentiles_joined - percentiles_joined.mean()
    ) / percentiles_joined.std()
    standardized.head()

    cgram = Clustergram(range(1, num_clusters), backend='sklearn', n_init=10, random_state=42)
    cgram.fit(standardized.fillna(0))
    
    return(cgram)


def clustering_scores_plot(cgram, num_clusters=20):
    cgram.davies_bouldin_score()
    (pd.DataFrame(
        data = {
            'x': list(range(2, num_clusters, 1)),
            'y': cgram.davies_bouldin_.values})
    .plot(
        x='x',
        y ='y', 
        kind='scatter', 
        ylabel="Davies-Bouldin score",
        xlabel = "Number of clusters")
    )

    return


def best_cluster_number(cgram, num_clusters=20):
    cgram.davies_bouldin_score()
    db_score = pd.DataFrame(
        data = {
            'x': list(range(2, num_clusters, 1)),
            'y': cgram.davies_bouldin_.values}
        )
    
    gt_3 = db_score.query('x > 3')
    best_cluster = gt_3.loc[gt_3['y'].idxmin(), 'x']


    return best_cluster


def static_clustergram(cgram, num_cluster):
    ax = cgram.plot(
    figsize=(10, 8),
    linewidth=0.5,
    cluster_style={"edgecolor": "w", "color": 'r', "linewidth": 1.5},
    size=1,
    line_style={"color":'b'},
    pca_kwargs=dict(random_state=0),
    )
    ax.set_ylim(-12, 25)
    ax.axvline(num_cluster, color='red', ymin=.02, ymax=.98)
    return(ax)


def cluster_hierarchy(perc_with_cluster):
    group = perc_with_cluster.groupby('cluster').mean()
    Z = hierarchy.linkage(group, 'ward')
    plt.figure(figsize=(25, 10))
    _ = hierarchy.dendrogram(Z, labels=group.index)
    plt.gcf()
