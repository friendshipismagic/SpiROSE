# Renderer PoC

Welcome to the marvelous renderer for SpiROSE, the renderer of dragons.

## Running

The current requirements for this thing are :

- GPU supporting at least OpenGL 3.3 (Geometry Shader)
- GLFW
- GLEW

And the usual stuff : git, make, gcc, g++, ...

Get the single *tiny* library and build :

    git submodule init
    git submodule update
    make run

## Controls

- Mouse to drag view around (tracktable)
- `up`/`down` keys to zoom/dezoom
- `p` to pause animation
- `left`/`right` to scroll animation (no effect if animation is not paused)
- `r` to reload the shaders
- `w` to toggle wireframe (useful to see the cut)
- `c` to toggle the pizza transform

## What's implemented

- Cutting the scene
- Pizza transform
- Voxelization

## Pizza transform

This is a simple transformation, yet hard to describe.

Our display is effectively a cylinder, with rounded voxels. This does not plays
nicely with standard pictures, which are matricies of standard square pixels.
Thus, our geometry needs to be remapped to a rectangle to be able to render our
voxels.

### Simple visual explanation

Take a round pizza with crust all around. Cut along a radius. Now imagine the
pizza is infinitely stretchable. Un-cicle it to obtain a rectangular pizza with
crust on a single edge.

### Detailed explanation

Given a 3D scene, you have a bunch of triangles. However, simple rasterization
would not give the proper voxel shape. For this, we need to map polar
coordinates to cartesian ones in the dirty but efficient way of
$`(x, y) = (\theta, r)`$.

First, the scene is cut along the
$`\left\{\begin{array}{ll} x = 0 \\ y <= 0 \end{array}\right.`$ half plane. This
generates between 1 (identity) and 4 triangles for each triangle in the scene.

Then, to unwrap, we need to duplicate every vertex along the $`x = y = 0`$ axis.
This is because the coordinate mapping maps this line to the $`y = 0`$ plane.
This generates zero or one more triangle for each input triangle.

Finally, we map the coordinates. This mapping is trickily done using the other
vertices in the triangle, since we need $`\theta`$ from something else than the
current cartesian coordinates, because $`r = 0`$.

