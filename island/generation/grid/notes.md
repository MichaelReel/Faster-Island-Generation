# Grid Layer

Creates an array of points in 3d space on a flat (y=0) plane.

Each point has a link to it's neighbour points so that here are up to six connected points, left, right, 2 above and 2 below.

Depending on the row the point is on, the positions of the connected points can be calculated

```text
 row  |
  0   | 0_____1_____2_____3_____4
      |  \    /\    /\    /\    /
      |   \  /  \  /  \  /  \  /
  1   |   0\/___1\/___2\/___3\/     Where (x) is odd, the connected (y+/-1) are: (x) and (x+1)
      |    /\    /\    /\    /\
      |   /  \  /  \  /  \  /  \
  2   | 0/___1\/___2\/___3\/___4\   Where (x) is even, the connected (y+/-1) are: (x-1) and (x)
      |  \    /\    /\    /\    /
      |   \  /  \  /  \  /  \  /
  3   |   0\/___1\/___2\/___3\/
```

Creates an array of triangles based on the connections between the 3D points.

Produces a mesh of triangles representing the base triangle mesh by going through all the triangles and drawing the points using a primitive triangle surface tool.
