module Forests

using Random
using MLJ
using DataFrames
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
    ŷ = MLJ.predict(uf.mach, DataFrame(uf.X[:, uf.inds_test]', :auto))
    y_truth = uf.y[uf.inds_test]
    return ŷ, y_truth
end

function predict(uf::UnaryForest, X::Matrix)
    X_df = DataFrame(X', :auto)
    return MLJ.predict(uf.mach, X_df)
end

end # module