/****************************************
 * Penrose Glom by Daniel Demski.
 * 
 * The actual point of this is to make sure that I understand the
 * Cut and Project method for making non-periodic tilings,
 * and see what some examples at odd angles look like. But as a 
 * first application I thought it would be nice to make a non-
 * periodic clone of 2048.
 * 
 * 
 *****************************************/
 import queasycam.*;
 
float radius = 5;//15;
float debugscale = 0.84;
float driftspeed = 0.1;

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
Point5D fivedeex = new Point5D(new float[]{1, 0.309, -0.809, -0.809, 0.309});
Point5D fivedeey = new Point5D(new float[]{0, 0.951, 0.588, -0.588, -0.951});
Point5D fivedeez = new Point5D(new float[]{1, 1, 1, 1, 1});
Point5D fivedeew = new Point5D(new float[]{0.4, 0.4, 0.4, 0.4, 0.4});

Point5D driftx = new Point5D(new float[]{random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1)});
Point5D drifty = new Point5D(new float[]{random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1)});
Point5D driftz = new Point5D(new float[]{random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1)});
Point5D driftw = new Point5D(new float[]{random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1), random(-1, 1)});
//float[] driftw = {.25,.25,.25,.25,.25};

ArrayList<Point5D> cells = new ArrayList<Point5D>();
//TODO: Using 4 of the 5 dims to store pairs of 2D points. Cheezy.
ArrayList<Point5D> edges = new ArrayList<Point5D>();
ArrayList<Rhomb> rhombs = new ArrayList<Rhomb>();
ArrayList<Point2D> rc2D = new ArrayList<Point2D>();
ArrayList<Block> blocks = new ArrayList<Block>();

//Point5D w;

float CameraX = 0;
float CameraY = 0;
float CameraZ = 0;
float CameraRX = 0;
float CameraRY = 0;
float CameraRZ = 0;

public dimProjector twodee;
public dimProjector fivedee;

float addx;
float addy;

QueasyCam camera;

void setup() {
  size(displayWidth, displayHeight, P3D);
  smooth(3);
  background(100);
  addx = (1-debugscale) * displayWidth / 3.0;
  addy = (1-debugscale) * displayHeight / 3.0;
  //camera(width/2.0,height/2.0,(height/2.0) / tan(PI*30.0 / 180.0), width/2.0, height/2.0, 0, 0, 1, 0);
  //frustum(10, -10, -10*float(displayHeight)/displayWidth, 10*float(displayHeight)/displayWidth, 10, 1000000);
  camera = new QueasyCam(this);
  camera.speed = 5;
  camera.sensitivity = 2;
}

void draw() {
  /*if (keyPressed) {
    //if (key == 'a') CameraX += 40;
    if (key == 'a') {
      //Move camera in y direction
      CameraX += 10*(cos(CameraRZ));
      CameraZ += 10*(sin(CameraRZ));
    }
    //if (key == 'e') CameraX -= 40;
    if (key == 'e') {
      //Move camera in y direction
      CameraX -= 10*(cos(CameraRZ));
      CameraZ -= 10*(sin(CameraRZ));
    }
    if (key == ',') {
      // Move camera in x direction
      CameraX += -10*cos(CameraRY)*cos(CameraRZ);
      CameraY += 10*sin(CameraRZ)*cos(CameraRY);
      CameraZ += 10*sin(CameraRY);
      //CameraZ += 500;
      //println(cos(CameraRX)+" "+cos(CameraRY)+" "+cos(CameraRZ));
    }
    if (key == 'o') {
      //Move camera in x direction
      CameraX -= -10*cos(CameraRY)*cos(CameraRZ);
      CameraY -= 10*sin(CameraRZ)*cos(CameraRY);
      CameraZ -= 10*sin(CameraRY);
      //CameraZ -= 500;
    }
  }*/
  //CameraRZ = map(mouseX,0,width,-PI,PI);
  //CameraRY = map(mouseY,0,height,-PI,PI);
  //camera(CameraX,CameraY,CameraZ,
  //        CameraX-50*cos(CameraRY)*cos(CameraRZ),CameraY+50*sin(CameraRZ)*cos(CameraRY),CameraZ+50*sin(CameraRY),
  //        0,0,1);
  
  lights();
  //translate(-width/2, -height/2);
  //println(twodee);
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

void setupRender() {
  /*rc2D = new ArrayList<Point2D>();
   for (int i=0; i < rhombs.size(); i++) {
   Rhomb rhomb = rhombs.get(i);*/
  /*Need to set up the following in BLock:
   ArrayList<Integer> axes;
   ArrayList<Block> prev;
   ArrayList<Block> next;
   ArrayList<Rhomb> sides;*/
  /*for (Rhomb r : rhombs) {
   float corner1neighbor = min(new float[]{rhomb.corner1.minus(r.corner1).length(), rhomb.corner1.minus(r.corner2).length(), 
   rhomb.corner1.minus(r.corner3).length(), rhomb.corner1.minus(r.corner4).length()});
   float corner2neighbor = min(new float[]{rhomb.corner2.minus(r.corner1).length(), rhomb.corner2.minus(r.corner2).length(), 
   rhomb.corner2.minus(r.corner3).length(), rhomb.corner2.minus(r.corner4).length()});
   float corner3neighbor = min(new float[]{rhomb.corner3.minus(r.corner1).length(), rhomb.corner3.minus(r.corner2).length(), 
   rhomb.corner3.minus(r.corner3).length(), rhomb.corner3.minus(r.corner4).length()});
   float corner4neighbor = min(new float[]{rhomb.corner4.minus(r.corner1).length(), rhomb.corner4.minus(r.corner2).length(), 
   rhomb.corner4.minus(r.corner3).length(), rhomb.corner4.minus(r.corner4).length()});
   
   if (corner1neighbor < 0.1 && corner2neighbor < 0.1 && corner3neighbor > 0.1) {
   rhomb.a1prev = r;
   //r.a1next = rhomb;
   } else if (corner3neighbor < 0.1 && corner4neighbor < 0.1 && corner1neighbor > 0.1) {
   rhomb.a1next = r;
   //r.a1prev = rhomb;
   } else if (corner1neighbor < 0.1 && corner3neighbor < 0.1 && corner2neighbor > 0.1) {
   rhomb.a2prev = r;
   //r.a2next = rhomb;
   } else if (corner2neighbor < 0.1 && corner4neighbor < 0.1 && corner1neighbor > 0.1) {
   rhomb.a2next = r;
   //r.a2prev = rhomb;
   }
   }
   rc2D.add(twodee.project(rhomb.center.minus(fivedeew)));
   rhomb.value = 0;
   //rhomb.value = i;
   }
   addValue();
   addValue();
   addValue();
   int selection = floor(random(rhombs.size()));
   rhombs.get(selection).value = 1;*/
  int selection;
  for (int loopvar = 0; loopvar < 100; loopvar++) {
    selection = floor(random(blocks.size()));
    blocks.get(selection).value = 1;
  }

  playSetup = true;
}

void addValue() {
  ArrayList<Rhomb> zeroes = new ArrayList<Rhomb>();
  for (Rhomb r : rhombs) {
    if (r.value == 0) zeroes.add(r);
  }
  int selection = floor (random(zeroes.size()));
  zeroes.get(selection).value = ceil(random(0, 2));
}

void render() {
  if (!playSetup) {
    setupRender();
  }
  background(0, 100, 0);
  for (Block block : blocks) {
    if (block.value > -1) {
      for (Rhomb face : block.sides) {
        // TODO shouldn't have to re-normalize each time; make fivedee0 etc. global.
        // TODO actually shouldn't have to re-calculate any of this each time....
        PVector corner1_3D = new PVector(face.corner1.minus(fivedeew).dot(fivedeex.normalized()), face.corner1.minus(fivedeew).dot(fivedeey.normalized()), face.corner1.minus(fivedeew).dot(fivedeez.normalized()));
        PVector corner2_3D = new PVector(face.corner2.minus(fivedeew).dot(fivedeex.normalized()), face.corner2.minus(fivedeew).dot(fivedeey.normalized()), face.corner2.minus(fivedeew).dot(fivedeez.normalized()));
        PVector corner3_3D = new PVector(face.corner3.minus(fivedeew).dot(fivedeex.normalized()), face.corner3.minus(fivedeew).dot(fivedeey.normalized()), face.corner3.minus(fivedeew).dot(fivedeez.normalized()));
        PVector corner4_3D = new PVector(face.corner4.minus(fivedeew).dot(fivedeex.normalized()), face.corner4.minus(fivedeew).dot(fivedeey.normalized()), face.corner4.minus(fivedeew).dot(fivedeez.normalized()));
        beginShape();
        vertex(corner1_3D.x*10, corner1_3D.y*10, corner1_3D.z*10);
        vertex(corner2_3D.x*10, corner2_3D.y*10, corner2_3D.z*10);
        vertex(corner4_3D.x*10, corner4_3D.y*10, corner4_3D.z*10);
        vertex(corner3_3D.x*10, corner3_3D.y*10, corner3_3D.z*10);
        endShape(CLOSE);
      }
    }
  }
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

  final float pixelradius = float(height)/radius;
  background(0, 100, 0);
  stroke(100, 100, 100);
  //fivedeex, fivedeey and fivedeez determine the tilt of our plane in higher-d space.
  //fivedeew determines the last dimension, and serves as the 3D origin.
  fivedeex = fivedeex.plus(driftx.times(driftspeed*0.03));
  fivedeey = fivedeey.plus(drifty.times(driftspeed*0.03));
  fivedeez = fivedeez.plus(driftz.times(driftspeed*0.03));
  fivedeew = fivedeew.plus(driftw.times(driftspeed*0.03));
  for (int i = 0; i < 5; i++) {
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
  Point5D fivedee0 = fivedeex.normalized();
  Point5D fivedee1 = fivedeey.ortho(fivedee0).normalized();
  Point5D fivedee2 = fivedeez.ortho(fivedee0).ortho(fivedee1).normalized();

  // We then make our original vectors line up to these.
  // Sizes here determine bounded area of the render.
  fivedeex = fivedee0.times(radius*float(width)/float(height));
  fivedeey = fivedee1.times(radius);
  fivedeez = fivedee2.times(radius*float(width)/float(height));

  /* Old 2D code, delete once I'm sure 3D is okay
   // Then normalize their distance from the origin
   float fdxlength = fivedeex[0]*fivedeex[0]+fivedeex[1]*fivedeex[1]+fivedeex[2]*fivedeex[2]+fivedeex[3]*fivedeex[3]+fivedeex[4]*fivedeex[4];
   float fdylength = fivedeey[0]*fivedeey[0]+fivedeey[1]*fivedeey[1]+fivedeey[2]*fivedeey[2]+fivedeey[3]*fivedeey[3]+fivedeey[4]*fivedeey[4];
   for (int i=0; i<5; i++) {
   fivedee0[i] = fivedeex[i] / (sqrt(fdxlength));//fivedeex[i] / (sqrt(fdxlength)*pixelradius);
   fivedeex[i] = fivedeex[i]*radius*(float(width)/float(height))/ sqrt(fdxlength);
   fivedee1[i] = fivedeey[i] / (sqrt(fdylength));
   //fivedeey[i] = fivedeey[i]*radius/ sqrt(fdylength);
   }
   // make the second point orthogonal to the first
   //float dotprod = fivedeex[0]*fivedeey[0]+fivedeex[1]*fivedeey[1]+fivedeex[2]*fivedeey[2]+fivedeex[3]*fivedeey[3]+fivedeex[4]*fivedeey[4];
   float dotprod = fivedee0[0]*fivedee1[0]+fivedee0[1]*fivedee1[1]+fivedee0[2]*fivedee1[2]+fivedee0[3]*fivedee1[3]+fivedee0[4]*fivedee1[4];
   //float nonorthlength = dotprod/(radius*radius*(width/height)*(width/height));
   fdylength = 0;
   for (int i=0; i<5; i++) {
   //fivedeey[i] = fivedeey[i] - nonorthlength*fivedeex[i];
   fivedee1[i] = fivedee1[i] - dotprod*fivedee0[i];
   fdylength += fivedee1[i]*fivedee1[i];
   }
   for (int i=0; i<5; i++) {
   //fivedeey[i] = fivedeey[i]*radius/ sqrt(fdylength);
   //fivedee1[i] = fivedeey[i] / (sqrt(fdylength));
   fivedee1[i] = fivedee1[i]/(sqrt(fdylength));
   fivedeey[i] = fivedee1[i]*radius;
   }*/

  // Now we need to iterate over all the planes which fall inside our space, checking for intersections.

  // (as below w/ lines:) start values are rounded properly to get the smallest half-integer actually defining a plane
  float planestart0 = ceil(0.5 + fivedeew.point[0] + min(new float[]{0, fivedeex.point[0]}) + min(new float[]{0, fivedeey.point[0]}) + min(new float[]{0, fivedeez.point[0]})) - 0.5;
  float planestart1 = ceil(0.5 + fivedeew.point[1] + min(new float[]{0, fivedeex.point[1]}) + min(new float[]{0, fivedeey.point[1]}) + min(new float[]{0, fivedeez.point[1]})) - 0.5;
  float planestart2 = ceil(0.5 + fivedeew.point[2] + min(new float[]{0, fivedeex.point[2]}) + min(new float[]{0, fivedeey.point[2]}) + min(new float[]{0, fivedeez.point[2]})) - 0.5;
  float planestart3 = ceil(0.5 + fivedeew.point[3] + min(new float[]{0, fivedeex.point[3]}) + min(new float[]{0, fivedeey.point[3]}) + min(new float[]{0, fivedeez.point[3]})) - 0.5;
  float planestart4 = ceil(0.5 + fivedeew.point[4] + min(new float[]{0, fivedeex.point[4]}) + min(new float[]{0, fivedeey.point[4]}) + min(new float[]{0, fivedeez.point[4]})) - 0.5;

  float planeends0 = fivedeew.point[0] + max(new float[]{0, fivedeex.point[0]}) + max(new float[]{0, fivedeey.point[0]}) + max(new float[]{0, fivedeez.point[0]});
  float planeends1 = fivedeew.point[0] + max(new float[]{0, fivedeex.point[1]}) + max(new float[]{0, fivedeey.point[1]}) + max(new float[]{0, fivedeez.point[1]});
  float planeends2 = fivedeew.point[0] + max(new float[]{0, fivedeex.point[2]}) + max(new float[]{0, fivedeey.point[2]}) + max(new float[]{0, fivedeez.point[2]});
  float planeends3 = fivedeew.point[0] + max(new float[]{0, fivedeex.point[3]}) + max(new float[]{0, fivedeey.point[3]}) + max(new float[]{0, fivedeez.point[3]});
  float planeends4 = fivedeew.point[0] + max(new float[]{0, fivedeex.point[4]}) + max(new float[]{0, fivedeey.point[4]}) + max(new float[]{0, fivedeez.point[4]});

  float[] planestarts = new float[]{planestart0, planestart1, planestart2, planestart3, planestart4};
  float[] planeends = new float[]{planeends0, planeends1, planeends2, planeends3, planeends4};

  // Having expressed our 3D basis vectors in 5D, let's express the 5D basis vectors in 3D.

  PVector threedee0 = new PVector(fivedee0.point[0], fivedee1.point[0], fivedee2.point[0]);
  PVector threedee1 = new PVector(fivedee0.point[1], fivedee1.point[1], fivedee2.point[1]);
  PVector threedee2 = new PVector(fivedee0.point[2], fivedee1.point[2], fivedee2.point[2]);
  PVector threedee3 = new PVector(fivedee0.point[3], fivedee1.point[3], fivedee2.point[3]);
  PVector threedee4 = new PVector(fivedee0.point[4], fivedee1.point[4], fivedee2.point[4]);

  // Iterate over the dimension we hold constant
  for (int planeDim = 0; planeDim < 5; planeDim++) {
    // Iterate over the value at which we hold planeDim constant
    for (float planeN = planestarts[planeDim]; planeN < planeends[planeDim]; planeN++) {

      // We are on a plane which slices the rectangular prism which is our 3D space.

      // Choosing an arbitrary origin for now. The slice could be various strange shapes so 
      // it's not too useful to parameterize conveniently.
      Point5D plane5Dw = new Point5D(0, 0, 0, 0, 0);
      plane5Dw.point[planeDim] = planeN;

      Point5D orthox = fivedeex.ortho(plane5Dw);
      Point5D orthoy = fivedeey.ortho(plane5Dw);
      Point5D orthoz = fivedeez.ortho(plane5Dw);

      Point5D plane5D0 = new Point5D(0, 0, 0, 0, 0);
      Point5D plane5D1 = new Point5D(0, 0, 0, 0, 0);

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

      twodee = new dimProjector(twodee0.point, twodee1.point, twodee2.point, twodee3.point, twodee4.point);
      fivedee = new dimProjector(plane5D0.point, plane5D1.point);//new dimProjector(fivedeex, fivedeey);

      // Now we need to find all Voronoi cells of the 5D lattice which intersect our plane.


      // Clear out the arrays
      cells = new ArrayList<Point5D>();
      edges = new ArrayList<Point5D>();
      rhombs = new ArrayList<Rhomb>();

      // Halfway between lattice points are hyperplanes defined by having a particular half-integer value in a particular one of the five dimensions. 
      // These hyperplanes intersect our plane (the screen) in a line; five parallel sets of lines. Where these lines intersect, we're switching from 
      // one Voronoi cell to another. If we think of each line as being part of the next larger-valued cell (ie, round up when choosing nearest 
      // integer), we can start at the beginning of a line and determine which cell it's in, then walk up the line changing just one dimension at 
      // each intersection. Doing this to every line will be redundant but won't leave any cells behind... provided we remember to round down also 
      // when looking at the lines with the lowest values.

      // Such a search will find intersections between the first set of lines and the 2nd, 3rd, 4th, 5th; then intersections between the second and 
      // the 1st, 3rd, fourth, fifth, &c. &c. In order to avoid redundancy, what we need to do is only check for intersections with higher-index 
      // dimensions.

      // Gotta find the edges of our slice
      ArrayList<Point5D> planecorners = new ArrayList<Point5D>();

      // We'll find corners one rectangular-prism-edge at a time. Starting with the 3D axes
      if (fivedeex.point[planeDim] != 0.0) { //<>//
        //Point5D intersection = fivedeew.plus(fivedeex.times((planeN - fivedeew.point[planeDim])/fivedeex.point[planeDim]));
        // NOTE: These "interesection" variables exclude W so aren't in "proper 5D"
        Point5D intersection = fivedee0.times(planeN - fivedeew.point[planeDim]).times(1.0/fivedee0.point[planeDim]);
        if (intersection.dot(fivedeex) < 0 || intersection.length() > fivedeex.length()) {
          // Point is outside the rect, do nothing
        } else {
          //Convert to proper 5D
          planecorners.add(intersection.plus(fivedeew));
        }
      }
      if (fivedeey.point[planeDim] != 0.0) {
        //Point5D intersection = fivedeew.plus(fivedeey.times((planeN - fivedeew.point[planeDim])/fivedeey.point[planeDim]));
        Point5D intersection = fivedee1.times(planeN - fivedeew.point[planeDim]).times(1.0/fivedee1.point[planeDim]);
        if (intersection.dot(fivedeey) < 0 || intersection.length() > fivedeey.length()) {
          // Point is outside the rect, do nothing
        } else {
          planecorners.add(intersection.plus(fivedeew));
        }
      }
      if (fivedeez.point[planeDim] != 0.0) {
        //Point5D intersection = fivedeew.plus(fivedeez.times((planeN - fivedeew.point[planeDim])/fivedeez.point[planeDim]));
        Point5D intersection = fivedee2.times(planeN - fivedeew.point[planeDim]).times(1.0/fivedee2.point[planeDim]);
        if (intersection.dot(fivedeez) < 0 || intersection.length() > fivedeez.length()) {
          // Point is outside the rect, do nothing
        } else {
          planecorners.add(intersection.plus(fivedeew));
        }
      }
      // Now the far edges
      Point5D m = fivedeew.plus(fivedeex).plus(fivedeey).plus(fivedeez);
      if (fivedeex.point[planeDim] != 0.0) {
        //Point5D intersection = m.plus(fivedeex.times(-(planeN - m.point[planeDim])/fivedeex.point[planeDim]));
        // Coordinates are measured from "m" backwards
        Point5D intersection = fivedee0.times(m.point[planeDim] - planeN).times(1.0/fivedee0.point[planeDim]);
        if (intersection.dot(fivedeex) < 0 || intersection.length() > fivedeex.length()) {
          // Point is outside the rect, do nothing
        } else {
          planecorners.add(m.minus(intersection));
        }
      }
      if (fivedeey.point[planeDim] != 0.0) {
        //Point5D intersection = m.plus(fivedeey.times(-(planeN - m.point[planeDim])/fivedeey.point[planeDim]));
        Point5D intersection = fivedee1.times(m.point[planeDim] - planeN).times(1.0/fivedee1.point[planeDim]);
        if (intersection.dot(fivedeey) < 0 || intersection.length() > fivedeey.length()) {
          // Point is outside the rect, do nothing
        } else {
          planecorners.add(m.minus(intersection));
        }
      }
      if (fivedeez.point[planeDim] != 0.0) {
        //Point5D intersection = m.plus(fivedeez.times(-(planeN - m.point[planeDim])/fivedeez.point[planeDim]));
        Point5D intersection = fivedee2.times(m.point[planeDim] - planeN).times(1.0/fivedee2.point[planeDim]);
        if (intersection.dot(fivedeez) < 0 || intersection.length() > fivedeez.length()) {
          // Point is outside the rect, do nothing
        } else {
          planecorners.add(m.minus(intersection));
        }
      }
      // Now the trickier edges...
      // These first two are measured from the x axis' bigger corner
      Point5D xcorner = fivedeex.copy();
      if (fivedeey.point[planeDim] != 0.0) {
        Point5D intersection = fivedee1.times(planeN - xcorner.point[planeDim]).times(1.0/fivedee1.point[planeDim]);
        if (intersection.dot(fivedeey) < 0 || intersection.length() > fivedeey.length()) {
          // Point is outside the rect, do nothing
        } else {
          planecorners.add(intersection.plus(xcorner));
        }
      }
      if (fivedeez.point[planeDim] != 0.0) {
        Point5D intersection = fivedee2.times(planeN - xcorner.point[planeDim]).times(1.0/fivedee2.point[planeDim]);
        if (intersection.dot(fivedeez) < 0 || intersection.length() > fivedeez.length()) {
          // Point is outside the rect, do nothing
        } else {
          planecorners.add(intersection.plus(xcorner));
        }
      }
      // Now measuring from the other y-axis corner
      Point5D ycorner = fivedeey.copy();
      if (fivedeex.point[planeDim] != 0.0) {
        Point5D intersection = fivedee0.times(planeN - ycorner.point[planeDim]).times(1.0/fivedee0.point[planeDim]);
        if (intersection.dot(fivedeex) < 0 || intersection.length() > fivedeex.length()) {
          // Point is outside the rect, do nothing
        } else {
          planecorners.add(intersection.plus(ycorner));
        }
      }
      if (fivedeez.point[planeDim] != 0.0) {
        Point5D intersection = fivedee2.times(planeN - ycorner.point[planeDim]).times(1.0/fivedee2.point[planeDim]);
        if (intersection.dot(fivedeez) < 0 || intersection.length() > fivedeez.length()) {
          // Point is outside the rect, do nothing
        } else {
          planecorners.add(intersection.plus(ycorner));
        }
      }
      // Now measuring from the other z-axis corner
      Point5D zcorner = fivedeez.copy();
      if (fivedeex.point[planeDim] != 0.0) {
        Point5D intersection = fivedee0.times(planeN - zcorner.point[planeDim]).times(1.0/fivedee0.point[planeDim]);
        if (intersection.dot(fivedeex) < 0 || intersection.length() > fivedeex.length()) {
          // Point is outside the rect, do nothing
        } else {
          planecorners.add(intersection.plus(zcorner));
        }
      }
      if (fivedeey.point[planeDim] != 0.0) {
        Point5D intersection = fivedee1.times(planeN - zcorner.point[planeDim]).times(1.0/fivedee1.point[planeDim]);
        if (intersection.dot(fivedeey) < 0 || intersection.length() > fivedeey.length()) {
          // Point is outside the rect, do nothing
        } else {
          planecorners.add(intersection.plus(zcorner));
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


      /*float start0 = ceil(min(new float[]{fivedeew[0], fivedeew[0]+fivedeex[0], fivedeew[0]+fivedeey[0], fivedeew[0]+fivedeex[0]+fivedeey[0]})+0.5)-0.5;
       float start1 = ceil(min(new float[]{fivedeew[1], fivedeew[1]+fivedeex[1], fivedeew[1]+fivedeey[1], fivedeew[1]+fivedeex[1]+fivedeey[1]})+0.5)-0.5;
       float start2 = ceil(min(new float[]{fivedeew[2], fivedeew[2]+fivedeex[2], fivedeew[2]+fivedeey[2], fivedeew[2]+fivedeex[2]+fivedeey[2]})+0.5)-0.5;
       float start3 = ceil(min(new float[]{fivedeew[3], fivedeew[3]+fivedeex[3], fivedeew[3]+fivedeey[3], fivedeew[3]+fivedeex[3]+fivedeey[3]})+0.5)-0.5;
       float start4 = ceil(min(new float[]{fivedeew[4], fivedeew[4]+fivedeex[4], fivedeew[4]+fivedeey[4], fivedeew[4]+fivedeex[4]+fivedeey[4]})+0.5)-0.5;*/

      // End values are just a cutoff //<>//
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

      /*float end0 = max(new float[]{fivedeew[0], fivedeew[0]+fivedeex[0], fivedeew[0]+fivedeey[0], fivedeew[0]+fivedeex[0]+fivedeey[0]});
       float end1 = max(new float[]{fivedeew[1], fivedeew[1]+fivedeex[1], fivedeew[1]+fivedeey[1], fivedeew[1]+fivedeex[1]+fivedeey[1]});
       float end2 = max(new float[]{fivedeew[2], fivedeew[2]+fivedeex[2], fivedeew[2]+fivedeey[2], fivedeew[2]+fivedeex[2]+fivedeey[2]});
       float end3 = max(new float[]{fivedeew[3], fivedeew[3]+fivedeex[3], fivedeew[3]+fivedeey[3], fivedeew[3]+fivedeex[3]+fivedeey[3]});
       float end4 = max(new float[]{fivedeew[4], fivedeew[4]+fivedeex[4], fivedeew[4]+fivedeey[4], fivedeew[4]+fivedeex[4]+fivedeey[4]});*/

      float[] dimstarts = {start0, start1, start2, start3, start4};
      float[] dimends   = {end0, end1, end2, end3, end4  };

      println("Plane slices: "+(planeDim*20+(planeN-planestarts[planeDim])*20/(planeends[planeDim]-planestarts[planeDim]))+"%");


      for (int N = 0; N < 5; N++) {
        //TODO: I think there's stuff I do every time through the loop which I could do outside the loop. Goes for other loops too
        //Skip this iteration if we're on the dimension which generated the plane.
        if (N == planeDim) continue;

        for (float dimN = dimstarts[N]; dimN <= dimends[N]; dimN += 1) {
          // We are on a line where the Nth 5D coordinate takes value dimN (and because of the plane, planeDimth coordinate takes value planeN).
          // Find where this line enters and leaves the cut.
          // "enter" and "exit" will be points in proper 5D, ie, we include the offset "plane5Dw"

          float[] enter = new float[5];
          float[] exit = new float[5];
          float[] enter2D = new float[2];
          float[] exit2D = new float[2];


          // We have corners to work with, not edges; strategy will be to generate the line segments between 
          // these, find intersections, and then take the extreme values.
          // TODO: Shouldn't need to use lines between all corners. Take extreme corners on either side? Corners which share some 5D values?
          ArrayList<Point5D> intersections = new ArrayList<Point5D>();
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
          Point5D metric = new Point5D(1, 1, 1, 1, 1);

          Point5D enterp = intersections.get(0); //<>//
          Point5D exitp = intersections.get(0);
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
          enter2D = twodee.project(enterp.minus(plane5Dw)).point;
          exit2D = twodee.project(exitp.minus(plane5Dw)).point;

          /*Boolean entered = false;
           float dist;
           
           
           if ((fivedeew[N] <= dimN && dimN <= fivedeew[N]+fivedeex[N]) || (fivedeex[N]+fivedeew[N] <= dimN && dimN <= fivedeew[N])) {
           // If dimN is between the starting and ending values of the "x axis" (screen top), 
           // then our line intersects there.
           dist = (dimN-fivedeew[N])/fivedeex[N];
           enter = new float[]{fivedeew[0]+fivedeex[0]*dist, fivedeew[1]+fivedeex[1]*dist, fivedeew[2]+fivedeex[2]*dist, fivedeew[3]+fivedeex[3]*dist, fivedeew[4]+fivedeex[4]*dist};//Note, the Nth entry here had better equal dimN.
           enter2D = new float[]{dist*float(width), 0};
           entered = true;
           }
           if ((fivedeew[N] <= dimN && dimN <= fivedeey[N]+fivedeew[N]) || (fivedeey[N]+fivedeew[N] <= dimN && dimN <= fivedeew[N])) {
           dist = (dimN-fivedeew[N])/fivedeey[N];
           if (!entered) {
           enter = new float[]{fivedeew[0]+fivedeey[0]*dist, fivedeew[1]+fivedeey[1]*dist, fivedeew[2]+fivedeey[2]*dist, fivedeew[3]+fivedeey[3]*dist, fivedeew[4]+fivedeey[4]*dist};
           enter2D = new float[]{0, dist*float(height)};
           entered = true;
           } else {
           // Then this is the exit point
           exit = new float[]{fivedeew[0]+fivedeey[0]*dist, fivedeew[1]+fivedeey[1]*dist, fivedeew[2]+fivedeey[2]*dist, fivedeew[3]+fivedeey[3]*dist, fivedeew[4]+fivedeey[4]*dist};
           exit2D = new float[]{0, dist*float(height)};
           }
           }
           if ((fivedeex[N]+fivedeew[N] <= dimN && dimN <= fivedeex[N] + fivedeey[N]+fivedeew[N]) || (fivedeex[N] + fivedeey[N] + fivedeew[N] <= dimN && dimN <= fivedeex[N] + fivedeew[N])) {
           dist = (dimN - fivedeex[N] - fivedeew[N])/fivedeey[N];
           if (!entered) {
           enter = new float[]{fivedeew[0]+fivedeex[0]+fivedeey[0]*dist, fivedeew[1]+fivedeex[1] + fivedeey[1]*dist, fivedeew[2]+fivedeex[2] + fivedeey[2]*dist, fivedeew[3]+fivedeex[3] + fivedeey[3]*dist, fivedeew[4]+fivedeex[4] + fivedeey[4]*dist};
           enter2D = new float[]{float(width), dist*float(height)};
           entered = true;
           } else {
           // Then this is the exit point
           exit = new float[]{fivedeew[0]+fivedeex[0] + fivedeey[0]*dist, fivedeew[1]+fivedeex[1] + fivedeey[1]*dist, fivedeew[2]+fivedeex[2] + fivedeey[2]*dist, fivedeew[3]+fivedeex[3] + fivedeey[3]*dist, fivedeew[4]+fivedeex[4] + fivedeey[4]*dist};
           exit2D = new float[]{float(width), dist*float(height)};
           }
           }
           if ((fivedeey[N]+fivedeew[N] <= dimN && dimN <= fivedeex[N] + fivedeey[N] + fivedeew[N]) || (fivedeex[N] + fivedeey[N] + fivedeew[N] <= dimN && dimN <= fivedeey[N] + fivedeew[N])) {
           dist = (dimN - fivedeey[N] - fivedeew[N])/fivedeex[N];
           // This could only be the exit point (we checked three sides already)
           exit = new float[]{fivedeew[0]+fivedeey[0] + fivedeex[0]*dist, fivedeew[1]+fivedeey[1] + fivedeex[1]*dist, fivedeew[2]+fivedeey[2] + fivedeex[2]*dist, fivedeew[3]+fivedeey[3] + fivedeex[3]*dist, fivedeew[4]+fivedeey[4] + fivedeex[4]*dist};
           exit2D = new float[]{dist*float(width), float(height)};
           }*/

          // Testing that enter and enter2D agree
          //TODO These seem to diverge occasionally, e.g. by five or occasionally 30. Why? Perhaps there's a typo in one of the cases above.
          //Point5D enterAgain = fivedee.project(new Point2D(enter2D));
          //Point2D enter2DAgain = twodee.project(new Point5D(enter));
          //println(str(enter2D[0]-enter2DAgain.point[0]+enter2D[1]-enter2DAgain.point[1])+" "
          //  +str(enter[0]+enter[1]+enter[2]+enter[3]+enter[4]-enterAgain.point[0]-enterAgain.point[1]-enterAgain.point[2]-enterAgain.point[3]-enterAgain.point[4]));


          /*
          Point5D enterp = new Point5D(enter);
           Point5D exitp = new Point5D(exit);
           Point5D metric = new Point5D(1, 1, 1, 1, 1);
           
           if (enterp.dot(metric) > exitp.dot(metric)) {
           float[] temp = new float[]{enter[0], enter[1], enter[2], enter[3], enter[4]};
           float[] temp2D = new float[]{enter2D[0], enter2D[1]};
           enter = exit;
           enter2D = exit2D;
           exit = temp;
           exit2D = temp2D;
           }*/

          // Next we need to find all crossing-points between 'enter' and 'exit'. These are just half-integer values of any of the four non-fixed dimensions; 
          // but for each one we need to note how far along our line it occurs. Each crossing point tells us a particular cell does intersect our plane, and 
          // is adjacent (shares a face) with the previous cell. (Really, each crossing point exhibits eight cells which intersect our 3D space and twelve 
          // adjacencies.)


          float[] linevector = {exit[0]-enter[0], exit[1]-enter[1], exit[2]-enter[2], exit[3]-enter[3], exit[4]-enter[4]};

          //ArrayList<Point2D> distsanddims = new ArrayList<Point2D>();
          ArrayList<Float> dists = new ArrayList<Float>();
          ArrayList<Integer> dims = new ArrayList<Integer>();

          //TODO: Would be better not to redundantly note crossings. This requires properly using the "intersections" thing.
          //TODO: Sometimes a crossing involves more than two lines; this can especially happen at the edge, and it causes errors which propagate across
          // the rest of the line that's being stepped down. Come up with a way to handle this properly.

          for (int d = 0; d < 5; d++) {
            if (d != N && d != planeDim) {
              // We want to catch any included half-integer values, so we'll subtract 0.5 and take all integer values of that range.
              for (int i = ceil(min(enter[d], exit[d])-0.5); i <= max(enter[d], exit[d])-0.5; i++) {//I changed from floor to ceil here. We don't want an intersection which isn't onscreen.//TODO This change fixed stuff but I don't see why it did! Reverse engineer bug!!
                //ArrayList<Point2D> coercd = (ArrayList<Point2D>)intersections[N][d];
                //coercd.add(new Point2D(dimN,i+0.5));

                float dist = ((float(i)+0.5)-(enter[d]))/linevector[d];

                //distsanddims.add(new Point2D(dist,d));
                dists.add(dist);
                dims.add(d);

                //ellipseMode(CENTER);
                //fill(d*50);
                //debugellipse(enter2D[0]+dist*(exit2D[0]-enter2D[0]), enter2D[1]+dist*(exit2D[1]-enter2D[1]), 10,10);
                //fill(200);
              }
            }
          }

          // Then sort crossings by how far along they occur.


          //distsanddims.sort(Point2D.Lexico);
          //distsanddims.sort();
          //java.util.Collections.sort(distsanddims);
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
            //int numdds = distsanddims.size();
            //Point2D[] dds = (Point2D[])distsanddims.toArray();

            // Then step through each one, iterating the associated dimension in the correct direction to get the right latticepoint.

            Point5D left_downCell = new Point5D(round(enter[0]), round(enter[1]), round(enter[2]), round(enter[3]), round(enter[4]));
            // We have to add or subtract a bit to ensure we fall the desired direction for each starting cell. 
            left_downCell.point[N] = round(enter[N]+0.01);
            left_downCell.point[planeDim] = round(enter[planeDim]-0.01);

            Point5D right_downCell = new Point5D(round(enter[0]), round(enter[1]), round(enter[2]), round(enter[3]), round(enter[4]));
            right_downCell.point[N] = round(enter[N]-0.01);
            right_downCell.point[planeDim] = round(enter[planeDim]-0.01);

            Point5D left_upCell = new Point5D(round(enter[0]), round(enter[1]), round(enter[2]), round(enter[3]), round(enter[4]));
            left_upCell.point[N] = round(enter[N]+0.01);
            left_upCell.point[planeDim] = round(enter[planeDim]+0.01);

            Point5D right_upCell = new Point5D(round(enter[0]), round(enter[1]), round(enter[2]), round(enter[3]), round(enter[4]));
            right_upCell.point[N] = round(enter[N]-0.01);
            right_upCell.point[planeDim] = round(enter[planeDim]+0.01);

            

            cells.add(left_downCell); //<>//
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

              //println("ok..."+);

              Point5D oldLeftDownCell = left_downCell;
              Point5D oldRightDownCell = right_downCell;
              Point5D oldLeftUpCell = left_upCell;
              Point5D oldRightUpCell = right_upCell;

              //TODO Floating point error could build up as I add and subtract integers here; could be better off using integers.
              left_downCell = left_downCell.copy();
              right_downCell = right_downCell.copy();
              left_upCell = left_upCell.copy();
              right_upCell = right_upCell.copy();
              left_downCell.point[dim] += 1*dir;
              right_downCell.point[dim] += 1*dir;
              left_upCell.point[dim] += 1*dir;
              right_upCell.point[dim] += 1*dir;
              cells.add(left_downCell);
              cells.add(right_downCell);
              cells.add(left_upCell);
              cells.add(right_upCell);

              // Our eight cell-centers define a parallelepiped (of course in 5D it's a cube). In dim N, the left cells 
              // lie in the positive direction from the right. In planeDim, the up cells lie in the positive direction 
              // from the down.
              // In dim "dim", the new cells lie in the "dir" direction from the old.
              // We want to note the parallelepiped, and order the corners according to a convention:
              //Point5D corner1;//negative in both axes; (-.5,-.5)
              //Point5D corner2;//(-.5,.5)
              //Point5D corner3;//(.5,-.5)
              //Point5D corner4;//(.5,.5)
              // Actually can't use "dir". Gotta use the arbitrary score of the line we're crossing
              /*Point5D xconst = new Point5D(fivedee0).times(1.0/fivedee0[dim]);
               Point5D yconst = new Point5D(fivedee1).times(1.0/fivedee1[dim]);
               float dir3 = xconst.dot(metric) < yconst.dot(metric) ? 1 : -1;
               float dir4 = xconst.point[N] < yconst.point[N] ? 1 : -1;
               Point5D unit = new Point5D(new float[]{0, 0, 0, 0, 0});
               unit.point[dim]=dir;*/
              //Rhomb rhomb = (dir3*dir4 > 0) ? new Rhomb(oldRightCell, oldLeftCell, rightCell, leftCell) : new Rhomb(oldLeftCell, oldRightCell, leftCell, rightCell);
              //Rhomb rhomb = (dir3 > 0) ? new Rhomb(oldRightCell, oldLeftCell, rightCell, leftCell) : new Rhomb(rightCell, leftCell, oldRightCell, oldLeftCell);

              // Actually for now I'm going to ignore all that and do completely arbitrary directions.
              // I'll try and fix it if it turns out those conventions still matter.
              // TODO hmm... looks like it would provide a more efficient way to track adjacency?

              ArrayList<Point5D> the_others = new ArrayList<Point5D>();
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
                Point5D difference = b.center.minus(block.center);
                float maxdivergence = max(new float[]{abs(difference.point[0]), abs(difference.point[1]), abs(difference.point[2]), abs(difference.point[3]), abs(difference.point[4])});
                if (maxdivergence < 0.001) {//TODO Apparently we get floating point error around 0.005, at least w/in the "enter" variable
                  blockregistered = true;
                  prev = b;
                }
              }
              if (!blockregistered) {
                blocks.add(block);
                // This ordering of the axes - (N, planeDim, dim) - will be used when interpreting prev and next.
                block.axes = new ArrayList<Integer>(java.util.Arrays.asList(new Integer[]{N, planeDim, dim}));
                block.sides.add(new Rhomb(oldLeftDownCell.copy(),  oldRightDownCell.copy(), oldLeftUpCell.copy(),  oldRightUpCell.copy()));// old face
                block.sides.add(new Rhomb(oldLeftDownCell.copy(),  left_downCell.copy(),    oldLeftUpCell.copy(),  left_upCell.copy()));// left face
                block.sides.add(new Rhomb(right_downCell.copy(),   left_downCell.copy(),    right_upCell.copy(),   left_upCell.copy()));// new face
                block.sides.add(new Rhomb(right_downCell.copy(),   oldRightDownCell.copy(), right_upCell.copy(),   oldRightUpCell.copy()));// right face
                block.sides.add(new Rhomb(oldLeftUpCell.copy(),    oldRightUpCell.copy(),   left_upCell.copy(),    right_upCell.copy()));// up face
                block.sides.add(new Rhomb(oldLeftDownCell.copy(),  oldRightDownCell.copy(), left_downCell.copy(),  right_downCell.copy()));// down face
              }


              //println("still fine...");

              /*Point2D leend = twodee.project(leftCell.minus(w));
               Point2D reend = twodee.project(rightCell.minus(w));
               
               //println("hang in there");
               
               ledge.point[0] = lebegin.point[0];
               ledge.point[1] = lebegin.point[1];
               ledge.point[2] = leend.point[0];
               ledge.point[3] = leend.point[1];
               
               redge.point[0] = rebegin.point[0];
               redge.point[1] = rebegin.point[1];
               redge.point[2] = reend.point[0];
               redge.point[3] = reend.point[1];
               
               //println("you with me?");
               
               edges.add(ledge);
               edges.add(redge);
               
               
               Point5D ow = w.ortho(new Point5D(fivedee0));
               ow = ow.ortho(new Point5D(fivedee1));
               Point5D own = ow.normalized();
               */

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
    return new Point6D(new float[]{point[0], point[1], point[2], point[3], point[4]});
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

  public dimProjector(float[] a, float[] b, float[] c, float[] d, float[] e) {
    basis = new float[][]{a.clone(), b.clone(), c.clone(), d.clone(), e.clone()};
  }

  public dimProjector(float[] x, float[] y) {
    basis = new float[][]{x.clone(), y.clone()};
  }

  public Point2D project(Point5D p5d) {
    float[] p = p5d.point;
    return new Point2D((p[0]*basis[0][0]+p[1]*basis[1][0]+p[2]*basis[2][0]+p[3]*basis[3][0]+p[4]*basis[4][0])*float(width)/(radius*float(width)/float(height)), 
      (p[0]*basis[0][1]+p[1]*basis[1][1]+p[2]*basis[2][1]+p[3]*basis[3][1]+p[4]*basis[4][1])*float(height)/radius);
  }

  public Point5D project(Point2D p2d) {
    float[] p = p2d.point;
    return new Point5D((p[0]*basis[0][0]+p[1]*basis[1][0])*radius/float(height), (p[0]*basis[0][1]+p[1]*basis[1][1])*radius/float(height), 
      (p[0]*basis[0][2]+p[1]*basis[1][2])*radius/float(height), (p[0]*basis[0][3]+p[1]*basis[1][3])*radius/float(height), 
      (p[0]*basis[0][4]+p[1]*basis[1][4])*radius/float(height));
  }
}

class Rhomb {
  int axis1;
  int axis2;
  Rhomb a1prev;
  Rhomb a1next;
  Rhomb a2prev;
  Rhomb a2next;
  Point5D corner1;//negative in both axes; (-.5,-.5)
  Point5D corner2;//(-.5,.5)
  Point5D corner3;//(.5,-.5)
  Point5D corner4;//(.5,.5)
  Point5D center;
  int value;
  int nextValue;

  public Rhomb(Point5D c1, Point5D c2, Point5D c3, Point5D c4) {
    corner1 = c1;
    corner2 = c2;
    corner3 = c3;
    corner4 = c4;
    center = (c1.plus(c2.plus(c3.plus(c4)))).times(0.25);
    a1prev = null;
    a2prev = null;
    a1next = null;
    a2next = null;
  }
}

class Block {
  ArrayList<Integer> axes;
  ArrayList<Block> prev;
  ArrayList<Block> next;
  ArrayList<Rhomb> sides;
  Point5D center;
  int value;
  int nextValue;

  public Block(Point5D p) {
    axes = new ArrayList<Integer>();
    prev = new ArrayList<Block>();
    next = new ArrayList<Block>();
    sides = new ArrayList<Rhomb>();
    center = p;
    value = 0;
    nextValue = -1;
  }
}
