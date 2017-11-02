# Renderer PoC

Welcome to the marvelous renderer for SpiROSE, the renderer of dragons.

## Running

The current requirements for this thing are :

- GPU supporting at least OpenGL 3.3 (Geometry Shader)
- GLFW
- GLEW

And the usual stuff : git, make, gcc, g++, ...

Get the single *tiny* library and build :

    make dep
    make run

## Controls

- Mouse to drag view around (tracktable)
- `up`/`down` keys to zoom/dezoom
- `p` to pause animation
- `left`/`right` to scroll animation (no effect if animation is not paused)
- `r` to reload the shaders
- `w` to toggle wireframe (useful to see the cut)

## What's implemented

- Cutting the scene
- Pizza transform

## TODO

- Voxelization

