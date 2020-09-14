/********************************************** //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>//
 *
 * Implements a 3D quasicrystal tiling within 
 * given rectangular bounds.
 *
 * Daniel Demski
 *
 **********************************************/

// TODO want different grids easily available to construct.
public class Quasicrystal {
  // Radius determines side length of cube, so how many
  // be found scales as its cube.
  float radius = 4;
  // Tolerance is used when checking whether two vertices are equal.
  float tolerance = 0.0001;

  Point6D fivedeex = new Point6D(new float[]{random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1)});
  Point6D fivedeey = new Point6D(new float[]{random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1)});
  Point6D fivedeez = new Point6D(new float[]{random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1)});
  Point6D fivedeew = new Point6D(new float[]{random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1)});
  Point6D fivedee0 = new Point6D(new float[]{0, 0, 0, 0, 0, 0});
  Point6D fivedee1 = new Point6D(new float[]{0, 0, 0, 0, 0, 0});
  Point6D fivedee2 = new Point6D(new float[]{0, 0, 0, 0, 0, 0});

  VertexStore cells = new VertexStore(tolerance);
  //ArrayList<Rhomb> rhombs = new ArrayList<Rhomb>();
  RhombStore rhombs = new RhombStore(tolerance);
  //ArrayList<Block> blocks = new ArrayList<Block>();
  BlockStore blocks = new BlockStore(tolerance);
  PointStore intersections = new PointStore(tolerance);

  public Quasicrystal(Point6D w, Point6D x, Point6D y, Point6D z, float r) {
    // x, y, and z can be non-orthogonal and non-unit.
    fivedeex = x.copy();
    fivedeey = y.copy();
    fivedeez = z.copy();
    fivedeew = w.copy();
    radius = r;
    // these are the actual basis vectors: (making them orthogonal)
    //fivedee0 = fivedeex.normalized();
    //fivedee1 = fivedeey.ortho(fivedee0).normalized();
    //fivedee2 = fivedeez.ortho(fivedee0).ortho(fivedee1).normalized();
    //Old version insisted orthonormal. If we're going to allow skew, want neither.
    fivedee0 = fivedeex.copy();
    fivedee1 = fivedeey.copy();
    fivedee2 = fivedeez.copy();

    // We then make our original vectors line up to these.
    // Sizes here determine bounded area of the render.
    fivedeex = fivedee0.times(radius);
    fivedeey = fivedee1.times(radius);
    fivedeez = fivedee2.times(radius);

    // Now we need to iterate over all the planes which fall inside our space, checking for intersections.

    // Big TODO item: Everywhere code looks repetitive (e.g., has one line per dimension), make it less repetitive.
    // Very related TODO: Make code agnostic to number of dimensions (ie, 5 vs 6).

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

    // TODO Come up with some assertions here

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
    // TODO Might be more efficient to use lower tolerance on some of these?
    cells = new VertexStore(tolerance);
    rhombs = new RhombStore(tolerance);
    blocks = new BlockStore(tolerance);
    intersections = new PointStore(0);// High tolerance is important here

    // Iterate over the dimension we hold constant
    for (int planeDim = 0; planeDim < 6; planeDim++) {
      // Iterate over the value at which we hold planeDim constant

      // Strict comparison because values on the boundary don't contribute cells.
      for (float planeLoc = planestarts[planeDim]; planeLoc < planeends[planeDim]; planeLoc += 1) {

        // We are on a plane which slices the rectangular prism which is our 3D space.

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
                Point6D intersection =  difference.times(planeLoc - firstp.point[planeDim]).times(1.0/difference.point[planeDim]);
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



        println("Plane slices: "+(planeDim*16.6+(planeLoc-planestarts[planeDim])*16.6/(planeends[planeDim]-planestarts[planeDim]))+"%");
        //background((planeDim*20+(planeN-planestarts[planeDim])*20/(planeends[planeDim]-planestarts[planeDim]))*255);

        //Starting with planeDim because the other lines have been checked already back when they were planes.
        //for (int lineDim = 0; lineDim < 6; lineDim++) {
        for (int lineDim = planeDim; lineDim < 6; lineDim++) {
          //Skip this iteration if we're on the dimension which generated the plane.
          if (lineDim == planeDim) continue; //Should end up skipped automatically TODO does that make sense

          // Requiring strict lineLoc < dimends[lineDim] because an intersection at the very edge won't contribute cells. (Was lineLoc <= dimends[lineDim] for a long time)
          for (float lineLoc = dimstarts[lineDim]; lineLoc < dimends[lineDim]; lineLoc += 1) {
            // We are on a line where the Nth 5D coordinate takes value dimN (and because of the plane, planeDimth coordinate takes value planeN).
            // Find where this line enters and leaves the cut.
            // "enter" and "exit" will be points in proper 5D, ie, we include the offset "plane5Dw"

            float[] enter = new float[6];
            float[] exit = new float[6];


            // We have corners to work with, not edges; strategy will be to generate the line segments between 
            // these, find intersections, and then take the extreme values.
            // TODO: Shouldn't need to use lines between all corners. Take extreme corners on either side? Corners which share some higher-D values?
            ArrayList<Point6D> segment_intersections = new ArrayList<Point6D>();
            for (int i = 0; i < planecorners.size(); i++) {
              for (int j = i; j < planecorners.size(); j++) {
                if (i != j) {
                  // okay, segment starting at planecorners.get(i) and ending at planecorners.get(j).
                  if ((lineLoc <= planecorners.get(i).point[lineDim] || lineLoc <= planecorners.get(j).point[lineDim]) && (lineLoc >= planecorners.get(i).point[lineDim] || lineLoc >= planecorners.get(j).point[lineDim])) {
                    float dist = (lineLoc - planecorners.get(i).point[lineDim])/(planecorners.get(j).point[lineDim] - planecorners.get(i).point[lineDim]);
                    if (dist > 0 && dist < 1) {// Intersections right on the edge don't introduce cells
                      segment_intersections.add(planecorners.get(i).plus((planecorners.get(j).minus(planecorners.get(i))).times(dist)));
                    }
                  }
                }
              }
            }

            // If the only intersection is at a corner, we can end up with none, in which case, skip
            if (segment_intersections.size() == 0) continue;


            Point6D segenterp = segment_intersections.get(0);
            Point6D segexitp = segment_intersections.get(0);

            for (int i = 0; i < segment_intersections.size(); i++) {
              if (segment_intersections.get(i).minus(segenterp).length() > segexitp.minus(segenterp).length()) segexitp = segment_intersections.get(i);
            }
            for (int i = 0; i < segment_intersections.size(); i++) {
              if (segment_intersections.get(i).minus(segexitp).length() > segexitp.minus(segenterp).length()) segenterp = segment_intersections.get(i);
            }
            if (test_assertions) {
              for (int i = 0; i < segment_intersections.size(); i++) {
                assert (segment_intersections.get(i).minus(segenterp).length() <= segexitp.minus(segenterp).length()) :
                "First run of finding opposite entry/exit points failed.";
                assert (segment_intersections.get(i).minus(segexitp).length() <= segexitp.minus(segenterp).length()) :
                "First run of finding opposite entry/exit points failed.";
              }
            }

            /* TODO Make the below code work and then run it as a double-check?
             Point6D enterp = segment_intersections.get(0);
             Point6D exitp = segment_intersections.get(0);
             Point6D metric = new Point6D(1, 1, 1, 1, 1, 1);
             for (int i = 0; i < segment_intersections.size(); i++) {
             if (segment_intersections.get(i).dot(metric) < enterp.dot(metric)) enterp = segment_intersections.get(i);
             if (segment_intersections.get(i).dot(metric) > exitp.dot(metric)) exitp = segment_intersections.get(i);
             }
             if (enterp == exitp) {
             metric = segment_intersections.get(0).minus(segment_intersections.get(segment_intersections.size()-1));
             for (int i = 0; i < segment_intersections.size(); i++) {
             if (segment_intersections.get(i).dot(metric) < enterp.dot(metric)) enterp = segment_intersections.get(i);
             if (segment_intersections.get(i).dot(metric) > exitp.dot(metric)) exitp = segment_intersections.get(i);
             }
             }
             assert (enterp.minus(exitp).length() == segenterp.minus(segexitp).length()): 
             "Failed to pick maximally distant entrance and exit. Difference was "+(enterp.minus(exitp).length() - segenterp.minus(segexitp).length());
             */


          assert segenterp != segexitp : 
            "Unable to determine entry/exit. Bad metric?";

            // For consistency of direction, we want a convention for which side is "enter" and which "exit". Using vector [1,1,1,1,1] for direction.
            Point6D metric = new Point6D(1, 1, 1, 1, 1, 1);
            if (segenterp.dot(metric) > segexitp.dot(metric)) {
              Point6D tempp = segenterp.copy();
              segenterp = segexitp;
              segexitp = tempp;
            }

            // TODO segenterp and segexitp appear to work; reinstate once code regains basic function.
            enter = segenterp.copy().point;
            exit = segexitp.copy().point;
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

            // Starting at d = 0. At one point I was silly and started at d = lineDim.
            // We have to use d = 0 because we inherently want to catch old crossings.
            // TODO could we record old crossings and use them to start at d = N and
            // be more efficient? What we need for this is to create all the "dists"
            // lists right away, and whenever we find a crossing, add it to both our
            // current dimension's list and the other one's. However, it does need 
            // to all be sorted by which values both lines take on (as well as the 
            // plane) so that we can then quickly find them right before this for 
            // loop and add them to dists/dims. And we don't know ahead of time
            // what all the values that will be fixed are - though we do know bounds.
            // TODO Write an actual fetch method that could do this so that tolerance 
            // can be factored in. Ideally what we want is for incomplete queries to 
            // return a new PointStore object so that our queries can be chained
            // together.
            /* TODO MEMORY MECHANISM find out why this doesn't work
             // It seems the relationship between remembered intersections and the current dist loop
             // is complex. I want to note cases of double-cross, since some grids make use of 
             // those. Yet I don't want to double count crossings (for the same reason of course).
             // So I can't let the PointStore object do the work of eliminating duplicates.
             // Most of this is taken care of by starting at d = lineDim instead of d = 0, but
             // ... well, I'm getting errors further down the line when I make the switch,
             // Next step, I suppose, is adding a check for whether the points are near-identical,
             // in the place where I currently test for number of remembered intersections.
             ArrayList<Float> pre_N_dists = new ArrayList<Float>();
             ArrayList<Float> memory_dists = new ArrayList<Float>();
             ArrayList<Integer> pre_N_dims = new ArrayList<Integer>();
             ArrayList<Integer> memory_dims = new ArrayList<Integer>();
             ArrayList<Point6D> line_pre_N = new ArrayList<Point6D>();
             ArrayList<Point6D> onOurPlane = new ArrayList<Point6D>();
             if (intersections.storage[planeDim].get(planeLoc) != null) onOurPlane = (ArrayList<Point6D>)(intersections.storage[planeDim].get(planeLoc));
             ArrayList<Point6D> onOurOtherPlane = new ArrayList<Point6D>();
             if (intersections.storage[lineDim].get(lineLoc) != null) onOurOtherPlane = (ArrayList<Point6D>)(intersections.storage[lineDim].get(lineLoc));
             ArrayList<Point6D> line_memory = new ArrayList<Point6D>();
             for (Point6D p : onOurPlane) {
             if (onOurOtherPlane.contains(p)) {
             // p is on our line
             line_memory.add(p);
             }
             }
             for (Point6D p : line_memory) {
             assert p.minus(segenterp).ortho(new Point6D(linevector)).length() < 0.01: 
             "Point p is off the line by "+p.minus(segenterp).ortho(new Point6D(linevector)).length();
             int dim = -1;
             for (int check_d = 0; check_d < 6; check_d++) {
             if (check_d != lineDim && check_d != planeDim && (p.point[check_d] - floor(p.point[check_d]) == 0.5)) {
             // There should only be one dimension like this
             assert dim == -1 : 
             "Double-cross in intersection history. Dunno how to split it up. Teach me how.";
             dim = check_d;
             }
             }
             float dist = -1;
             for (int check_d = 0; check_d < 6; check_d++) {
             if (check_d != lineDim && check_d != planeDim && check_d != dim) {
             float this_dist = (p.point[check_d] - enter[check_d])/linevector[check_d];
             assert this_dist > 0 && this_dist < 1.0 : 
             "new dist value exceeded range";
             if (test_assertions && dist > 0) {
             // Asserting that all ways of calculating dist are same to high tolerance
             assert abs(dist - this_dist) < tolerance : 
             "Wrong about distance math. Got "+dist+" and "+this_dist;
             }
             dist = this_dist;
             if (!test_assertions) break;
             }
             }
             //float dist = p.minus(new Point6D(enter)).length()/(new Point6D(linevector)).length();
             memory_dists.add(dist);
             memory_dims.add(dim);
             }*/
            // Okay, trying this out with initialization d=N; above code should catch old lower-d intersections.
            for (int d = 0; d < 6; d++) {
              /*for (int d = lineDim; d < 6; d++) {// Part of MEMORY MECHANISM tests
               if (d == lineDim) {
               // Check that things are adding up so far
               assert dists.size() == memory_dists.size(): 
               "Remembered "+(memory_dists.size()-dists.size())+" more intersections than were calculated.";
               }*/
              if (d != lineDim && d != planeDim) {
                // We want to catch any included half-integer values, so we'll subtract 0.5 and take all integer values of that range.
                // TODO Suppose enter[d] is 1.5, and that makes i = 1.0. We'll be including a transition which is right on the
                // edge of our window, which we don't really want to do. Adding 1 and taking the floor pushes i up to 2.0, which seems
                // like the right thing; yet the comment below warns about problems when I was using floor. Right now it seems to crash either
                // way, but only when I have certain non-orthogonal choices of x, y, z.
                for (int i = ceil(min(enter[d], exit[d])-0.5); i <= max(enter[d], exit[d])-0.5; i++) {//I changed from floor to ceil here. We don't want an intersection which isn't onscreen.//TODO This change fixed stuff but I don't see why it did! Reverse engineer bug!!
                  // We measure dist from enter[d] since linevector is measured from that point.
                  float dist = ((float(i)+0.5)-(enter[d]))/linevector[d];
                assert dist > 0 && dist < 1 : 
                  "Distance to crossing outside of expected range; dist = "+dist; //<>//
                  dists.add(dist);
                  dims.add(d);
                  // TODO I'm adding math here. Is this new storage system actually speeding anything up?
                  // Theoretically I could be cleverer and only store the math done already 
                  // (ie, store enter, linevector, planeDim, N, d, dist, and dim). On the other hand maybe
                  // all math I'm doing here would get done later anyway? No - whenever j < N I think
                  // I'm doing unneeded work.
                  // Also note how the dists are not ever used after sorting them. They only need to be
                  // accurate enough to produce the ordering of the crossings. Can that be leveraged?
                  // TODO If no new storage system, still want some assertions of that sort.
                  /* part of MEMORY MECHANISM
                   Point6D intersection = new Point6D(0, 0, 0, 0, 0, 0);
                   intersection.point[planeDim] = planeLoc;
                   intersection.point[lineDim] = lineLoc;
                   intersection.point[d] = i+0.5;
                   for (int j = 0; j < 6; j++) {
                   if (j != planeDim && j != lineDim && j != d) {
                   intersection.point[j] = enter[j] + linevector[j]*dist;
                   }
                   }
                   
                   if (test_assertions) {
                   if (d < lineDim && line_memory.size() > 0) {// part of MEMORY MECHANISM tests
                   line_pre_N.add(segenterp.plus(new Point6D(linevector).times(dist)));
                   //intersections.add(segenterp.plus(new Point6D(linevector).times(dist)));
                   }
                   Point6D prev_intersection = intersections.get(intersection);
                   assert(!intersections.contains(intersection)) : 
                   "PointStore object thinks it already has the intersection; so-called previous copy off by "+prev_intersection.minus(intersection).length();
                   assert(intersection.minus(segenterp.plus(new Point6D(linevector).times(dist))).length() < 0.001) :
                   "Frugal intersection calculation failed";
                   // intersection as calculated ought to be on our line and in our 3D space.
                   //println("d: "+d+" N: "+N+" planeDim: "+planeDim);
                   //println(intersection.minus(enterp.plus(new Point6D(linevector).times(dist))).point);
                   assert (intersection.minus(fivedeew).ortho(fivedeex).ortho(fivedeey).ortho(fivedeez).length() < 0.001) : 
                   "Intersection not within our space, by "+intersection.minus(fivedeew).ortho(fivedeex).ortho(fivedeey).ortho(fivedeez).length();
                   Point6D intersectionvector = intersection.minus(segenterp);
                   assert (intersectionvector.ortho(new Point6D(linevector)).length() < 0.001) : 
                   "Intersection not on line";
                   assert (intersectionvector.minus((new Point6D(linevector)).times(dist)).length() < 0.001) : 
                   "Intersection mismatch by "+intersectionvector.minus((new Point6D(linevector)).times(dist)).length();
                   assert (intersectionvector.length()/(new Point6D(linevector)).length() <= 1.0) :
                   "Intersection beyond end of line segment";
                   }
                   intersections.add(intersection);*/                  // part of MEMORY MECHANISM
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
              Vertex left_downCell = new Vertex(round(enter[0]), round(enter[1]), round(enter[2]), round(enter[3]), round(enter[4]), round(enter[5]));
              // We have to add or subtract a bit to ensure we fall the desired direction for each starting cell. 
              left_downCell.point[lineDim] = round(enter[lineDim]+0.01);
              left_downCell.point[planeDim] = round(enter[planeDim]-0.01);

              Vertex right_downCell = new Vertex(round(enter[0]), round(enter[1]), round(enter[2]), round(enter[3]), round(enter[4]), round(enter[5]));
              right_downCell.point[lineDim] = round(enter[lineDim]-0.01);
              right_downCell.point[planeDim] = round(enter[planeDim]-0.01);

              Vertex left_upCell = new Vertex(round(enter[0]), round(enter[1]), round(enter[2]), round(enter[3]), round(enter[4]), round(enter[5]));
              left_upCell.point[lineDim] = round(enter[lineDim]+0.01);
              left_upCell.point[planeDim] = round(enter[planeDim]+0.01);

              Vertex right_upCell = new Vertex(round(enter[0]), round(enter[1]), round(enter[2]), round(enter[3]), round(enter[4]), round(enter[5]));
              right_upCell.point[lineDim] = round(enter[lineDim]-0.01);
              right_upCell.point[planeDim] = round(enter[planeDim]+0.01);

              left_downCell = cells.add(left_downCell);
              right_downCell = cells.add(right_downCell);
              left_upCell = cells.add(left_upCell);
              right_upCell = cells.add(right_upCell);

              //println("generating cells... "+N*20+round((dimN-dimstarts[N])/(dimends[N]-dimstarts[N]))+"%");

              // TODO MY FINAL GRIDS ARE MISSING SOME CELLS. This problem is not present (80% sure after testing) in 
              // the commit from 6/12/20. I NEED TO ADD SOME TEST THAT WOULD HAVE NOTICED THIS - probably I need to
              // reinstate the code which attempts to hook up the worms with a preferred directionality. 
              // Are some crossing points getting missed? I don't think so - a single point missed inside of a line would 
              // "derail" the conway worm and cause obvious gaps, deviations, and intersecting blocks. Instead it seems
              // like some lines are terminating early. Except I specifically fixed an early termination bug fairly recently,
              // and also, though these missing blocks are somewhat clustered together, I'm not seeing that one missing block 
              // tends to be followed by a bunch. What I'm seeing is that all the missing blocks seem to be instances of the 
              // same three planes intersecting one another. I guess this could still be a line terminating early - the non-missing
              // blocks along these worms would just be blocks generated by earlier passes.
              // If there are lines terminating early, it seems it's not *very* early. Final crossing-point passes an assertion for
              // being within root six of the line segment's endpoint. Not early enough to explain the observations.
              // The bug is not affected by reinstating the "metric" variable to ensure lines are flipped around to
              // face consistent directions. Yet, the zones in which these blocks are missing look like the sort
              // of thing that would be caused by not using "metric".
              // After some additional testing I'm fairly confident the issue is only happening for one specific block
              // type (same shape and orientation each time). Any given grid contains several vaguely triangular clusters
              // of missing blocks. The edges of these triangles seem to meet edges of the cube I'm generating within.
              // CHANGES SINCE 6/12/20:
              // >> fivedee0, fivedee1, and fivedee2 aren't directly normalized inside this constructor anymore.
              //    I could check whether this one is responsible pretty easily. At the same time I think I made
              //    this change immediately *after* noticing the bug, so it's probably not responsible.
              // >> cells was made a VertexStore.
              //    I could change Point6DStore to use the old exhaustive searches in order to check all
              //    these changes at once. Or make a LazyPoint6DStore class and change just VertexStore
              //    to be a subclass of it.
              // >> rhombs was made a RhombStore.
              // >> blocks was made a BlockStore.
              // >> PointStore intersections was introduced.
              // >> blocks is cleared out when cells and rhombs are.
              // >> renamed: planeN > planeLoc
              // >> renamed: N > lineDim
              // >> renamed: dimN > lineLoc
              // >> renamed: intersections > segment_intersections
              //    Any chance some references to "intersections" should be "segment_intersections" or vice versa?
              // >> Replaced mechanism for calculating enter and exit. Old version, which relied solely on "metric",
              //    was choosing incorrect elements of segment_intersection, which caused early line termination.
              //    (This was creating assertion errors later on rather than leaving holes in the grid.) Reason for
              //    early termination undiagnosed.
              // >> Added many assertions.
              //    Theoretically an assertion could have a side-effect. Could test this change simply by turning 
              //    assertions off.
              // >> The stepping cells, left_downCell &c., are all Vertex objects now instead of Point6D objects.
              // >> New block / new rhombus initialization stuff was reordered to accommodate use of Point6DStore
              // >> Many ".copy()" calls removed from the cells (within aforementioned initialization) in order 
              //    to ensure the Vertex objects assigned as vertices to our rhombuses are the same ones which end
              //    up in the list of cells.
              // The bug isn't affected by starting "lineDim" at zero instead of the (default) initialization of 
              // lineDim = planeDim.
              // The bug isn't fixed by moving the tolerance down to 0.0001 or down to zero.

              for (int i = 0; i < dists.size();) {// i gets incremented by the while loop
                // If we cross several lines at once, this is the place to deal with it.
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
                // In this specific example (with 4 lines crossing), we generate an octagonal prism,
                // but we ignore the two octagons, assuming they'll be expanded out later. So a 
                // weakness of this overall approach is that it only creates rhombic faces. If two
                // of the lines within the crossing coincide, it would just try to choose an order
                // rather than generating a higher-order face. (If the octagon were a proper face, all
                // these lines would coincide in any plane but this one.)
                /*if (i+1 < dists.size() && abs(dists.get(i) - dists.get(i+1)) < 0.01) {
                 println("Possible double-cross. Difference was "+(dists.get(i) - dists.get(i+1)));
                 println("Dimensions: "+dims.get(i)+", "+dims.get(i+1));
                 }*/

                //int dim = sorteddims[i];
                //int dir = enter[dim] < exit[dim] ? 1 : -1;
                int leftdim = sorteddims[i];
                int leftdir = enter[leftdim] < exit[leftdim] ? 1 : -1;
                int rightdim = sorteddims[i];
                int rightdir = enter[rightdim] < exit[rightdim] ? 1 : -1;

                // step through the entire singularity in one instance of the loop so I can associate all the
                // faces I generate to one cell. (That cell may exist or may not, and if it does we still
                // may need to add faces, which is different from the non-singular behavior.)
                // Find first and last crossing which are just this vertex' multiplicity.
                int curvertex_min = i;
                int curvertex_max = i;
                // TODO There's some possibility of the "current vertex window" being inconsistent
                // across loops (if these vertices are each slightly farther along but within the 
                // tolerance). Write an assertion which could tell. Perhaps could be done by recalculating
                // cell positions from the purported beginning of this vertex.
                while (curvertex_min > 0 && sorteddists[i] - sorteddists[curvertex_min-1] < tolerance*tolerance) {
                  curvertex_min --;
                }
                assert curvertex_min == i : "inconsistent current vertex window";
                while (curvertex_max+1 < dists.size() && abs(sorteddists[i] - sorteddists[curvertex_max+1]) < tolerance*tolerance) {//TODO right way of handling tolerance here? More generally, ought to start coming up with smarter choices of tolerance numbers
                  curvertex_max ++;
                }
                
                Point6D current_crossing = new Point6D(linevector).times(sorteddists[i]).plus(segenterp);
                Block multi_block = new Block(current_crossing);
                
                while (i <= curvertex_max) {
                  // TODO Now based on our current index within a multiple vertex, assign 
                  // differing values to leftdim and leftdir according to corrent ordering
                  // of the lines.
  
                  Vertex oldLeftDownCell = left_downCell;
                  Vertex oldRightDownCell = right_downCell;
                  Vertex oldLeftUpCell = left_upCell;
                  Vertex oldRightUpCell = right_upCell;
  
                  //TODO Floating point error could build up as I add and subtract integers here; could be better off using integers.
                  left_downCell = left_downCell.copy();
                  right_downCell = right_downCell.copy();
                  left_upCell = left_upCell.copy();
                  right_upCell = right_upCell.copy();
                  left_downCell.point[leftdim] += 1*leftdir;
                  right_downCell.point[rightdim] += 1*rightdir;
                  left_upCell.point[leftdim] += 1*leftdir;
                  right_upCell.point[rightdim] += 1*rightdir;
  
                  assert left_downCell.minus(oldLeftDownCell).length() == 1.0: 
                  "Wrong nldc-oldc";
  
                  //Point6D newintersection = enterp.plus((exitp.minus(enterp)).times(sorteddists[i]));
                  /*println(oldLeftDownCell.minus(newintersection).length());
                   println(oldRightDownCell.minus(newintersection).length());
                   println(oldLeftUpCell.minus(newintersection).length());
                   println(oldRightUpCell.minus(newintersection).length());
                   println(left_downCell.minus(newintersection).length());
                   println(right_downCell.minus(newintersection).length());
                   println(left_upCell.minus(newintersection).length());
                   println(right_upCell.minus(newintersection).length());*/
  
                  left_downCell = cells.add(left_downCell);
                  right_downCell = cells.add(right_downCell);
                  left_upCell = cells.add(left_upCell);
                  right_upCell = cells.add(right_upCell);
  
                  assert cells.contains(oldLeftDownCell): 
                  "old cell missing from cells";
                  assert cells.contains(oldRightDownCell): 
                  "old cell missing from cells";
                  assert cells.contains(oldLeftUpCell): 
                  "old cell missing from cells";
                  assert cells.contains(oldRightUpCell): 
                  "old cell missing from cells";
  
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
                  the_others.add(left_upCell);// TODO this is so many lines. how do i write it better
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
  
                  Block prev_block = blocks.add(block);
                  if (prev_block == block) {
                    // block was new; do setup
                    //blocks.add(block);
                    // This ordering of the axes - (N, planeDim, dim) - will be used when interpreting prev and next.
                    // TODO Used leftdim here. Is that reasonable?
                    block.axes = new ArrayList<Integer>(java.util.Arrays.asList(new Integer[]{lineDim, planeDim, leftdim}));
                    block.sides.add(new Rhomb(oldLeftDownCell, oldRightDownCell, oldLeftUpCell, oldRightUpCell));// old face
                    block.sides.add(new Rhomb(oldLeftDownCell, left_downCell, oldLeftUpCell, left_upCell));// left face
                    block.sides.add(new Rhomb(right_downCell, left_downCell, right_upCell, left_upCell));// new face
                    block.sides.add(new Rhomb(right_downCell, oldRightDownCell, right_upCell, oldRightUpCell));// right face
                    block.sides.add(new Rhomb(oldLeftUpCell, oldRightUpCell, left_upCell, right_upCell));// up face
                    block.sides.add(new Rhomb(oldLeftDownCell, oldRightDownCell, left_downCell, right_downCell));// down face
                    for (int side = 0; side < block.sides.size(); side++) {
                      if (test_assertions) {
                        float side_distance = block.sides.get(side).center.minus(block.center).length();
                        assert(side_distance == 0.5) : 
                        "Side is wrong distance from center";
                      }
                      //boolean rhombregistered = false;
                      // Rather than tracking direction and next vs. prev,
                      // for now I'm just going to rely on rhombs' ordering in "sides"
                      // lining up with neighboring blocks' ordering in "next".
                      Rhomb prev_rhomb = rhombs.add(block.sides.get(side));
                      if (prev_rhomb != block.sides.get(side)) {
                        assert prev_rhomb.parents.size() == 1 : 
                        "Rhombus already has two parents";
                        // Rhomb already existed.
                        block.sides.set(side, prev_rhomb);
                        // Rhombus must already have one parent.
                        Block neighbor = prev_rhomb.parents.get(0);
                        block.next.add(neighbor);
                        neighbor.next.set(neighbor.sides.indexOf(prev_rhomb), block);
                        prev_rhomb.parents.add(block);
                      } else {
                        // New rhombus
                        // Keep lists even w/ null elements
                        block.next.add(null);
                        prev_rhomb.parents.add(block);
                        assert prev_rhomb.parents.size() == 1 : 
                        "Rhombus already has two parents";
                        assert block.sides.get(side).parents.size() == 1 : 
                        "Rhombus already has two parents, and something odd is happening with RhombStore";
                      }
                      assert prev_rhomb == block.sides.get(side) : 
                      "Somehow didn't fix a mismatch";
                      assert rhombs.contains(block.sides.get(side)) : 
                      "RhombStore doing something weird";
                      assert prev_rhomb == rhombs.add(prev_rhomb) : 
                      "RhombStore doing something weird";
                      /*for (Rhomb rh : rhombs) {
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
                       }*/
                    }
                  }
                  if (test_assertions) {
                    for (Rhomb face : prev_block.sides) {
                      assert rhombs.contains(face) : 
                      "A face remains unregistered";
                      assert cells.contains(face.corner1) : 
                      "A corner remains unregistered";
                    }
                    for (Rhomb face : block.sides) {
                      assert cells.contains(face.corner1) : 
                      "A corner remains unregistered in an unused block object";
                    }
                  }
                  i++;
                }// End of double-cross while loop
                // TODO Could assert here that left and right are brought back together by the end (ie,
                // they form a unit cube again). Could also assert they're together at the beginning.
              }// Processed last crossing
              assert (new Point6D(linevector)).length()*(1 - sorteddists[dists.size()-1]) < sqrt(6): 
              "Didn't traverse whole line";
            }// done with if(dists.size() != 0
          }// done with all lineLoc's on this lineDim
          assert blocksOK(blocks.list): 
          "Problem with a block after lineDim"+lineDim;
        }// done with all lineDims on this plane
      }// done with this plane's positions
    }// done with all planes
    // Hunt down and fill in remaining holes.
    println("Checking for holes...");
    assert rhombsOK(rhombs.list) : 
    "Rhombs broken before hole search";
    assert blocksOK(blocks.list): 
    "Blocks compromised before hole search";
    ArrayList<Rhomb> incomplete = new ArrayList<Rhomb>();
    for (Rhomb face : (Iterable<Rhomb>)rhombs) {
      if (face.parents.size() == 1) {
        incomplete.add(face);
      }
    }
    assert rhombsOK(rhombs.list) : 
    "Rhombs broken by initialization of 'incomplete' list";
    ArrayList<Block> proposed = new ArrayList<Block>();
    for (Rhomb h : incomplete) {
      boolean have_proposal = false;
      Block proposal = new Block(new Vertex(0, 0, 0, 0, 0, 0));
      //assert rhombsOK(incomplete) : 
      //"Rhombs broken at start of h's loop";
      for (Rhomb i : incomplete) {
        if (h != i && max(h.center.minus(i.center).point) < 2) {// TODO This could be wrong cutoff once non-rhombohedron cells are included
          if (abs(h.center.minus(i.center).length() - (sqrt(2)/2)) <= tolerance) {
            // Might be adjacent face. Checking that it looks right
            Point6D diff = i.center.minus(h.center);
            int diffcount = 0;
            for (int dim = 0; dim < 6; dim++) {
              if (abs(diff.point[dim]) > tolerance) {
                diffcount++;
              }
            }
            if (diffcount == 2) {
              // Adjacent face
              if (have_proposal) {
                proposal.sides.add(i);
                //assert rhombsOK(incomplete):
                //"Rhombs broken by adding to proposal";
              } else {
                // Gotta initialize proposal
                Vertex new_center = new Vertex(h.center.copy().point);
                // Where h and i differ, take the one that's a half-integer rather than
                // the one that's an integer.
                for (int dim = 0; dim < 6; dim++) {
                  //assert rhombsOK(incomplete):
                  //"Rhombs broken before new proposal initialization";
                  if (abs(diff.point[dim]) > tolerance) {
                    if (abs(abs(h.center.point[dim] - round(h.center.point[dim]))-0.5) <= tolerance) {
                      //assert rhombsOK(incomplete):
                      //"Rhombs broken by if statements w/in new proposal init";
                      new_center.point[dim] = h.center.point[dim];
                    } else {
                      //assert rhombsOK(incomplete):
                      //"Rhombs broken by first if statement w/in new proposal init";
                      if (abs(abs(i.center.point[dim] - round(i.center.point[dim]))-0.5) <= tolerance) {
                        //assert rhombsOK(incomplete):
                        //"Rhombs broken before assignment to new_center";
                        new_center.point[dim] = i.center.point[dim];
                        //assert rhombsOK(incomplete):
                        //"Rhombs broken by assignment to new_center";
                      } else {
                        // We decided these were adjacent faces, so there shouldn't be an "else"
                        println(abs(abs(h.center.point[dim] - round(h.center.point[dim]))-0.5));
                        println(abs(abs(i.center.point[dim] - round(i.center.point[dim]))-0.5));
                      assert 1 == 0 : 
                        "Adjacent faces had no half-off dimensions";
                      }
                    }
                  }
                  //assert rhombsOK(incomplete):
                  //"Rhombs broken by new proposal initialization";
                }
                proposal = new Block(new_center);
                proposal.sides.add(h);
                proposal.sides.add(i);
                proposed.add(proposal);
                have_proposal = true;
              }
            }
          } else if (abs(h.center.minus(i.center).length() - 1.0) <= tolerance) {
            Point6D diff = i.center.minus(h.center);
            // In 4D and up, a whole-number difference could nonetheless be along a diagonal.
            // IE, 1.0 can show up if the rhombuses differ by 0.5 in exactly four dimensions.
            // Check that this isn't happening.
            if (max(diff.point) > 0.5 || min(diff.point) < -0.5) {
              // We have an opposite face
              if (have_proposal) {
                proposal.sides.add(i);
              } else {
                // Gotta initialize proposal
                Vertex new_center = new Vertex(h.center.copy().point);
                // Where h and i differ, take value between the two.
                for (int dim = 0; dim < 6; dim++) {
                  if (abs(diff.point[dim]) > tolerance) {
                    new_center.point[dim] = (h.center.point[dim] + i.center.point[dim])/2;
                    assert rhombsOK(rhombs.list) : 
                    "Rhombs broken...";
                    assert abs(abs(h.center.point[dim] - i.center.point[dim]) - 1.0) <= tolerance :
                    "Opposite faces were off by "+abs(h.center.point[dim] - i.center.point[dim]);
                  }
                }
                proposal = new Block(new_center);
                proposal.sides.add(h);
                proposal.sides.add(i);
                proposed.add(proposal);
                have_proposal = true;
              }
            }
          }
        }
      }// done with all i
    }
    if (test_assertions) {
      for (Rhomb i : incomplete) {
        assert i.parents.size() == 1 : "Supposedly single-parent rhomb w/ two parents after proposal stage";
      }
    }
    BlockStore complete = new BlockStore(0.01);
    for (Block proposal : proposed) {
      // TODO It's looking like there are probably cases where the block has more than 6 proposed sides
      // but would still be OK to add
      if (proposal.sides.size() == 6) {
        boolean block_exists = false;
        boolean block_sane = true;
        Point6D center_calc = new Point6D(0,0,0,0,0,0);
        for (Rhomb face : proposal.sides) {
          center_calc = center_calc.plus(face.center);
          int samecount = 0;
          for (Rhomb face2 : proposal.sides) {
            if (face.parents.get(0) == face2.parents.get(0)) samecount++;
          }
          if (samecount != 1) {
            block_exists = true;
            // TODO below assertion fails. Why do I actually get samecount > 1?
            //assert blocks.contains(proposal) : "block might have been weird, but wasn't already there";
          }
        }
        center_calc = center_calc.times(1.0/6);
        if (center_calc.minus(proposal.center).length() > 0.001) block_sane = false;
        if (picky_assertions) {
          assert block_sane : "Block appears malformed for unknown reason.";
        }
        if (block_sane && !block_exists)
          complete.add(proposal);
      }
      // TODO We could fill in some faces, e.g. if we had 5 of 6.
    }
    if (test_assertions) {
      for (Rhomb i : incomplete) {
        assert i.parents.size() == 1 : "Supposedly single-parent rhomb w/ two parents after filtering proposals";
      }
    }
    if (picky_assertions) {
      assert complete.size() == 0 :
      "Discovered "+complete.size()+" cell-shaped holes in the tiling.";
    } else {
      println("Filling "+complete.size()+" holes");
    }
    // TODO We let BlockStore deal with our redundancy. Would be faster w/o redundancy //<>//
    assert blocksOK(blocks.list): 
    "Blocks compromised before adding any";
    for (Block block : complete.list) {
      assert blocksOK(blocks.list): 
      "Irregularity occurred prev. time thru loop";
      Block canonical_block = blocks.add(block);
      assert blocksOK(blocks.list): 
      "Should not have added block, it's wonky";
      if (block == canonical_block) {
        // block being added for the first time. Add block to its faces.
        for (Rhomb face : block.sides) {// Trying to figure out what's going wrong
          assert (face.parents.size() == 1) :
          "If block is being added for the first time, how does its face have two parents?";
          int samecount = 0;
          for (Rhomb face2 : block.sides) {
            if (face.parents.get(0) == face2.parents.get(0)) samecount++;
          }
          if (samecount != 1) {
            print("Faces already weird");
          }
        }
        for (Rhomb face : block.sides) {
          block.next.add(face.parents.get(0));
          assert face.parents.size() == 1 : 
          "Face already had two parents";
          assert face.parents.get(0).next.get(face.parents.get(0).sides.indexOf(face)) == null :
          "Looks like something is up with our alignment of next and sides";
          face.parents.get(0).next.set(face.parents.get(0).sides.indexOf(face), block);
          face.parents.add(block);
        }
        assert blocksOK(blocks.list): "Seems like we didn't add to next properly.";
      }
    }
  }// done with Quasicrystal constructor

  boolean rhombsOK(ArrayList<Rhomb> rhombs) {
    for (Rhomb r : rhombs) {
      Rhomb testrhomb = new Rhomb(r.corner1, r.corner2, r.corner3, r.corner4);
      if (testrhomb.center.minus(r.center).length() > 0.0001) {
        return false;
      }
    }
    return true;
  }

  boolean blocksOK(ArrayList<Block> blocks) {
    for (Block b : blocks) {
      if (b.next.size() > 0 && b.next.size() != b.sides.size()) {
        return false;
      }
      for (Block neighbor : b.next) {
        if (neighbor != null) {
          int samecount = 0;
          for (Block neighbor2 : b.next) {
            if (neighbor == neighbor2) samecount++;
          }
          if (samecount != 1) 
            return false;
        }
      }
      for (Rhomb r : b.sides) {
        int samecount = 0;
        for (Rhomb r2 : b.sides) {
          if (r == r2) samecount++;
        }
        if (samecount != 1)
          return false;
        if (r.parents.size() == 2) {
          // test that the two parents make sense
          int index = 0;
          while (index < r.parents.size() && r.parents.get(index) == b) index++;
          if (index > 1)
            return false; //<>//
          // TODO test that neighbor is adjacent and
          // isn't overlapping
        } else {
          assert r.parents.size() == 1 : 
          "Rhombus with 3 or more parents";
          if (b.next.size() > 0 && b.next.get(b.sides.indexOf(r)) != null) {
            // Rhombus is w/o a parent but block has a corresponding "next"
            return false; //<>//
          }
        }
      }
    }
    return true;
  }
}// done with Quasicrystal class

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

  public void set(Point6D p) {
    point[0] = p.point[0];
    point[1] = p.point[1];
    point[2] = p.point[2];
    point[3] = p.point[3];
    point[4] = p.point[4];
    point[5] = p.point[5];
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
  Vertex corner1;//negative in both axes; (-.5,-.5)
  Vertex corner2;//(-.5,.5)
  Vertex corner3;//(.5,-.5)
  Vertex corner4;//(.5,.5)
  Point6D center;
  int value;
  int nextValue;

  // 3D cache
  /*PVector corner1_3D;
   PVector corner2_3D;
   PVector corner3_3D;
   PVector corner4_3D;*/
  PVector center_3D;

  public Rhomb(Vertex c1, Vertex c2, Vertex c3, Vertex c4) {
    corner1 = c1;
    corner2 = c2;
    corner3 = c3;
    corner4 = c4;
    center = (c1.plus(c2.plus(c3.plus(c4)))).times(0.25);
    if (test_assertions) {
      for (int i = 0; i < 6; i++) {
        assert abs(center.point[i]-round(center.point[i])) == 0.0 || abs(center.point[i]-round(center.point[i])) == 0.5 :
        "Created a rhombus with a weird center point";
      }
    }
    a1prev = null;
    a2prev = null;
    a1next = null;
    a2next = null;
    parents = new ArrayList<Block>();
  }
}

class Vertex extends Point6D {
  PVector location_3D;
  // TODO It's pretty lame that this class ends up being so many lines when it's literally
  // adding one field and doing nothing else. Fix??
  public Vertex (float a, float b, float c, float d, float e, float f) {
    super(a, b, c, d, e, f);
  }
  public Vertex (float[] p) {
    super(p);
  }
  public Vertex copy() {
    return new Vertex(super.copy().point);
  }
  public Vertex times(float scalar) {
    return new Vertex(super.times(scalar).point);
  }

  public void set(Vertex v) {
    // TODO I want a compile-time error if I add a field to Vertex and forget to
    // copy its value here. Is that too much to ask?
    super.set(v);
    //location_3D.x = v.location_3D.x;
    //location_3D.y = v.location_3D.y;
    //location_3D.z = v.location_3D.z;
    location_3D = v.location_3D;
  }
}

// TODO Create version which uses integer coordinates
abstract class Point6DStore<V> implements Iterable {
  // TODO make list and storage private, deal with the consequences properly.
  java.util.Dictionary[] storage;
  ArrayList<V> list;
  float tolerance;

  public Point6DStore(float fetch_tolerance) {
    tolerance = fetch_tolerance;
    storage = new java.util.Dictionary[]{new java.util.Hashtable<Float, ArrayList<V>>(), new java.util.Hashtable<Float, ArrayList<V>>(), new java.util.Hashtable<Float, ArrayList<V>>(), 
      new java.util.Hashtable<Float, ArrayList<V>>(), new java.util.Hashtable<Float, ArrayList<V>>(), new java.util.Hashtable<Float, ArrayList<V>>()};
    list = new ArrayList<V>();
  }

  // TODO Make iterable have right type
  // TODO Allow removal of items
  // TODO Support get() queries with wider tolerances; use to optimize chunk classification.
  // TODO There is almost complete overlap between code in contains(), add(), and get(). Find a clean way to abstract.

  /*private void general_lookup(Point6D key, boolean do_add, boolean do_return_multiple, float tolerance, V value, Boolean return_found, V[] return_match, ArrayList return_multiple) {
   // Look for matches to key, within range tolerance. If do_add, and no matches, add value using key.
   // If there is a match, return it by assignment to return_match, then terminate search. If 
   // do_return_multiple, continue the search instead and return all matches. Set return_found to true 
   // whenever one or more matches are found.
   boolean found = false;
   // TODO several ways to make this faster.
   ArrayList<Float>[] hits = new ArrayList[]{new ArrayList<Float>(), new ArrayList<Float>(), new ArrayList<Float>(), new ArrayList<Float>(), new ArrayList<Float>(), new ArrayList<Float>()};
   for (int i = 0; i < 6; i++) {
   boolean came_up_empty = true;
   for (java.util.Enumeration<Float> k = storage[i].keys(); k.hasMoreElements(); ) {
   float nextkey = k.nextElement();
   if (abs(nextkey - key.point[i]) < tolerance) {
   hits[i].add(nextkey);
   came_up_empty = false;
   }
   }
   if (came_up_empty) {
   // No need to do next dimension; unmatched in one means novel item.
   break;
   }
   }
   ArrayList<Integer> hitsize = new ArrayList<Integer>();
   for (int i = 0; i < 6; i++) {
   int sum = 0;
   for (Float k : hits[i]) {
   sum += ((ArrayList<Float>)(storage[i].get(k))).size();
   }
   hitsize.add(sum);
   }
   if (min(new int[]{hitsize.get(0), hitsize.get(1), hitsize.get(2), hitsize.get(3), hitsize.get(4), hitsize.get(5)}) == 0) {
   // Item not present in storage. Go ahead and add it.
   if (do_add) definitelyAdd(key, value);
   return_found
   return;
   }
   int i = hitsize.indexOf(min(new int[]{hitsize.get(0), hitsize.get(1), hitsize.get(2), hitsize.get(3), hitsize.get(4), hitsize.get(5)}));
   for (Float k : hits[i]) {
   ArrayList<V> values = (ArrayList<V>)storage[i].get(k);
   for (V fetched : values) {
   if (equals(location(value), location(fetched))) {
   found = true;
   return fetched;
   }
   }
   }
   if (!found) {
   // Item is not present; actually add it
   definitelyAdd(key, value);
   return value;
   }
   // Hopefully this is unreachable
   return null;
   }*/

  boolean contains(V value) {
    Point6D key = location(value);
    boolean found = false;
    // TODO several ways to make this faster.
    ArrayList<Float>[] hits = new ArrayList[]{new ArrayList<Float>(), new ArrayList<Float>(), new ArrayList<Float>(), new ArrayList<Float>(), new ArrayList<Float>(), new ArrayList<Float>()};
    for (int i = 0; i < 6; i++) {
      boolean came_up_empty = true;
      for (java.util.Enumeration<Float> k = storage[i].keys(); k.hasMoreElements(); ) {
        float nextkey = k.nextElement();
        if (abs(nextkey - key.point[i]) <= tolerance) {
          hits[i].add(nextkey);
          came_up_empty = false;
        }
      }
      if (came_up_empty) {
        // No need to do next dimension; unmatched in one means novel item.
        break;
      }
    }
    ArrayList<Integer> hitsize = new ArrayList<Integer>();
    for (int i = 0; i < 6; i++) {
      int sum = 0;
      for (Float k : hits[i]) {
        sum += ((ArrayList<Float>)(storage[i].get(k))).size();
      }
      hitsize.add(sum);
    }
    if (min(new int[]{hitsize.get(0), hitsize.get(1), hitsize.get(2), hitsize.get(3), hitsize.get(4), hitsize.get(5)}) == 0) {
      // Item not present in storage.
      return false;
    }
    int i = hitsize.indexOf(min(new int[]{hitsize.get(0), hitsize.get(1), hitsize.get(2), hitsize.get(3), hitsize.get(4), hitsize.get(5)}));
    for (Float k : hits[i]) {
      ArrayList<V> values = (ArrayList<V>)storage[i].get(k);
      for (V fetched : values) {
        if (equals(location(value), location(fetched))) {
          found = true;
          return found;
        }
      }
    }
    return found;
  }

  V add(V value) {
    Point6D key = location(value);
    boolean found = false;
    // TODO several ways to make this faster.
    ArrayList<Float>[] hits = new ArrayList[]{new ArrayList<Float>(), new ArrayList<Float>(), new ArrayList<Float>(), new ArrayList<Float>(), new ArrayList<Float>(), new ArrayList<Float>()};
    for (int i = 0; i < 6; i++) {
      boolean came_up_empty = true;
      for (java.util.Enumeration<Float> k = storage[i].keys(); k.hasMoreElements(); ) {
        float nextkey = k.nextElement();
        if (abs(nextkey - key.point[i]) <= tolerance) {
          hits[i].add(nextkey);
          came_up_empty = false;
        }
      }
      if (came_up_empty) {
        // No need to do next dimension; unmatched in one means novel item.
        break;
      }
    }
    ArrayList<Integer> hitsize = new ArrayList<Integer>();
    for (int i = 0; i < 6; i++) {
      int sum = 0;
      for (Float k : hits[i]) {
        sum += ((ArrayList<Float>)(storage[i].get(k))).size();
      }
      hitsize.add(sum);
    }
    if (min(new int[]{hitsize.get(0), hitsize.get(1), hitsize.get(2), hitsize.get(3), hitsize.get(4), hitsize.get(5)}) == 0) {
      // Item not present in storage. Go ahead and add it.
      definitelyAdd(key, value);
      return value;
    }
    int i = hitsize.indexOf(min(new int[]{hitsize.get(0), hitsize.get(1), hitsize.get(2), hitsize.get(3), hitsize.get(4), hitsize.get(5)}));
    for (Float k : hits[i]) {
      ArrayList<V> values = (ArrayList<V>)storage[i].get(k);
      for (V fetched : values) {
        if (equals(location(value), location(fetched))) {
          found = true;
          return fetched;
        }
      }
    }
    if (!found) {
      // Item is not present; actually add it
      definitelyAdd(key, value);
      return value;
    }
    // Hopefully this is unreachable
    return null;
  }

  private void definitelyAdd(Point6D key, V value) {
    for (int i = 0; i < 6; i++) {
      ArrayList<V> list_i = (ArrayList<V>)(storage[i].get(key.point[i]));
      if (list_i != null) {
        list_i.add(value);
      } else {
        ArrayList<V> initial_list_i = new ArrayList<V>();
        initial_list_i.add(value);
        storage[i].put(key.point[i], initial_list_i);
      }
    }
    list.add(value);
  }

  V get(Point6D key) {
    // TODO several ways to make this faster.
    ArrayList<Float>[] hits = new ArrayList[]{new ArrayList<Float>(), new ArrayList<Float>(), new ArrayList<Float>(), new ArrayList<Float>(), new ArrayList<Float>(), new ArrayList<Float>()};
    for (int i = 0; i < 6; i++) {
      boolean came_up_empty = true;
      for (java.util.Enumeration<Float> k = storage[i].keys(); k.hasMoreElements(); ) {
        float nextkey = k.nextElement();
        if (abs(nextkey - key.point[i]) <= tolerance) {
          hits[i].add(nextkey);
          came_up_empty = false;
        }
      }
      if (came_up_empty) {
        // No need to do next dimension; unmatched in one means novel item.
        break;
      }
    }
    ArrayList<Integer> hitsize = new ArrayList<Integer>();
    for (int i = 0; i < 6; i++) {
      int sum = 0;
      for (Float k : hits[i]) {
        sum += ((ArrayList<Float>)(storage[i].get(k))).size();
      }
      hitsize.add(sum);
    }
    if (min(new int[]{hitsize.get(0), hitsize.get(1), hitsize.get(2), hitsize.get(3), hitsize.get(4), hitsize.get(5)}) == 0) {
      // Item not present in storage.
      return null;
    }
    int i = hitsize.indexOf(min(new int[]{hitsize.get(0), hitsize.get(1), hitsize.get(2), hitsize.get(3), hitsize.get(4), hitsize.get(5)}));
    for (Float k : hits[i]) {
      ArrayList<V> values = (ArrayList<V>)storage[i].get(k);
      for (V fetched : values) {
        if (equals(key, location(fetched))) {
          return fetched;
        }
      }
    }
    // Item not found
    return null;
  }

  boolean equals(Point6D a, Point6D b) {
    return (max((a).minus((b)).abs().point) <= tolerance);
  }

  abstract Point6D location(V value);

  public java.util.Iterator<V> iterator() {
    return list.iterator();
  }

  public int size( ) {
    return list.size();
  }
}

class RhombStore extends Point6DStore<Rhomb> {
  public RhombStore(float tolerance) {
    super(tolerance);
  }

  Point6D location(Rhomb r) {
    return r.center;
  }
}

class VertexStore extends Point6DStore<Vertex> {
  public VertexStore(float tolerance) {
    super(tolerance);
  }

  Point6D location(Vertex v) {
    return v;
  }
}

class BlockStore extends Point6DStore<Block> {
  public BlockStore(float tolerance) {
    super(tolerance);
  }

  Point6D location(Block b) {
    return b.center;
  }
}

class PointStore extends Point6DStore<Point6D> {
  public PointStore(float tolerance) {
    super(tolerance);
  }

  Point6D location(Point6D p) {
    return p;
  }
}
