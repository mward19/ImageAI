# import a bunch of tomograms, generate features, save labels.
module SVM
using LIBSVM
using Statistics

struct SVMUnary
    features_train
    classes_train
    model
    features_test
    classes_test
end

struct SVMPairwise
    model
end

function SVMUnary(
        features_train::Matrix, 
        classes_train::Vector, 
        features_test::Matrix, 
        classes_test::Vector
    )
    return SVMUnary(
        features_train,
        classes_train,
        svmtrain(features_train, classes_train),
        features_test,
        classes_test
    )
end

function SVMUnary(features::Matrix, classes::Vector)
    train_test_split = 0.7
    cutoff = floor(Int, length(classes) * train_test_split)
    features_train = features[:, begin:cutoff]
    features_test  = features[:, cutoff+1:end]
    classes_train  = classes[begin:cutoff]
    classes_test   = classes[cutoff+1:end]
    return SVMUnary(
        features_train,
        classes_train,
        svmtrain(features_train, classes_train),
        features_test,
        classes_test
    )
end

function test(model::SVMUnary)
    predictions = svmpredict(model, features_test)
    results = predictions .== classes_test
    return mean(results)
end

end # module