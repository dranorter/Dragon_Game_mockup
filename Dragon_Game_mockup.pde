/**************************************** //<>// //<>// //<>// //<>// //<>//
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

float driftspeed = 1;

boolean run = true;
boolean firstrun = true;
int initialdelay = 1;
int rounddelay = 10;
boolean playSetup = false;

boolean spacePressed = false;
boolean clicked = false;

//Point6D w;

float CameraX = 0;
float CameraY = 0;
float CameraZ = 0;
float CameraRX = 0;
float CameraRY = 0;
float CameraRZ = 0;

QueasyCam cam;
PMatrix3D originalMatrix;

Quasicrystal lattice;

void setup() {
  size(displayWidth, displayHeight, P3D);
  smooth(3);
  background(100);
  //camera(width/2.0,height/2.0,(height/2.0) / tan(PI*30.0 / 180.0), width/2.0, height/2.0, 0, 0, 1, 0);
  //frustum(10, -10, -10*float(displayHeight)/displayWidth, 10*float(displayHeight)/displayWidth, 10, 1000000);
  originalMatrix = ((PGraphicsOpenGL)this.g).camera;
  cam = new QueasyCam(this);
  cam.speed = 0.1;
  cam.sensitivity = 0.4;
}

void draw() {
  lights();
  if (spacePressed) {
    run = !run;
    spacePressed = false;
  }
  if (run) {
    generate();
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
  for (Block block : lattice.blocks) {
    for (Rhomb face : block.sides) {
      /* TODO I'm repeating calculations here; the block only has a few vertices, but each
       vertex has several rhombuses. Ideally what I would do is have a Vertex object which 
       stores the 3D calculation, so that it need only be computed once for all adjacent
       vertices. */
      face.corner1_3D = new PVector(face.corner1.minus(lattice.fivedeew).dot(lattice.fivedee0), face.corner1.minus(lattice.fivedeew).dot(lattice.fivedee1), face.corner1.minus(lattice.fivedeew).dot(lattice.fivedee2));
      face.corner2_3D = new PVector(face.corner2.minus(lattice.fivedeew).dot(lattice.fivedee0), face.corner2.minus(lattice.fivedeew).dot(lattice.fivedee1), face.corner2.minus(lattice.fivedeew).dot(lattice.fivedee2));
      face.corner3_3D = new PVector(face.corner3.minus(lattice.fivedeew).dot(lattice.fivedee0), face.corner3.minus(lattice.fivedeew).dot(lattice.fivedee1), face.corner3.minus(lattice.fivedeew).dot(lattice.fivedee2));
      face.corner4_3D = new PVector(face.corner4.minus(lattice.fivedeew).dot(lattice.fivedee0), face.corner4.minus(lattice.fivedeew).dot(lattice.fivedee1), face.corner4.minus(lattice.fivedeew).dot(lattice.fivedee2));
      face.center_3D = new PVector(face.center.minus(lattice.fivedeew).dot(lattice.fivedee0), face.center.minus(lattice.fivedeew).dot(lattice.fivedee1), face.center.minus(lattice.fivedeew).dot(lattice.fivedee2));
    }
  }
  int selection;
  for (int loopvar = 0; loopvar < 1; loopvar++) {
    selection = floor(random(lattice.blocks.size()));
    lattice.blocks.get(selection).value = ceil(random(0, 20));
  }

  playSetup = true;
}

void render() {
  if (!playSetup) {
    setupRender();
  }
  background(0, 100, 0);
  ArrayList<Rhomb> pointedAt = new ArrayList<Rhomb>();
  for (Block block : lattice.blocks) {
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
          stroke(100);
          //noStroke();
          fill(block.value*10, block.value*5, 255-block.value*10);
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
        if (mouseButton == LEFT) empty.value += ceil(random(0, 10));
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
        //println(block.center.point);
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

void generate() {
  //float[] fivedeex = {random(-10,10),random(-10,10),random(-10,10),random(-10,10),random(-10,10)};
  //float[] fivedeey = {random(-10,10),random(-10,10),random(-10,10),random(-10,10),random(-10,10)};
  //float[] fivedeew = {random(-10,10),random(-10,10),random(-10,10),random(-10,10),random(-10,10)};// The position of the screen's origin

  // Penrose?
  float phi = (1+sqrt(5))/2;
  Point6D x = new Point6D(new float[]{phi, 0, 1, phi, 0, -1});
  Point6D y = new Point6D(new float[]{1, phi, 0, -1, phi, 0});
  Point6D z = new Point6D(new float[]{0, 1, phi, 0, -1, phi});
  Point6D w = new Point6D(new float[]{0.3, 0.5, 0.7, 0.11, 0.13, 0.17});

  //float[] driftw = {.25,.25,.25,.25,.25};
  lattice = new Quasicrystal(w, x, y, z);
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

class Chunk extends Block {
  int level;

  public Chunk(Point6D p) {
    super(p);
    level = 0;
  }
}
