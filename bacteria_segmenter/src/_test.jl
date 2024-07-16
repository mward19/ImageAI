using MultivariateStats

closest_contours = randn(12, 4)
pca_model = fit(PCA, closest_contours)