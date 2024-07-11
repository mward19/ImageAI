# Goal
Our goal is to construct a model that can efficiently segment bacteria in cryo-ET tomograms. This does not include structures within the bacteria&mdash;only the bacteria as a whole (the outer membrane, periplasm, cytoplasm, etc. all together).

# Plan
- As a preprocessing step, apply a guided filter (or perhaps two, if it's cheap enough) to the tomogram (using the tomogram as both the guide and the input to preserve edges) to minimize noise and emphasize the outer membrane

- Perform an oversegmentation of the image using a supervoxel segmentation algorithm. SLIC will probably do the trick (hey, that rhymes!).

- In each supervoxel, generate a handful of feature vectors. Some features that might be useful:
  - Ray features (see the Ray features subheading)
  - Local texture features
  - Local histogram features
  - Local intensity
  - Whatever else we can think of that's cheap and information-rich

- Train a classifier algorithm or decision tree algorithm on the resulting data, using the manual segmentations we've been developing.


## Notes on preprocessing
It would be good to make the parameters of the filter(s) depend on the histogram characteristics of the tomogram, or at least perform a grid search over the parameters.

To evaluate the effectiveness of a filter configuration, we could use the Intersection over Union (IoU) of the one-pixel-wide edge in a manual segmentation and the edge resulting from an edge detector applied to the filtered image.

The guided filter might not be the best choice. We just need an edge-preserving filter that works in 3D and scales well to the hundreds of millions of voxels in a tomogram.

Collin is assigned to this task, at the moment.

## Notes on supervoxel segmentation
I'm not yet sure how many supervoxels will be the right number. Fortunately, if we use some kind of weak classifier or decision tree type algorithm, the number of supervoxels doesn't have to be constant (I think).

Perhaps we could find ideal parameters using a method akin to the evaluation described in Notes on preprocessing.

## Notes on Ray features
### On efficiency
In [Fast Ray Features for Learning Irregular Shapes](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=6044718), an algorithm is proposed to efficiently precalculate the Ray features. I don't think it will apply to our situation&mdash;we only need to calculate features for a small subset of the voxels in each supervoxel. I propose the following (somewhat naive) approach:

First, we take the gradient of the tomogram. <sub>I was thinking of using Sobel kernels or something. Some low-rank 3D kernel (whatever "rank" means in 3D, haha.)</sub> 

Then we threshold the gradient image to extract edges without having to run another (expensive) edge detector algorithm.

<sub>I have implemented a kind of "memoization" (not to be confused with memorization) to make the closest contour function more efficient. In addition, I have implemented some memoization for the gradients, if we decide that we want to calculate edges and gradients separately. That would be more like Fast Ray Features for Learning Irregular Shapes</sub>

### Canonical orientation
In [Supervoxel-Based Segmentation of Mitochondria in EM Image Stacks With Learned Shape Features](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=6044718), the authors describe "align\[ing\] the descriptor to a canonical orientation, making it rotation invariant" by "reorder\[ing\] the descriptor such that $\mathbf{n}_1$ and $\mathbf{n}_2$ align with an orientation estimate". In our case, the information in the lowest and highest slices (along what ITK-SNAP calls the axial axis) is information-poor.

Thus, to use the notation in the paper, instead of seeking "two orthogonal vectors $e_1$ and $e_2$ in the directions of maximal variance of the local shape" in all three dimensions, I propose restricting $e_1$ and $e_2$ to lie within the 2D slice.

In extension, while the paper seems to depict Ray features being calculated for many angles distributed evenly in all three dimensions, I propose only shooting rays up to, say, around 30 degrees above or below the slice (again, using the notation of the paper, restrict the angle $\gamma$ such that $-\pi/6 \leq \gamma \leq \pi/6$. Consider Figure 4). Information beyond that angle is likely to be corrupt.

### Dealing with the edges of the image
Because most tomograms are not large enough to depict a bacterium in its entirety, it is to be expected that a ray shot toward the borders of the tomogram will likely not encounter any contour. I propose the following modifications (or clarifications?) to the behavior of the four ray features and the closest contour function at the edges of the tomogram.

- Closest contour function $c(\mathbf{m}) = \mathbf{c}$
  - If a ray does not encounter a contour before reaching the edge of the image, then the closest contour is the position of the spot where the ray encountered the edge of the image, but those dimensions that lie on the edge of the image are saved as $-\infty$ or $\infty$ instead of the usual pixel value.
- Distance feature
  - If the vector $\mathbf{c} = c(\mathbf{m})$ has some $\infty$ value in it, return $\infty$.
- All other Ray features (Distance difference feature, Orientation feature, Norm feature)
  - If the vector $\mathbf{c} = c(\mathbf{m})$ has some $\infty$ value in it, return NaN (not a number).

## Notes on classifier algorithm
I have not thoroughly studied this aspect of the project. My understanding of algorithms like AdaBoost (what the paper used), random forests, etc. is shallow. My hope is that with information-rich feature vectors, many such algorithms will do just fine.

(We could also try a neural network, I suppose. But that should not be strictly necessary!)


# Papers
1. [Supervoxel-Based Segmentation of Mitochondria in EM Image Stacks With Learned Shape Features](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=6044718) is the primary inspiration for this work.

2. [Fast Ray Features for Learning Irregular Shapes](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=5459210)describes Ray features in more depth.

3. [Guided Image Filtering](https://kaiminghe.github.io/publications/eccv10guidedfilter.pdf)

4. [SLIC superpixels](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=6205760)