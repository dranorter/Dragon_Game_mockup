/**********************************************
 *
 * Implements a 3D quasicrystal tiling within 
 * given rectangular bounds.
 *
 * Daniel Demski
 *
 **********************************************/

// TODO want different grids easily available to construct.
public class Quasicrystal {
  // Radius is roughly how many cells will be rendered in
  float radius = 4;
  // Tolerance is used when checking whether two vertices are equal.
  float tolerance = 0.01;

  Point6D fivedeex = new Point6D(new float[]{random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1)});
  Point6D fivedeey = new Point6D(new float[]{random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1)});
  Point6D fivedeez = new Point6D(new float[]{random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1)});
  Point6D fivedeew = new Point6D(new float[]{random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1)});
  Point6D fivedee0 = new Point6D(new float[]{0, 0, 0, 0, 0, 0});
  Point6D fivedee1 = new Point6D(new float[]{0, 0, 0, 0, 0, 0});
  Point6D fivedee2 = new Point6D(new float[]{0, 0, 0, 0, 0, 0});

  ArrayList<Point6D> cells = new ArrayList<Point6D>();
  ArrayList<Rhomb> rhombs = new ArrayList<Rhomb>();
  ArrayList<Block> blocks = new ArrayList<Block>();

  public Quasicrystal(Point6D w, Point6D x, Point6D y, Point6D z, float r) {
    fivedeex = x;
    fivedeey = y;
    fivedeez = z;
    fivedeew = w;
    radius = r;
    // these are the actual basis vectors: (making them orthogonal)
    fivedee0 = fivedeex.normalized();
    fivedee1 = fivedeey.ortho(fivedee0).normalized();
    fivedee2 = fivedeez.ortho(fivedee0).ortho(fivedee1).normalized();

    // We then make our original vectors line up to these.
    // Sizes here determine bounded area of the render.
    fivedeex = fivedee0.times(radius);
    fivedeey = fivedee1.times(radius);
    fivedeez = fivedee2.times(radius);

    // Now we need to iterate over all the planes which fall inside our space, checking for intersections.

    // (as below w/ lines:) start values are rounded properly to get the smallest half-integer actually defining a plane
    float planestart0 = ceil(0.5 + fivedeew.point[0] + min(new float[]{0, fivedeex.point[0]}) + min(new float[]{0, fivedeey.point[0]}) + min(new float[]{0, fivedeez.point[0]})) - 0.5;
    float planestart1 = ceil(0.5 + fivedeew.point[1] + min(new float[]{0, fivedeex.point[1]}) + min(new float[]{0, fivedeey.point[1]}) + min(new float[]{0, fivedeez.point[1]})) - 0.5;
    float planestart2 = ceil(0.5 + fivedeew.point[2] + min(new float[]{0, fivedeex.point[2]}) + min(new float[]{0, fivedeey.point[2]}) + min(new float[]{0, fivedeez.point[2]})) - 0.5;
    float planestart3 = ceil(0.5 + fivedeew.point[3] + min(new float[]{0, fivedeex.point[3]}) + min(new float[]{0, fivedeey.point[3]}) + min(new float[]{0, fivedeez.point[3]})) - 0.5;
    float planestart4 = ceil(0.5 + fivedeew.point[4] + min(new float[]{0, fivedeex.point[4]}) + min(new float[]{0, fivedeey.point[4]}) + min(new float[]{0, fivedeez.point[4]})) - 0.5;
    float planestart5 = ceil(0.5 + fivedeew.point[5] + min(new float[]{0, fivedeex.point[5]}) + min(new float[]{0, fivedeey.point[5]}) + min(new float[]{0, fivedeez.point[5]})) - 0.5;

    float planeends0 = fivedeew.point[0] + max(new float[]{0, fivedeex.point[0]}) + max(new float[]{0, fivedeey.point[0]}) + max(new float[]{0, fivedeez.point[0]});
    float planeends1 = fivedeew.point[1] + max(new float[]{0, fivedeex.point[1]}) + max(new float[]{0, fivedeey.point[1]}) + max(new float[]{0, fivedeez.point[1]});
    float planeends2 = fivedeew.point[2] + max(new float[]{0, fivedeex.point[2]}) + max(new float[]{0, fivedeey.point[2]}) + max(new float[]{0, fivedeez.point[2]});
    float planeends3 = fivedeew.point[3] + max(new float[]{0, fivedeex.point[3]}) + max(new float[]{0, fivedeey.point[3]}) + max(new float[]{0, fivedeez.point[3]});
    float planeends4 = fivedeew.point[4] + max(new float[]{0, fivedeex.point[4]}) + max(new float[]{0, fivedeey.point[4]}) + max(new float[]{0, fivedeez.point[4]});
    float planeends5 = fivedeew.point[5] + max(new float[]{0, fivedeex.point[5]}) + max(new float[]{0, fivedeey.point[5]}) + max(new float[]{0, fivedeez.point[5]});

    float[] planestarts = new float[]{planestart0, planestart1, planestart2, planestart3, planestart4, planestart5};
    float[] planeends = new float[]{planeends0, planeends1, planeends2, planeends3, planeends4, planeends5};

    //The corners of our space, for use later:

    Point6D corner000 = fivedeew.copy();
    Point6D corner001 = fivedeew.plus(fivedeez);
    Point6D corner010 = fivedeew.plus(fivedeey);
    Point6D corner100 = fivedeew.plus(fivedeex);
    Point6D corner011 = corner001.plus(fivedeey);
    Point6D corner101 = corner001.plus(fivedeex);
    Point6D corner110 = corner010.plus(fivedeex);
    Point6D corner111 = corner011.plus(fivedeex);

    Point6D[][][] spacebounds = new Point6D[2][2][2];
    spacebounds[0][0][0] = corner000;
    spacebounds[0][0][1] = corner001;
    spacebounds[0][1][0] = corner010;
    spacebounds[1][0][0] = corner100;
    spacebounds[0][1][1] = corner011;
    spacebounds[1][0][1] = corner101;
    spacebounds[1][1][0] = corner110;
    spacebounds[1][1][1] = corner111;


    // Clear out the arrays
    cells = new ArrayList<Point6D>();
    rhombs = new ArrayList<Rhomb>();

    // Iterate over the dimension we hold constant
    for (int planeDim = 0; planeDim < 6; planeDim++) {
      // Iterate over the value at which we hold planeDim constant


      // Since all planes are just translations of one another, doing some setup before we land
      // on a specific plane:

      // Choosing an arbitrary origin for now. The slice could be various strange shapes so 
      // it's not too useful to parameterize conveniently.
      Point6D plane5Dw = new Point6D(0, 0, 0, 0, 0, 0);
      plane5Dw.point[planeDim] = 1;

      for (float planeN = planestarts[planeDim]; planeN < planeends[planeDim]; planeN += 1) {

        // We are on a plane which slices the rectangular prism which is our 3D space.

        plane5Dw.point[planeDim] = planeN;

        // Now we need to find all Voronoi cells of the 5D lattice which intersect our plane.

        // Halfway between lattice points are hyperplanes defined by having a particular half-integer value in a particular one of the five dimensions. 
        // These hyperplanes intersect our plane (the screen) in a line; five parallel sets of lines. Where these lines intersect, we're switching from 
        // one Voronoi cell to another. If we think of each line as being part of the next larger-valued cell (ie, round up when choosing nearest 
        // integer), we can start at the beginning of a line and determine which cell it's in, then walk up the line changing just one dimension at 
        // each intersection. Doing this to every line will be redundant but won't leave any cells behind... provided we remember to round down also 
        // when looking at the lines with the lowest values.

        // Such a search will find intersections between the first set of lines and the 2nd, 3rd, 4th, 5th, 6th; then intersections between the second and 
        // the 1st, 3rd, fourth, fifth, &c. &c. In order to avoid redundancy, what we need to do is only check for intersections with higher-index 
        // dimensions.

        // Gotta find the edges of our slice
        ArrayList<Point6D> planecorners = new ArrayList<Point6D>();

        // using the spacebounds array from above
        for (int firstd = 0; firstd < 2; firstd++) {
          for (int secondd = 0; secondd < 2; secondd++) {
            for (int varied = 0; varied < 3; varied++) {
              Point6D firstp = (new Point6D[]{spacebounds[0][firstd][secondd], spacebounds[firstd][0][secondd], spacebounds[firstd][secondd][0]})[varied];
              Point6D secondp = (new Point6D[]{spacebounds[1][firstd][secondd], spacebounds[firstd][1][secondd], spacebounds[firstd][secondd][1]})[varied];
              Point6D difference = secondp.minus(firstp);
              if (difference.point[planeDim] > 0) {
                Point6D intersection =  difference.times(planeN - firstp.point[planeDim]).times(1.0/difference.point[planeDim]);
                if (intersection.dot(difference) < 0 || intersection.length() > difference.length()) {
                  // Point is outside the space, do nothing.
                } else {
                  planecorners.add(intersection.plus(firstp));
                }
              }
            }
          }
        }

        // Now we have corners, but it's possible they just define e.g. a line segment. 
        // We don't want to include plane sections with no area because intersections
        // at the boundary of the space don't contribute Voronoi cells anyway.
        ArrayList<Point6D> temp = new ArrayList<Point6D>();
        for (Point6D p : planecorners) temp.add(p);
        planecorners = new ArrayList<Point6D>();
        for (Point6D p : temp) {
          boolean found = false;
          for (Point6D q : planecorners) {
            if (q.point[0] == p.point[0] && q.point[1] == p.point[1] && q.point[2] == p.point[2] && q.point[3] == p.point[3] && q.point[4] == p.point[4] && q.point[5] == p.point[5]) {
              found = true;
              break;
            }
          }
          if (!found) planecorners.add(p);
        }
        if (planecorners.size() < 3) {
          // Move on to next plane
          continue;
        }

        // OK I've got corners... what do I do with corners???
        // Could it... could it be ...? D..do I just want minima over corners?
        // I guess all I'm looking for right now is minimum values on the slice, in each higher-d dimension but planeDim.
        // O..of course they do have to be properly rounded to the needed half-integer.

        // TODO- I don't need all these values in loops where not all of them are being calculated.
        // Start values are rounded properly to give us an actual place to start
        float[] cornervals = new float[planecorners.size()];
        for (int c = 0; c < planecorners.size(); c++) {
          cornervals[c] = planecorners.get(c).point[0];
        }
        float start0 = ceil(min(cornervals)+0.5)-0.5;
        for (int c = 0; c < planecorners.size(); c++) {
          cornervals[c] = planecorners.get(c).point[1];
        }
        float start1 = ceil(min(cornervals)+0.5)-0.5;
        for (int c = 0; c < planecorners.size(); c++) {
          cornervals[c] = planecorners.get(c).point[2];
        }
        float start2 = ceil(min(cornervals)+0.5)-0.5;
        for (int c = 0; c < planecorners.size(); c++) {
          cornervals[c] = planecorners.get(c).point[3];
        }
        float start3 = ceil(min(cornervals)+0.5)-0.5;
        for (int c = 0; c < planecorners.size(); c++) {
          cornervals[c] = planecorners.get(c).point[4];
        }
        float start4 = ceil(min(cornervals)+0.5)-0.5;
        for (int c = 0; c < planecorners.size(); c++) {
          cornervals[c] = planecorners.get(c).point[5];
        }
        float start5 = ceil(min(cornervals)+0.5)-0.5;

        // End values are just a cutoff
        for (int c = 0; c < planecorners.size(); c++) {
          cornervals[c] = planecorners.get(c).point[0];
        }
        float end0 = max(cornervals);
        for (int c = 0; c < planecorners.size(); c++) {
          cornervals[c] = planecorners.get(c).point[1];
        }
        float end1 = max(cornervals);
        for (int c = 0; c < planecorners.size(); c++) {
          cornervals[c] = planecorners.get(c).point[2];
        }
        float end2 = max(cornervals);
        for (int c = 0; c < planecorners.size(); c++) {
          cornervals[c] = planecorners.get(c).point[3];
        }
        float end3 = max(cornervals);
        for (int c = 0; c < planecorners.size(); c++) {
          cornervals[c] = planecorners.get(c).point[4];
        }
        float end4 = max(cornervals);
        for (int c = 0; c < planecorners.size(); c++) {
          cornervals[c] = planecorners.get(c).point[5];
        }
        float end5 = max(cornervals);

        float[] dimstarts = {start0, start1, start2, start3, start4, start5};
        float[] dimends   = {end0, end1, end2, end3, end4, end5};
        
        

        println("Plane slices: "+(planeDim*16.6+(planeN-planestarts[planeDim])*16.6/(planeends[planeDim]-planestarts[planeDim]))+"%");
        //background((planeDim*20+(planeN-planestarts[planeDim])*20/(planeends[planeDim]-planestarts[planeDim]))*255);

        //Starting with planeDim because the other lines have been checked already back when they were planes.
        for (int N = planeDim; N < 6; N++) {
          //Skip this iteration if we're on the dimension which generated the plane.
          if (N == planeDim) continue;

          for (float dimN = dimstarts[N]; dimN <= dimends[N]; dimN += 1) {
            // We are on a line where the Nth 5D coordinate takes value dimN (and because of the plane, planeDimth coordinate takes value planeN).
            // Find where this line enters and leaves the cut.
            // "enter" and "exit" will be points in proper 5D, ie, we include the offset "plane5Dw"

            float[] enter = new float[6];
            float[] exit = new float[6];
            //float[] enter2D = new float[2];
            //float[] exit2D = new float[2];


            // We have corners to work with, not edges; strategy will be to generate the line segments between 
            // these, find intersections, and then take the extreme values.
            // TODO: Shouldn't need to use lines between all corners. Take extreme corners on either side? Corners which share some higher-D values?
            ArrayList<Point6D> intersections = new ArrayList<Point6D>();
            for (int i = 0; i < planecorners.size(); i++) {
              for (int j = i; j < planecorners.size(); j++) {
                if (i != j) {
                  // okay, segment starting at planecorners.get(i) and ending at planecorners.get(j).
                  if ((dimN <= planecorners.get(i).point[N] || dimN <= planecorners.get(j).point[N]) && (dimN >= planecorners.get(i).point[N] || dimN >= planecorners.get(j).point[N])) {
                    float dist = (dimN - planecorners.get(i).point[N])/(planecorners.get(j).point[N] - planecorners.get(i).point[N]);
                    if (dist > 0 && dist < 1) {// Intersections right on the edge don't introduce cells
                      intersections.add(planecorners.get(i).plus((planecorners.get(j).minus(planecorners.get(i))).times(dist)));
                    }
                  }
                }
              }
            }

            // If the only intersection is at a corner, we can end up with none, in which case, skip
            if (intersections.size() == 0) continue;

            // For consistency of direction, we want a convention for which side is "enter" and which "exit". Using vector [1,1,1,1,1] for direction.
            Point6D enterp = intersections.get(0);
            Point6D exitp = intersections.get(0);
            Point6D metric = new Point6D(1, 1, 1, 1, 1, 1);

            for (int i = 0; i < intersections.size(); i++) {
              if (intersections.get(i).dot(metric) < enterp.dot(metric)) enterp = intersections.get(i);
              if (intersections.get(i).dot(metric) > exitp.dot(metric)) exitp = intersections.get(i);
            }
            if (enterp == exitp) {
              metric = intersections.get(0).minus(intersections.get(intersections.size()-1));
              for (int i = 0; i < intersections.size(); i++) {
                if (intersections.get(i).dot(metric) < enterp.dot(metric)) enterp = intersections.get(i);
                if (intersections.get(i).dot(metric) > exitp.dot(metric)) exitp = intersections.get(i);
              }
            }

            // TODO do something about bad metric instead of just raising an exception.
            // A viable alternative would be to choose the two intersection points maximally
            // distant from one another. Can I do without the "metric" thing entirely?


          assert enterp != exitp : 
            "Unable to determine entry/exit. Bad metric?";


            enter = enterp.copy().point;
            exit = exitp.copy().point;
            //enter2D = twodee.project(enterp.minus(plane5Dw)).point;
            //exit2D = twodee.project(exitp.minus(plane5Dw)).point;

            // Next we need to find all crossing-points between 'enter' and 'exit'. These are just half-integer values of any of the four non-fixed dimensions; 
            // but for each one we need to note how far along our line it occurs. Each crossing point tells us a particular cell does intersect our plane, and 
            // is adjacent (shares a face) with the previous cell. (Really, each crossing point exhibits eight cells which intersect our 3D space and twelve 
            // adjacencies.)


            float[] linevector = {exit[0]-enter[0], exit[1]-enter[1], exit[2]-enter[2], exit[3]-enter[3], exit[4]-enter[4], exit[5]-enter[5]};

            //ArrayList<Point2D> distsanddims = new ArrayList<Point2D>();
            ArrayList<Float> dists = new ArrayList<Float>();
            ArrayList<Integer> dims = new ArrayList<Integer>();

            // Starting at d = 0. At one point I was silly and started at d = N.
            // We have to use d = 0 because we inherently want to catch old crossings.
            // TODO could we record old crossings and use them to start at d = N and
            // be more efficient? What we need for this is to create all the "dists"
            // lists right away, and whenever we find a crossing, add it to both our
            // current dimension's list and the other one's. However, it does need 
            // to all be sorted by which values both lines take on (as well as the 
            // plane) so that we can then quickly find them right before this for 
            // loop and add them to dists/dims. And we don't know ahead of time
            // what all the values that will be fixed are - though we do know bounds.
            for (int d = 0; d < 6; d++) {
              if (d != N && d != planeDim) {
                // We want to catch any included half-integer values, so we'll subtract 0.5 and take all integer values of that range.
                for (int i = ceil(min(enter[d], exit[d])-0.5); i <= max(enter[d], exit[d])-0.5; i++) {//I changed from floor to ceil here. We don't want an intersection which isn't onscreen.//TODO This change fixed stuff but I don't see why it did! Reverse engineer bug!!
                  float dist = ((float(i)+0.5)-(enter[d]))/linevector[d];
                  dists.add(dist);
                  dims.add(d);
                }
              }
            }

            // Then sort crossings by how far along they occur.

            if (dists.size() != 0) {
              float[] distsarray = new float[dists.size()];
              int index = 0;
              for (Float d : dists) {
                distsarray[index] = d;
                index++;
              }
              ArrayList<Float> dists2 = new ArrayList<Float>(dists);
              java.util.Collections.sort(dists2);
              float[] sorteddists = new float[dists.size()];
              index = 0;
              for (Float d : dists2) {
                sorteddists[index] = d;
                index ++;
              }
              int[] sorteddims = new int[dists.size()];
              int[] dimsarray = new int[dims.size()];
              index = 0;
              for (Integer d : dims) {
                dimsarray[index] = d;
                index++;
              }

              for (int i = 0; i < dists2.size(); i++) {
                for (int j = 0; j < dists.size(); j++) {
                  if (distsarray[j] == sorteddists[i]) {
                    sorteddims[i] = dimsarray[j];
                  }
                }
              }

              // Then step through each one, iterating the associated dimension in the correct direction to get the right latticepoint.


              // We step through with four cells; below vs. above the current plane, and to either side of the current line.
              Point6D left_downCell = new Point6D(round(enter[0]), round(enter[1]), round(enter[2]), round(enter[3]), round(enter[4]), round(enter[5]));
              // We have to add or subtract a bit to ensure we fall the desired direction for each starting cell. 
              left_downCell.point[N] = round(enter[N]+0.01);
              left_downCell.point[planeDim] = round(enter[planeDim]-0.01);

              Point6D right_downCell = new Point6D(round(enter[0]), round(enter[1]), round(enter[2]), round(enter[3]), round(enter[4]), round(enter[5]));
              right_downCell.point[N] = round(enter[N]-0.01);
              right_downCell.point[planeDim] = round(enter[planeDim]-0.01);

              Point6D left_upCell = new Point6D(round(enter[0]), round(enter[1]), round(enter[2]), round(enter[3]), round(enter[4]), round(enter[5]));
              left_upCell.point[N] = round(enter[N]+0.01);
              left_upCell.point[planeDim] = round(enter[planeDim]+0.01);

              Point6D right_upCell = new Point6D(round(enter[0]), round(enter[1]), round(enter[2]), round(enter[3]), round(enter[4]), round(enter[5]));
              right_upCell.point[N] = round(enter[N]-0.01);
              right_upCell.point[planeDim] = round(enter[planeDim]+0.01);


              // TODO Would it be beneficial to weed out repetition in the
              // list of cells? Cells don't track their parent rhombuses right
              // now and I'm not sure they should; right now I basically
              // don't use the cells ArrayList for anything.
              // It would also allow me to cache the cells' 3D coordinates (that
              // is, the 3D coordinates of each vertex) without repetition.
              // The cells could be of a class that only allows integer coordinates,
              // which would reduce risk of error.
              cells.add(left_downCell);
              cells.add(right_downCell);
              cells.add(left_upCell);
              cells.add(right_upCell);

              //println("generating cells... "+N*20+round((dimN-dimstarts[N])/(dimends[N]-dimstarts[N]))+"%");

              for (int i = 0; i < dists.size(); i++) {
                //TODO If we cross several lines at once, this is the place to deal with it.
                // They would have the same "dist" value (give or take floating point error) and
                // would be sorted to be adjacent. Crossing those intersections in every possible
                // order ought to generate all the vertices of the desired shape. It's interesting
                // to picture those different Conway worms... I suppose the vertices which are
                // actually part of the tiling are produced by finding the cells which actually
                // fall within our 3D surface. Rather than crossing the lines in a specific order,
                // these would be found by having the left cells cross in a different order from 
                // the right cells, all according to the order the lines cross our plane. For example:
                //                               \       |       /                                  
                //                                \      |      /                                   
                //                                 \     |     /                                    
                //                                  \    |    /                                     
                //                                   \   |   /                                      
                //                                    \  |  /                                       
                //                                     \ | /                                        
                //                                      \|/                                         
                // --------------------------------------*------------------------------------------
                //                                      /|\                                         
                //                                     / | \                                        
                //                                    /  |  \                                       
                //                                   /   |   \                                      
                //                                  /    |    \                                     
                //                                 /     |     \                                    
                //                                /      |      \                                   
                //                               /       | ^     \                                  
                //                              /        | |      \                                  
                // If we are moving upwards along the vertical line ("|"), on the left side we need to 
                // cross "/", then "-", then "\". But on the right side, we cross "\", then "-", then "/".
                // What about up vs. down? Well, I guess they just get grouped by left and right. These 
                // sixteen Voronoi cells indeed intersect our space and generate those vertices; and the 
                // vertices are connected in the way which this crossing order suggests.
                // In this specific example (with 4 lines crossing), 
                /*if (i+1 < dists.size() && abs(dists.get(i) - dists.get(i+1)) < 0.01) {
                 println("Possible double-cross. Difference was "+(dists.get(i) - dists.get(i+1)));
                 println("Dimensions: "+dims.get(i)+", "+dims.get(i+1));
                 }*/

                int dim = sorteddims[i];
                int dir = enter[dim] < exit[dim] ? 1 : -1;

                Point6D oldLeftDownCell = left_downCell;
                Point6D oldRightDownCell = right_downCell;
                Point6D oldLeftUpCell = left_upCell;
                Point6D oldRightUpCell = right_upCell;

                //TODO Floating point error could build up as I add and subtract integers here; could be better off using integers.
                left_downCell = left_downCell.copy();
                right_downCell = right_downCell.copy();
                left_upCell = left_upCell.copy();
                right_upCell = right_upCell.copy();
                left_downCell.point[dim] += 1*dir;
                right_downCell.point[dim] += 1*dir;
                left_upCell.point[dim] += 1*dir;
                right_upCell.point[dim] += 1*dir;

                //Point6D newintersection = enterp.plus((exitp.minus(enterp)).times(sorteddists[i]));
                /*println(oldLeftDownCell.minus(newintersection).length());
                 println(oldRightDownCell.minus(newintersection).length());
                 println(oldLeftUpCell.minus(newintersection).length());
                 println(oldRightUpCell.minus(newintersection).length());
                 println(left_downCell.minus(newintersection).length());
                 println(right_downCell.minus(newintersection).length());
                 println(left_upCell.minus(newintersection).length());
                 println(right_upCell.minus(newintersection).length());*/

                // TODO Would it be beneficial to weed out repetition in the
                // list of cells? Cells don't track their parent rhombuses right
                // now and I'm not sure they should; right now I basically
                // don't use the cells ArrayList for anything.
                // I could be using cells to track intersections (ie, dists)
                // and stop computing them all three times as I currently do.
                //cells.add(left_downCell);
                //cells.add(right_downCell);
                //cells.add(left_upCell);
                //cells.add(right_upCell);

                // Our eight cell-centers define a parallelepiped (of course in 5D it's a cube). In dim N, the left cells 
                // lie in the positive direction from the right. In planeDim, the up cells lie in the positive direction 
                // from the down.
                // In dim "dim", the new cells lie in the "dir" direction from the old.
                // We want to note the parallelepiped, and order the corners according to a convention:
                //Point6D corner1;//negative in both axes; (-.5,-.5)
                //Point6D corner2;//(-.5,.5)
                //Point6D corner3;//(.5,-.5)
                //Point6D corner4;//(.5,.5)
                // Actually can't use "dir". Gotta use the arbitrary score of the line we're crossing
                /*Point6D xconst = new Point6D(fivedee0).times(1.0/fivedee0[dim]);
                 Point6D yconst = new Point6D(fivedee1).times(1.0/fivedee1[dim]);
                 float dir3 = xconst.dot(metric) < yconst.dot(metric) ? 1 : -1;
                 float dir4 = xconst.point[N] < yconst.point[N] ? 1 : -1;
                 Point6D unit = new Point6D(new float[]{0, 0, 0, 0, 0});
                 unit.point[dim]=dir;*/
                //Rhomb rhomb = (dir3*dir4 > 0) ? new Rhomb(oldRightCell, oldLeftCell, rightCell, leftCell) : new Rhomb(oldLeftCell, oldRightCell, leftCell, rightCell);
                //Rhomb rhomb = (dir3 > 0) ? new Rhomb(oldRightCell, oldLeftCell, rightCell, leftCell) : new Rhomb(rightCell, leftCell, oldRightCell, oldLeftCell);

                // Actually for now I'm going to ignore all that and do completely arbitrary directions.
                // I'll try and fix it if it turns out those conventions still matter.
                // TODO would just provide nice next/prev distinction.

                ArrayList<Point6D> the_others = new ArrayList<Point6D>();
                the_others.add(left_upCell);// this is so many lines. how do i write it better
                the_others.add(right_downCell);
                the_others.add(right_upCell);
                the_others.add(oldLeftDownCell);
                the_others.add(oldRightDownCell);
                the_others.add(oldLeftUpCell);
                the_others.add(oldRightUpCell);
                Block block = new Block(left_downCell.averageWith(the_others));
                /*Want to initialize:
                 ArrayList<Integer> axes;
                 ArrayList<Block> prev;
                 ArrayList<Block> next;
                 ArrayList<Rhomb> sides;
                 */

                // I'm going to skip determination of prev and next for now, as well as skip properly 
                // initializing axis1 and axis2 for the individual rhombuses.
                
                // TODO This part would be faster if I had the blocks
                // in some sort of data structure so they could be
                // found. non-exhaustively.
                boolean blockregistered = false;
                Block prev;
                for (Block b : blocks) {
                  Point6D difference = b.center.minus(block.center);
                  float maxdivergence = max(new float[]{abs(difference.point[0]), abs(difference.point[1]), abs(difference.point[2]), abs(difference.point[3]), abs(difference.point[4]), abs(difference.point[5])});
                  if (maxdivergence < tolerance) {
                    blockregistered = true;
                    prev = b;
                    break;
                  }
                }
                if (!blockregistered) {
                  blocks.add(block);
                  // This ordering of the axes - (N, planeDim, dim) - will be used when interpreting prev and next.
                  block.axes = new ArrayList<Integer>(java.util.Arrays.asList(new Integer[]{N, planeDim, dim}));
                  block.sides.add(new Rhomb(oldLeftDownCell.copy(), oldRightDownCell.copy(), oldLeftUpCell.copy(), oldRightUpCell.copy()));// old face
                  block.sides.add(new Rhomb(oldLeftDownCell.copy(), left_downCell.copy(), oldLeftUpCell.copy(), left_upCell.copy()));// left face
                  block.sides.add(new Rhomb(right_downCell.copy(), left_downCell.copy(), right_upCell.copy(), left_upCell.copy()));// new face
                  block.sides.add(new Rhomb(right_downCell.copy(), oldRightDownCell.copy(), right_upCell.copy(), oldRightUpCell.copy()));// right face
                  block.sides.add(new Rhomb(oldLeftUpCell.copy(), oldRightUpCell.copy(), left_upCell.copy(), right_upCell.copy()));// up face
                  block.sides.add(new Rhomb(oldLeftDownCell.copy(), oldRightDownCell.copy(), left_downCell.copy(), right_downCell.copy()));// down face
                  for (int side = 0; side < block.sides.size(); side++) {
                    // I probably spend a whole lot of my time checking for duplicate rhombs.
                    // Should store them in a searchable way.
                    boolean rhombregistered = false;
                    // Rather than tracking direction and next vs. prev,
                    // for now I'm just going to rely on rhombs' ordering in "sides"
                    // lining up with neighboring blocks' ordering in "next".
                    for (Rhomb rh : rhombs) {
                      Point6D difference = block.sides.get(side).center.minus(rh.center);
                      float maxdivergence = max(new float[]{abs(difference.point[0]), abs(difference.point[1]), abs(difference.point[2]), abs(difference.point[3]), abs(difference.point[4]), abs(difference.point[5])});
                      if (maxdivergence < tolerance) {
                        // Rhombus already exists.
                        block.sides.set(side, rh);
                        // Rhombus must have one parent.
                        Block neighbor = rh.parents.get(0);
                        block.next.add(neighbor);
                        neighbor.next.set(neighbor.sides.indexOf(rh), block);
                        rh.parents.add(block);
                        rhombregistered = true;
                        break;
                      }
                    }
                    if (!rhombregistered) {
                      rhombs.add(block.sides.get(side));
                      // Keep lists even w/ null elements
                      block.next.add(null);
                      block.sides.get(side).parents.add(block);
                    }
                  }
                }

                /*for (Rhomb face : block.sides) {
                  PVector corner1_3D = new PVector(face.corner1.minus(fivedeew).dot(fivedee0), face.corner1.minus(fivedeew).dot(fivedee1), face.corner1.minus(fivedeew).dot(fivedee2));
                  PVector corner2_3D = new PVector(face.corner2.minus(fivedeew).dot(fivedee0), face.corner2.minus(fivedeew).dot(fivedee1), face.corner2.minus(fivedeew).dot(fivedee2));
                  PVector corner3_3D = new PVector(face.corner3.minus(fivedeew).dot(fivedee0), face.corner3.minus(fivedeew).dot(fivedee1), face.corner3.minus(fivedeew).dot(fivedee2));
                  PVector corner4_3D = new PVector(face.corner4.minus(fivedeew).dot(fivedee0), face.corner4.minus(fivedeew).dot(fivedee1), face.corner4.minus(fivedeew).dot(fivedee2));
                  beginShape();
                  vertex(corner1_3D.x, corner1_3D.y, corner1_3D.z);
                  vertex(corner2_3D.x, corner2_3D.y, corner2_3D.z);
                  vertex(corner3_3D.x, corner3_3D.y, corner3_3D.z);
                  vertex(corner4_3D.x, corner4_3D.y, corner4_3D.z);
                  endShape(CLOSE);
                }*/
              }
            }
          }
        }
      }
    }
  }
}

class Block {
  ArrayList<Integer> axes;
  ArrayList<Block> prev;
  ArrayList<Block> next;
  ArrayList<Rhomb> sides;
  ArrayList<Chunk> parents;
  Point6D center;
  int value;
  int nextValue;

  public Block(Point6D p) {
    axes = new ArrayList<Integer>();
    prev = new ArrayList<Block>();
    next = new ArrayList<Block>();
    sides = new ArrayList<Rhomb>();
    center = p;
    value = 0;
    nextValue = -1;

    // TODO I'd like to have dummy values for the four "prev" and "next"
    // variables, as well as for the "parents", representing "that hasn't
    // been generated yet". When something requests the dummy, it could 
    // then be generated in.
  }
}

public class Point6D {
  public float[] point = {0, 0, 0, 0, 0, 0};

  public Point6D (float a, float b, float c, float d, float e, float f) {
    point = new float[]{a, b, c, d, e, f};
  }

  public Point6D (float[] p) {
    point = p;
  }

  public Point6D minus(Point6D p) {
    return new Point6D(point[0]-p.point[0], point[1]-p.point[1], point[2]-p.point[2], point[3]-p.point[3], point[4]-p.point[4], point[5]-p.point[5]);
  }

  public Point6D plus(Point6D p) {
    return new Point6D(point[0]+p.point[0], point[1]+p.point[1], point[2]+p.point[2], point[3]+p.point[3], point[4]+p.point[4], point[5]+p.point[5]);
  }

  public float dot(Point6D p) {
    return point[0]*p.point[0]+point[1]*p.point[1]+point[2]*p.point[2]+point[3]*p.point[3]+point[4]*p.point[4]+point[5]*p.point[5];
  }

  public Point6D times(float scalar) {
    return new Point6D(point[0]*scalar, point[1]*scalar, point[2]*scalar, point[3]*scalar, point[4]*scalar, point[5]*scalar);
  }

  public float length() {
    return sqrt(point[0]*point[0]+point[1]*point[1]+point[2]*point[2]+point[3]*point[3]+point[4]*point[4]+point[5]*point[5]);
  }

  public Point6D normalized() {
    float currentLength = length();
    return new Point6D(point[0]/currentLength, point[1]/currentLength, point[2]/currentLength, point[3]/currentLength, point[4]/currentLength, point[5]/currentLength);
  }

  public Point6D ortho(Point6D p) {
    // Returns the component which is orthogonal to p
    Point6D pnorm = p.normalized();
    float dotprod = dot(pnorm);
    return new Point6D(point[0]-dotprod*pnorm.point[0], point[1]-dotprod*pnorm.point[1], point[2]-dotprod*pnorm.point[2], point[3]-dotprod*pnorm.point[3], point[4]-dotprod*pnorm.point[4], point[5]-dotprod*pnorm.point[5]);
  }

  public Point6D averageWith(ArrayList<Point6D> points) {
    Point6D sum = new Point6D(new float[]{point[0], point[1], point[2], point[3], point[4], point[5]});
    for (Point6D p : points) {
      sum = sum.plus(p);
    }
    sum = sum.times(1.0/(points.size()+1));
    return sum;
  }

  public Point6D copy() {
    return new Point6D(new float[]{point[0], point[1], point[2], point[3], point[4], point[5]});
  }
  
  public Point6D abs() {
    return new Point6D(new float[]{Math.abs(point[0]), Math.abs(point[1]), Math.abs(point[2]), Math.abs(point[3]), Math.abs(point[4]), Math.abs(point[5])});
  }
}

class Point2D implements Comparable<Point2D> {

  public java.util.Comparator<Point2D> Lexico = new java.util.Comparator<Point2D>() {

    @Override
      public int compare(Point2D a, Point2D b) {
      if (a.point[0] > b.point[0]) {
        return 1;
      }
      if (a.point[0] < b.point[0]) {
        return -1;
      }
      if (a.point[1] > b.point[1]) {
        return 1;
      }
      if (a.point[1] < b.point[1]) {
        return -1;
      }
      return 0;
    }
  };
  public float[] point = {0, 0};


  public Point2D(float x, float y) {
    point = new float[]{x, y};
  }

  public Point2D(float[] p) {
    point = new float[]{p[0], p[1]};
  }

  public float dot(Point2D p) {
    return point[0]*p.point[0]+point[1]*p.point[1];
  }

  public Point2D minus(Point2D p) {
    return new Point2D(point[0]-p.point[0], point[1]-p.point[1]);
  }

  public float length() {
    return sqrt(point[0]*point[0]+point[1]*point[1]);
  }

  public int compareTo(Point2D p) {
    if (point[0] > p.point[0]) {
      return 1;
    }
    if (point[0] < p.point[0]) {
      return -1;
    }
    if (point[1] > p.point[1]) {
      return 1;
    }
    if (point[1] < p.point[1]) {
      return -1;
    }
    return 0;
  }

  public float x() {
    return point[0];
  }

  public float y() {
    return point[1];
  }

  public Point2D orthoflip() {
    return new Point2D(point[1], -point[0]);
  }

  public Point2D copy() {
    return new Point2D(new float[]{point[0], point[1]});
  }
}

class Rhomb {
  int axis1;
  int axis2;
  ArrayList<Block> parents;
  Rhomb a1prev;
  Rhomb a1next;
  Rhomb a2prev;
  Rhomb a2next;
  Point6D corner1;//negative in both axes; (-.5,-.5)
  Point6D corner2;//(-.5,.5)
  Point6D corner3;//(.5,-.5)
  Point6D corner4;//(.5,.5)
  Point6D center;
  int value;
  int nextValue;

  // 3D cache
  PVector corner1_3D;
  PVector corner2_3D;
  PVector corner3_3D;
  PVector corner4_3D;
  PVector center_3D;

  public Rhomb(Point6D c1, Point6D c2, Point6D c3, Point6D c4) {
    corner1 = c1;
    corner2 = c2;
    corner3 = c3;
    corner4 = c4;
    center = (c1.plus(c2.plus(c3.plus(c4)))).times(0.25);
    a1prev = null;
    a2prev = null;
    a1next = null;
    a2next = null;
    parents = new ArrayList<Block>();
  }
}