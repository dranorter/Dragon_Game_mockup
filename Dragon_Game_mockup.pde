/**************************************** //<>//
 * Dragon Game Mockup by Daniel Demski.
 * 
 * The actual point of this is to make sure that I understand the
 * Cut and Project method for making non-periodic tilings,
 * and see what some examples at odd angles look like. But as a 
 * first application I thought it would be nice to make a non-
 * periodic clone of 2048.
 * 
 * 
 *****************************************/
//import queasycam.*;

// Radius is roughly how many cells will be rendered in
float radius = 6;
float driftspeed = 0.1;
// Tolerance is used when checking whether two vertices are equal.
float tolerance = 0.01;

boolean run = true;
boolean firstrun = true;
int initialdelay = 1;
int rounddelay = 10;
boolean playSetup = false;

boolean spacePressed = false;
boolean clicked = false;

//float[] fivedeex = {random(-10,10),random(-10,10),random(-10,10),random(-10,10),random(-10,10)};
//float[] fivedeey = {random(-10,10),random(-10,10),random(-10,10),random(-10,10),random(-10,10)};
//float[] fivedeew = {random(-10,10),random(-10,10),random(-10,10),random(-10,10),random(-10,10)};// The position of the screen's origin

// Penrose?
Point6D fivedeex = new Point6D(new float[]{1, 0.309, -0.809, -0.809, 0.309, 0});
Point6D fivedeey = new Point6D(new float[]{0, 0.951, 0.588, -0.588, -0.951, 0});
Point6D fivedeez = new Point6D(new float[]{0, 0, 0, 0, 0, 1});
Point6D fivedeew = new Point6D(new float[]{0.4, 0.4, 0.4, 0.4, 0.4, 0.4});
Point6D fivedee0 = new Point6D(new float[]{1, 0.309, -0.809, -0.809, 0.309, 0});
Point6D fivedee1 = new Point6D(new float[]{0, 0.951, 0.588, -0.588, -0.951, 0});
Point6D fivedee2 = new Point6D(new float[]{0, 0, 0, 0, 0, 1});

Point6D driftx = new Point6D(new float[]{random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1)});
Point6D drifty = new Point6D(new float[]{random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1)});
Point6D driftz = new Point6D(new float[]{random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1)});
Point6D driftw = new Point6D(new float[]{random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1)});
//float[] driftw = {.25,.25,.25,.25,.25};

ArrayList<Point6D> cells = new ArrayList<Point6D>();
ArrayList<Rhomb> rhombs = new ArrayList<Rhomb>();
ArrayList<Point2D> rc2D = new ArrayList<Point2D>();
ArrayList<Block> blocks = new ArrayList<Block>();

//Point6D w;

float CameraX = 0;
float CameraY = 0;
float CameraZ = 0;
float CameraRX = 0;
float CameraRY = 0;
float CameraRZ = 0;

public dimProjector twodee;
public dimProjector fivedee;

QueasyCam cam;
PMatrix3D originalMatrix;

void setup() {
  size(displayWidth, displayHeight, P3D);
  smooth(3);
  background(100);
  //camera(width/2.0,height/2.0,(height/2.0) / tan(PI*30.0 / 180.0), width/2.0, height/2.0, 0, 0, 1, 0);
  //frustum(10, -10, -10*float(displayHeight)/displayWidth, 10*float(displayHeight)/displayWidth, 10, 1000000);
  originalMatrix = ((PGraphicsOpenGL)this.g).camera;
  cam = new QueasyCam(this);
  cam.speed = 0.5;
  cam.sensitivity = 0.5;
}

void draw() {
  lights();
  if (spacePressed) {
    run = !run;
    spacePressed = false;
  }
  if (run) {
    drift();
  } else {
    render();
  }
  if (run) run = !run;
}

void drawCrosshair() {
  hint(DISABLE_DEPTH_TEST);
  int ccolor = rotateColor(cam.applet.get(width/2, height/2));
  stroke(ccolor);
  PVector hudorigin = cam.position.copy().add(cam.getForward());
  PVector rightside = hudorigin.copy().add(cam.getRight().copy().mult(0.01));
  PVector leftside = hudorigin.copy().add(cam.getRight().copy().mult(-0.01));
  line(rightside.x, rightside.y, rightside.z, leftside.x, leftside.y, leftside.z);
  PVector up = cam.getForward().copy().cross(cam.getRight());
  PVector topside = hudorigin.copy().add(up.copy().mult(0.01));
  PVector bottomside = hudorigin.copy().add(up.copy().mult(-0.01));
  line(topside.x, topside.y, topside.z, bottomside.x, bottomside.y, bottomside.z);
  hint(ENABLE_DEPTH_TEST);
}

int rotateColor(int c) {
  float r = (red(c) + 128)%256;
  float g = (green(c) + 128)%256;
  float b = (blue(c) + 128)%256;
  return color(r, g, b);
}

void setupRender() {
  for (Block block : blocks) {
    for (Rhomb face : block.sides) {
      /* TODO I'm repeating calculations here; the block only has a few vertices, but each
       vertex has several rhombuses. Ideally what I would do is have a Vertex object which 
       stores the 3D calculation, so that it need only be computed once for all adjacent
       vertices. */
      face.corner1_3D = new PVector(face.corner1.minus(fivedeew).dot(fivedee0), face.corner1.minus(fivedeew).dot(fivedee1), face.corner1.minus(fivedeew).dot(fivedee2));
      face.corner2_3D = new PVector(face.corner2.minus(fivedeew).dot(fivedee0), face.corner2.minus(fivedeew).dot(fivedee1), face.corner2.minus(fivedeew).dot(fivedee2));
      face.corner3_3D = new PVector(face.corner3.minus(fivedeew).dot(fivedee0), face.corner3.minus(fivedeew).dot(fivedee1), face.corner3.minus(fivedeew).dot(fivedee2));
      face.corner4_3D = new PVector(face.corner4.minus(fivedeew).dot(fivedee0), face.corner4.minus(fivedeew).dot(fivedee1), face.corner4.minus(fivedeew).dot(fivedee2));
      face.center_3D = new PVector(face.center.minus(fivedeew).dot(fivedee0), face.center.minus(fivedeew).dot(fivedee1), face.center.minus(fivedeew).dot(fivedee2));
    }
  }
  int selection;
  for (int loopvar = 0; loopvar < 1000; loopvar++) {
    selection = floor(random(blocks.size()));
    blocks.get(selection).value = floor(random(0, 10));
  }

  playSetup = true;
}

void render() {
  if (!playSetup) {
    setupRender();
  }
  background(0, 100, 0);
  ArrayList<Rhomb> pointedAt = new ArrayList<Rhomb>();
  for (Block block : blocks) {
    if (block.value > 0) {
      for (Rhomb face : block.sides) {
        boolean hasair = true;
        if (face.parents.size() == 2) {
          if (face.parents.get(0).value > 0 && face.parents.get(1).value > 0) {
            hasair = false;
          }
        }
        if (hasair) {
          // We know this block isn't air and any neighbor is,
          // so we aren't rendering twice here
          if (cameraPoint(face)) {
            pointedAt.add(face);
          }
          //stroke(100);
          noStroke();
          fill(block.value*25, block.value*10, 255-block.value*25);
          beginShape();
          vertex(face.corner1_3D.x, face.corner1_3D.y, face.corner1_3D.z);
          vertex(face.corner2_3D.x, face.corner2_3D.y, face.corner2_3D.z);
          vertex(face.corner4_3D.x, face.corner4_3D.y, face.corner4_3D.z);
          vertex(face.corner3_3D.x, face.corner3_3D.y, face.corner3_3D.z);
          endShape(CLOSE);
        }
      }
    }
  }
  if (pointedAt.size() > 0) {
    Rhomb closest = pointedAt.get(0);
    float closestDist = closest.center_3D.copy().sub(cam.position).dot(cam.getForward());
    for (int i = 1; i < pointedAt.size(); i++) {
      float dist = pointedAt.get(i).center_3D.copy().sub(cam.position).dot(cam.getForward());
      if (closestDist > dist) {
        closestDist = dist;
        closest = pointedAt.get(i);
      }
    }
    Block block = closest.parents.get(0);
    if (closest.parents.size() == 2) {
      // Both sides are generated
      Block empty = closest.parents.get(1);
      if (block.value == 0) {
        block = closest.parents.get(1);
        empty = closest.parents.get(0);
      }
      if (clicked) {
        if (mouseButton == LEFT) empty.value += 1;
        if (mouseButton == RIGHT) block.value = 0;
        clicked = false;
      }
      stroke(255);
      noFill();
      for (Rhomb face : empty.sides) {
        beginShape();
        vertex(face.corner1_3D.x, face.corner1_3D.y, face.corner1_3D.z);
        vertex(face.corner2_3D.x, face.corner2_3D.y, face.corner2_3D.z);
        vertex(face.corner4_3D.x, face.corner4_3D.y, face.corner4_3D.z);
        vertex(face.corner3_3D.x, face.corner3_3D.y, face.corner3_3D.z);
        endShape(CLOSE);
      }
      stroke(0, 255, 0);
      fill(255-(255-block.value*25)*0.8, 255-(255-block.value*10)*0.8, 255-block.value*25*0.8);
      beginShape();
      vertex(closest.corner1_3D.x, closest.corner1_3D.y, closest.corner1_3D.z);
      vertex(closest.corner2_3D.x, closest.corner2_3D.y, closest.corner2_3D.z);
      vertex(closest.corner4_3D.x, closest.corner4_3D.y, closest.corner4_3D.z);
      vertex(closest.corner3_3D.x, closest.corner3_3D.y, closest.corner3_3D.z);
      endShape(CLOSE);
    } else {
      stroke(255, 255, 0);
      fill(255-(255-block.value*25)*0.8, 255-(255-block.value*10)*0.8, 255-block.value*25*0.8);
      if (clicked) {
        if (mouseButton == RIGHT) block.value = 0;
        clicked = false;
      }
      beginShape();
      vertex(closest.corner1_3D.x, closest.corner1_3D.y, closest.corner1_3D.z);
      vertex(closest.corner2_3D.x, closest.corner2_3D.y, closest.corner2_3D.z);
      vertex(closest.corner4_3D.x, closest.corner4_3D.y, closest.corner4_3D.z);
      vertex(closest.corner3_3D.x, closest.corner3_3D.y, closest.corner3_3D.z);
      endShape(CLOSE);
    }
  }
  drawCrosshair();
}

boolean cameraPoint(Rhomb face) {
  // Use camera as origin
  PVector c1 = face.corner1_3D.copy().sub(cam.position);
  PVector c2 = face.corner2_3D.copy().sub(cam.position);
  PVector c3 = face.corner3_3D.copy().sub(cam.position);
  PVector c4 = face.corner4_3D.copy().sub(cam.position);
  float c1f = cam.forward.dot(c1);
  float c2f = cam.forward.dot(c2);
  float c3f = cam.forward.dot(c3);
  float c4f = cam.forward.dot(c4);
  // Don't want to do any more multiplication unless we have to
  if (c1f > 0 || c2f > 0 || c3f > 0 || c4f > 0) {
    // flattening onto a plane
    c1.sub(cam.forward.copy().mult(c1f));
    c2.sub(cam.forward.copy().mult(c2f));
    c3.sub(cam.forward.copy().mult(c3f));
    //c4.sub(cam.forward.copy().mult(c4f));
    // Now for an actual plane
    Point2D flat1 = new Point2D(0, 0);
    Point2D flat2 = new Point2D(0, 0);
    Point2D flat3 = new Point2D(0, 0);
    //Point2D flat4 = new Point2D(0, 0);
    Point2D flatcenter = new Point2D(0, 0);// The camera's position is genuinely (0,0).
    // We're discarding whichever dimension varies least.
    for (int d = 0; d < 3; d++) {
      if (max(cam.forward.array()) == cam.forward.array()[d]) {
        int j = 0;
        for (int i=0;; j++) {
          if (i == d) i++;
          if (j>=2) break;
          flat1.point[j] = c1.array()[i];
          flat2.point[j] = c2.array()[i];
          flat3.point[j] = c3.array()[i];
          //flat4.point[j] = c4.array()[i];
          i++;
        }
        break;
      }
    }
    Point2D edge1 = flat2.minus(flat1);
    Point2D axis1 = edge1.orthoflip();
    float dp1 = flat1.dot(axis1);
    float dp2 = 0;// always works out to zero
    float dp3 = flat3.dot(axis1);
    if ((dp1 <= dp2 && dp2 <= dp3) || (dp1 >= dp2 && dp2 >= dp3)) {
      // Finally we know something: screen center is between two of the edges. Check other two.
      Point2D edge2 = flat3.minus(flat1);
      Point2D axis2 = edge2.orthoflip();
      dp1 = flat1.dot(axis2);
      dp2 = 0;// always works out to zero
      dp3 = flat2.dot(axis2);
      if ((dp1 <= dp2 && dp2 <= dp3) || (dp1 >= dp2 && dp2 >= dp3)) {
        return(true);
      }
    }
  }
  return(false);
}

Rhomb getNext(Rhomb r, int arrowdim, int arrowdir) {
  if (r.axis1 == arrowdim && arrowdir < 0) return r.a1prev;
  if (r.axis2 == arrowdim && arrowdir < 0) return r.a2prev;
  if (r.axis1 == arrowdim && arrowdir > 0) return r.a1next;
  if (r.axis2 == arrowdim && arrowdir > 0) return r.a2next;
  return null;
}

void keyPressed() {
  if (key==' ') {
    spacePressed = true;
  }
}

void mouseClicked() {
  clicked = true;
}

void drift() {
  // The 'radius' is approximately the size of the screen within the 5D space.
  // Within the 2D space, we will measure the screen in pixels instead.
  // The 3D space is approximately using pixels.

  clicked = false;
  playSetup = false;

  background(0, 100, 0);
  stroke(100, 100, 100);
  //fivedeex, fivedeey and fivedeez determine the tilt of our plane in higher-d space.
  //fivedeew determines the last dimension, and serves as the 3D origin.
  fivedeex = fivedeex.plus(driftx.times(driftspeed*0.03));
  fivedeey = fivedeey.plus(drifty.times(driftspeed*0.03));
  fivedeez = fivedeez.plus(driftz.times(driftspeed*0.03));
  fivedeew = fivedeew.plus(driftw.times(driftspeed*0.03));
  for (int i = 0; i < 6; i++) {
    driftx.point[i] += random(-0.02, 0.02);
    drifty.point[i] += random(-0.02, 0.02);
    driftz.point[i] += random(-0.02, 0.02);
    driftw.point[i] += random(-0.02, 0.02);
  }
  driftx = driftx.normalized();
  drifty = drifty.normalized();
  driftz = driftz.normalized();
  driftw = driftw.normalized();

  // these are the actual basis vectors: (making them orthogonal)
  fivedee0 = fivedeex.normalized();
  fivedee1 = fivedeey.ortho(fivedee0).normalized();
  fivedee2 = fivedeez.ortho(fivedee0).ortho(fivedee1).normalized();

  // We then make our original vectors line up to these.
  // Sizes here determine bounded area of the render.
  fivedeex = fivedee0.times(radius*float(width)/float(height));
  fivedeey = fivedee1.times(radius);
  fivedeez = fivedee2.times(radius*float(width)/float(height));

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

    Point6D orthox = fivedeex.ortho(plane5Dw);
    Point6D orthoy = fivedeey.ortho(plane5Dw);
    Point6D orthoz = fivedeez.ortho(plane5Dw);

    Point6D plane5D0 = new Point6D(0, 0, 0, 0, 0, 0);
    Point6D plane5D1 = new Point6D(0, 0, 0, 0, 0, 0);

    // We want the larger axes to minimize error maybe? but also because one of them could be zero.
    if (orthox.length() > orthoy.length()) { 
      if (orthox.length() > orthoz.length()) {
        plane5D0 = orthox;
        if (orthoy.length() > orthoz.length()) {
          plane5D1 = orthoy;
        } else {
          plane5D1 = orthoz;
        }
      } else {
        plane5D0 = orthoz;
        plane5D1 = orthox;
      }
    } else if (orthoy.length() > orthoz.length()) {
      plane5D0 = orthoy;
      if (orthox.length() > orthoz.length()) {
        plane5D1 = orthox;
      } else {
        plane5D1 = orthoz;
      }
    } else {
      plane5D0 = orthoz;
      plane5D1 = orthoy;
    }

    plane5D0 = plane5D0.normalized();
    plane5D1 = plane5D1.normalized();

    // Having expressed our 2D basis vectors in 5D, let's express the 5D basis vectors in 2D as well.

    Point2D twodee0 = new Point2D(plane5D0.point[0], plane5D1.point[0]);
    Point2D twodee1 = new Point2D(plane5D0.point[1], plane5D1.point[1]);
    Point2D twodee2 = new Point2D(plane5D0.point[2], plane5D1.point[2]);
    Point2D twodee3 = new Point2D(plane5D0.point[3], plane5D1.point[3]);
    Point2D twodee4 = new Point2D(plane5D0.point[4], plane5D1.point[4]);
    Point2D twodee5 = new Point2D(plane5D0.point[5], plane5D1.point[5]);

    twodee = new dimProjector(twodee0.point, twodee1.point, twodee2.point, twodee3.point, twodee4.point, twodee5.point);
    fivedee = new dimProjector(plane5D0.point, plane5D1.point);//new dimProjector(fivedeex, fivedeey);


    for (float planeN = planestarts[planeDim]; planeN < planeends[planeDim]; planeN++) {

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
            Point6D intersection =  difference.times(planeN - firstp.point[planeDim]).times(1.0/difference.point[planeDim]);
            if (intersection.dot(difference) < 0 || intersection.length() > difference.length()) {
              // Point is outside the space, do nothing
            } else {
              planecorners.add(intersection.plus(firstp));
            }
          }
        }
      }

      // OK I've got corners... what do I do with corners???
      // Could it... could it be ...? D..do I just want minima over corners?
      // I guess all I'm looking for right now is minimum values on the slice, in each higher-d dimension but planeDim.
      // O..of course they do have to be properly rounded to the needed half-integer.

      // Start values are rounded properly to give us an actual place to start
      float[] cornervals = new float[planecorners.size()];
      for (int c = 0; c < planecorners.size(); c++) {
        cornervals[c] = planecorners.get(c).point[0];
      }
      float start0 = ceil(min(cornervals)+0.5)-0.5;
      for (int c = 0; c < planecorners.size(); c++) {
        cornervals[c] = planecorners.get(c).point[1]; //<>//
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
                  intersections.add(planecorners.get(i).plus((planecorners.get(j).minus(planecorners.get(i))).times(dist)));
                }
              }
            }
          }

          // For consistency of direction, we want a convention for which side is "enter" and which "exit". Using vector [1,1,1,1,1] for direction.
          Point6D metric = new Point6D(1, 1, 1, 1, 1, 1);

          Point6D enterp = intersections.get(0);
          Point6D exitp = intersections.get(0);
          for (int i = 0; i < intersections.size(); i++) {
            if (intersections.get(i).dot(metric) < enterp.dot(metric)) enterp = intersections.get(i);
            if (intersections.get(i).dot(metric) > exitp.dot(metric)) exitp = intersections.get(i);
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

          // Starting at d = N to skip lines which have already had their turn.
          for (int d = N; d < 6; d++) {
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
            for (Float x : dists) {
              distsarray[index] = x;
              index++;
            }
            ArrayList<Float> dists2 = new ArrayList<Float>(dists);
            java.util.Collections.sort(dists2);
            float[] sorteddists = new float[dists.size()];
            index = 0;
            for (Float x : dists2) {
              sorteddists[index] = x;
              index ++;
            }
            int[] sorteddims = new int[dists.size()];
            int[] dimsarray = new int[dims.size()];
            index = 0;
            for (Integer x : dims) {
              dimsarray[index] = x;
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

              // TODO Would it be beneficial to weed out repetition in the
              // list of cells? Cells don't track their parent rhombuses right
              // now and I'm not sure they should; right now I basically
              // don't use the cells ArrayList for anything.
              cells.add(left_downCell);
              cells.add(right_downCell);
              cells.add(left_upCell);
              cells.add(right_upCell);

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
                  boolean rhombregistered = false;
                  // Rather than tracking direction and next vs. prev,
                  // for now I'm just going to rely on rhombs' ordering in "sides"
                  // lining up with neighboring blocks' ordering in "next".
                  for (Rhomb r : rhombs) {
                    Point6D difference = block.sides.get(side).center.minus(r.center);
                    float maxdivergence = max(new float[]{abs(difference.point[0]), abs(difference.point[1]), abs(difference.point[2]), abs(difference.point[3]), abs(difference.point[4]), abs(difference.point[5])});
                    if (maxdivergence < tolerance) {
                      // Rhombus already exists.
                      block.sides.set(side, r);
                      // Rhombus must have one parent.
                      Block neighbor = r.parents.get(0);
                      block.next.add(neighbor);
                      neighbor.next.set(neighbor.sides.indexOf(r), block);
                      r.parents.add(block);
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

              for (Rhomb face : block.sides) {
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
              }
            }
          }
        }
      }
    }
  }
  if (firstrun) {
    delay(initialdelay);
    firstrun = false;
  } else {
    delay(rounddelay);
  }



  while (!run) {
    delay(500);
  }
}

void mouseMoved() {
}


public class Point5D {
  public float[] point = {0, 0, 0, 0, 0};

  public Point5D (float a, float b, float c, float d, float e) {
    point = new float[]{a, b, c, d, e};
  }

  public Point5D (float[] p) {
    point = p;
  }

  public Point5D minus(Point5D p) {
    return new Point5D(point[0]-p.point[0], point[1]-p.point[1], point[2]-p.point[2], point[3]-p.point[3], point[4]-p.point[4]);
  }

  public Point5D plus(Point5D p) {
    return new Point5D(point[0]+p.point[0], point[1]+p.point[1], point[2]+p.point[2], point[3]+p.point[3], point[4]+p.point[4]);
  }

  public float dot(Point5D p) {
    return point[0]*p.point[0]+point[1]*p.point[1]+point[2]*p.point[2]+point[3]*p.point[3]+point[4]*p.point[4];
  }

  public Point5D times(float scalar) {
    return new Point5D(point[0]*scalar, point[1]*scalar, point[2]*scalar, point[3]*scalar, point[4]*scalar);
  }

  public float length() {
    return sqrt(point[0]*point[0]+point[1]*point[1]+point[2]*point[2]+point[3]*point[3]+point[4]*point[4]);
  }

  public Point5D normalized() {
    float currentLength = length();
    return new Point5D(point[0]/currentLength, point[1]/currentLength, point[2]/currentLength, point[3]/currentLength, point[4]/currentLength);
  }

  public Point5D ortho(Point5D p) {
    // Returns the component which is orthogonal to p
    Point5D pnorm = p.normalized();
    float dotprod = dot(pnorm);
    return new Point5D(point[0]-dotprod*pnorm.point[0], point[1]-dotprod*pnorm.point[1], point[2]-dotprod*pnorm.point[2], point[3]-dotprod*pnorm.point[3], point[4]-dotprod*pnorm.point[4]);
  }

  public Point5D averageWith(ArrayList<Point5D> points) {
    Point5D sum = new Point5D(new float[]{point[0], point[1], point[2], point[3], point[4]});
    for (Point5D p : points) {
      sum = sum.plus(p);
    }
    sum = sum.times(1.0/(points.size()+1));
    return sum;
  }

  public Point5D copy() {
    return new Point5D(new float[]{point[0], point[1], point[2], point[3], point[4]});
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
    return new Point6D(point[0]-p.point[0], point[1]-p.point[1], point[2]-p.point[2], point[3]-p.point[3], point[4]-p.point[4], point[5]-p.point[5]); //<>//
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

class dimProjector {
  float[][] basis;

  public dimProjector(float[] a, float[] b, float[] c, float[] d, float[] e, float[] f) {
    basis = new float[][]{a.clone(), b.clone(), c.clone(), d.clone(), e.clone(), f.clone()};
  }

  public dimProjector(float[] x, float[] y) {
    basis = new float[][]{x.clone(), y.clone()};
  }

  public Point2D project(Point6D p5d) {
    float[] p = p5d.point;
    return new Point2D((p[0]*basis[0][0]+p[1]*basis[1][0]+p[2]*basis[2][0]+p[3]*basis[3][0]+p[4]*basis[4][0]+p[5]*basis[5][0])*float(width)/(radius*float(width)/float(height)), 
      (p[0]*basis[0][1]+p[1]*basis[1][1]+p[2]*basis[2][1]+p[3]*basis[3][1]+p[4]*basis[4][1]+p[5]*basis[5][1])*float(height)/radius);
  }

  public Point6D project(Point2D p2d) {
    float[] p = p2d.point;
    return new Point6D(
      (p[0]*basis[0][0]+p[1]*basis[1][0])*radius/float(height), 
      (p[0]*basis[0][1]+p[1]*basis[1][1])*radius/float(height), 
      (p[0]*basis[0][2]+p[1]*basis[1][2])*radius/float(height), 
      (p[0]*basis[0][3]+p[1]*basis[1][3])*radius/float(height), 
      (p[0]*basis[0][4]+p[1]*basis[1][4])*radius/float(height),
      (p[0]*basis[0][5]+p[1]*basis[1][5])*radius/float(height));
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

class Chunk extends Block {
  int level;

  public Chunk(Point6D p) {
    super(p);
    level = 0;
  }
}
