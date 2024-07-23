module Forests

using Random
using MLJ
using ImageContrastAdjustment
using HistogramThresholding
using DataFrames
using StatsBase
RandomForestRegressor = MLJ.@load RandomForestRegressor pkg=DecisionTree

struct UnaryForest
    X
    y
    inds_train
    inds_test
    model
    mach # machine
end

function UnaryForest(X::Matrix, y::Vector, train_test_split=0.7)
    # Convert X to DataFrame
    X_df = DataFrame(X', :auto)

    model = RandomForestRegressor()
    mach = machine(model, X_df, y)

    N_train = floor(Int, length(y) * train_test_split)
    rows_perm = randperm(length(y))
    rows_train = rows_perm[1:N_train]
    rows_test = rows_perm[N_train+1:end]
    fit!(mach, rows=rows_train)

    return UnaryForest(
        X,
        y,
        rows_train,
        rows_test,
        model,
        mach
    )
end

function test(uf::UnaryForest)
    ŷ = predict(uf, uf.X[:, uf.inds_test])
    y_truth = uf.y[uf.inds_test]

    return mean(ŷ .== y_truth)
end

function predict_raw(uf::UnaryForest, X::Matrix)
    X_df = DataFrame(X', :auto)
    return MLJ.predict(uf.mach, X_df)
end

function predict(uf::UnaryForest, X::Matrix)
    ŷ = predict_raw(uf, X)

    edges, counts = build_histogram(ŷ, 256)
    threshold = find_threshold(Yen(), counts[1:end], edges)

    ŷ = [val > threshold ? 1. : 0. for val in ŷ]
    return ŷ
end

function predict_dict(uf::UnaryForest, features_dict::Dict)
    all_keys = collect(keys(features_dict))
    pred_dict = Dict()
    for key in all_keys
        feature_matrix = features_dict[key]
        ŷ = predict(uf, feature_matrix)
        pred = mode(ŷ) # TODO: Problem is threshold
        pred_dict[key] = pred
    end
    return pred_dict
end

end # module

module Tst
using ..Forests
using JLD2
function test()
    features = load_object("features_initial.jld2")
    labels = load_object("classes_initial.jld2")
    uf = Forests.UnaryForest(features, labels, 0.7)
    println(Forests.test(uf))
end
end # module Tst