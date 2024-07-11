# Goal
Our goal is to construct a model that can segment bacteria in cryo-ET tomograms. This does not include structures within the bacteria&mdash;only the bacteria as a whole (the outer membrane, periplasm, cytoplasm, etc. all together).

# Plan
- As a preprocessing step, apply a guided filter (or perhaps two) to the tomogram (using the tomogram as both the guide and the input to preserve edges) to minimize noise and emphasize the outer membrane
  - <sub>It would be good to make the parameters of the filter(s) depend on the histogram characteristics of the tomogram, or at least perform a grid search over the parameters</sub>
  - <sub>To evaluate the effectiveness of a filter configuration, we could use the Intersection over Union (IoU) of the one-pixel-wide edge in a manual segmentation and the edge resulting from an edge detector applied to the filtered image.</sub>
  - <sub>The guided filter might not be the best choice. We just need an edge-preserving filter that works in 3D and scales well to the hundreds of millions of voxels in a tomogram</sub>
  - <sub>Collin is assigned to this task, at the moment</sub>

- Perform an oversegmentation of the image using a supervoxel segmentation algorithm. SLIC will probably do the trick (hey, that rhymes!).
  - <sub>I'm not yet sure how many supervoxels will be the right number. Fortunately, if we use some kind of weak classifier or decision tree type algorithm, the number of supervoxels doesn't have to be constant (I think).</sub>

- In each supervoxel, generate a handful of feature vectors. Some features that might be useful:
  - Ray features
    - On efficiency
      - In [Fast Ray Features for Learning Irregular Shapes](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=6044718), an algorithm is proposed to efficiently precalculate the Ray features. I don't think it will apply to our situation&mdash;we only need to calculate features for a small subset of the voxels in each supervoxel. I propose the following (somewhat naive) approach:
      - First, we take the gradient of the tomogram. <sub>I was thinking of using Sobel kernels or something. Some low-rank 3D kernel (whatever "rank" means in 3D, haha.)</sub> 
      - Then we threshold the gradient image to extract edges without having to run another (expensive) edge detector algorithm.
      - <sub>I have implemented a kind of "memoization" (not to be confused with memorization) to make the closest contour function more efficient. In addition, I have implemented some memoization for the gradients, if we decide that we want to calculate edges and gradients separately. That would be more like Fast Ray Features for Learning Irregular Shapes</sub>
    - Canonical orientation
      - In [Supervoxel-Based Segmentation of Mitochondria in EM Image Stacks With Learned Shape Features](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=6044718), the authors describe "align\[ing\] the descriptor to a canonical orientation, making it rotation invariant" by "reorder\[ing\] the descriptor such that $\bf{n}_1$ and $\bf{n}_2$ align with an orientation estimate". In our case, the information in the lowest and highest slices (along what ITK-SNAP calls the axial axis) is information-poor.
      - Thus, to use the notation in the paper, instead of seeking "two orthogonal vectors $e_1$ and $e_2$ in the directions of maximal variance of the local shape" in all three dimensions, I propose restricting $e_1$ and $e_2$ to lie within the 2D slice.
      - In extension, while the paper seems to depict Ray features being calculated for many angles distributed evenly in all three dimensions, I propose only shooting rays up to, say, around 30 degrees above or below the slice (again, using the notation of the paper, restrict the angle $\gamma$ such that $-\pi/6 \leq \gamma \leq \pi/6$. Consider Figure 4). Information beyond that angle is likely to be corrupt.
  - Local texture features
  - Local histogram features <sub>(I need to learn more about how exactly this works. I understand image histograms but not quite how they work as features)</sub>
  - Local intensity
  - <sub>What else might help the classifier? The only requirement is that it's relatively cheap to compute</sub>

- Train a classifier algorithm or decision tree algorithm on the resulting data, using the manual segmentations we've been developing. <sub>(We could also try a neural network, I suppose. But that should not be strictly necessary!)</sub>
  - <sub>I have not thoroughly studied this aspect of the project. My understanding of algorithms like AdaBoost (what the paper used), random forests, etc. is shallow. My hope is that with information-rich feature vectors, many such algorithms will do just fine</sub>

# Papers
1. [Supervoxel-Based Segmentation of Mitochondria in EM Image Stacks With Learned Shape Features](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=6044718) is the primary inspiration for this work.

2. [Fast Ray Features for Learning Irregular Shapes](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=6044718) describes Ray features in more depth.

3. [Guided Image Filtering](https://kaiminghe.github.io/publications/eccv10guidedfilter.pdf)

4. [SLIC superpixels](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=6205760)