/**************************************** //<>// //<>// //<>//
 * Dragon Game Mockup by Daniel Demski.
 * 
 * Generates nonperiodic (quasicrystal) lattices in 3D
 * and allows the user to place and delete blocks within
 * the lattice. Change "r" inside "generate()" to add more
 * (or less) blocks.
 * 
 *****************************************/
//import queasycam.*;

float driftspeed = 1;

float chunk_ratio = 2.0;

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
Quasicrystal chunk_lattice;

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
    if (firstrun) {
      delay(initialdelay);
      firstrun = false;
    } else {
      delay(rounddelay);
    }
    while (!run) {
      delay(500);
    }
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
  for (int loopvar = 0; loopvar < 5; loopvar++) {
    selection = floor(random(lattice.blocks.size()));
    lattice.blocks.get(selection).value = ceil(random(0, 20));
  }
  for (Block chunk : chunk_lattice.blocks) {
    for (Rhomb face : chunk.sides) {
      face.corner1_3D = new PVector(face.corner1.minus(lattice.fivedeew).dot(lattice.fivedee0), face.corner1.minus(lattice.fivedeew).dot(lattice.fivedee1), face.corner1.minus(lattice.fivedeew).dot(lattice.fivedee2));
      face.corner2_3D = new PVector(face.corner2.minus(lattice.fivedeew).dot(lattice.fivedee0), face.corner2.minus(lattice.fivedeew).dot(lattice.fivedee1), face.corner2.minus(lattice.fivedeew).dot(lattice.fivedee2));
      face.corner3_3D = new PVector(face.corner3.minus(lattice.fivedeew).dot(lattice.fivedee0), face.corner3.minus(lattice.fivedeew).dot(lattice.fivedee1), face.corner3.minus(lattice.fivedeew).dot(lattice.fivedee2));
      face.corner4_3D = new PVector(face.corner4.minus(lattice.fivedeew).dot(lattice.fivedee0), face.corner4.minus(lattice.fivedeew).dot(lattice.fivedee1), face.corner4.minus(lattice.fivedeew).dot(lattice.fivedee2));
      face.center_3D = new PVector(face.center.minus(lattice.fivedeew).dot(lattice.fivedee0), face.center.minus(lattice.fivedeew).dot(lattice.fivedee1), face.center.minus(lattice.fivedeew).dot(lattice.fivedee2));
    }
  }
  for (int loopvar = 0; loopvar < 3; loopvar++) {
    selection = floor(random(chunk_lattice.blocks.size()));
    chunk_lattice.blocks.get(selection).value = ceil(random(0, 20));
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
  for (Block b : chunk_lattice.blocks) {
    if (b.value > 0) {
      for (Rhomb r : b.sides) {
        noFill();
        stroke(255, 0, 255);
        beginShape();
        vertex(r.corner1_3D.x, r.corner1_3D.y, r.corner1_3D.z);
        vertex(r.corner2_3D.x, r.corner2_3D.y, r.corner2_3D.z);
        vertex(r.corner4_3D.x, r.corner4_3D.y, r.corner4_3D.z);
        vertex(r.corner3_3D.x, r.corner3_3D.y, r.corner3_3D.z);
        endShape(CLOSE);
      }
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
  //Point6D w = new Point6D(new float[]{0.5, 0.5, 0.5, 0.5, 0.5, 0.5});
  // Simple cube grid!!
  //Point6D x = new Point6D(new float[]{1, 0, 0, 0, 0, 0});
  //Point6D y = new Point6D(new float[]{0, 1, 0, 0, 0, 0});
  //Point6D z = new Point6D(new float[]{0, 0, 1, 0, 0, 0});
  //Point6D w = new Point6D(new float[]{0, 0, 0, 0, 0, 0});
  float rad = 12;//12;
  float chunk_ratio = 2;

  chunkNetwork cn = new chunkNetwork(w, x, y, z);

  /*lattice = new Quasicrystal(w, x, y, z, rad);
   // What we want to do with the chunks is tilt the 3D basis within higher-D by the correct amount
   // to create a new tiling similar to the old but stretched out.
   chunk_lattice = new Quasicrystal(w.times(1.0/chunk_ratio), x.times(1.0/chunk_ratio), y.times(1.0/chunk_ratio), z.times(1.0/chunk_ratio), rad*(1.0/chunk_ratio));
   // Scale everything in chunk_lattice back up
   
   chunk_lattice.fivedeex = chunk_lattice.fivedeex.times(chunk_ratio);
   chunk_lattice.fivedeey = chunk_lattice.fivedeey.times(chunk_ratio);
   chunk_lattice.fivedeez = chunk_lattice.fivedeez.times(chunk_ratio);
   chunk_lattice.fivedeew = chunk_lattice.fivedeew.times(chunk_ratio);
   for (Rhomb rhomb : chunk_lattice.rhombs) {
   rhomb.center = rhomb.center.times(chunk_ratio);
   rhomb.corner1 = rhomb.corner1.times(chunk_ratio);
   rhomb.corner2 = rhomb.corner2.times(chunk_ratio);
   rhomb.corner3 = rhomb.corner3.times(chunk_ratio);
   rhomb.corner4 = rhomb.corner4.times(chunk_ratio);
   }
   for (Block b : chunk_lattice.blocks) {
   b.center = b.center.times(chunk_ratio);
   }
   
   classifyChunks();*/
}

class chunkNetwork {
  ArrayList<Chunk> chunkTypes;

  public chunkNetwork(Point6D initial_w, Point6D x, Point6D y, Point6D z) {
    float searchradius = 6;// needs to be big enough to guarantee one fully-populated chunk
    Quasicrystal lattice = new Quasicrystal(initial_w, x, y, z, 6);
    Quasicrystal chunk_lattice = new Quasicrystal(initial_w.times(1.0/chunk_ratio), x.times(1.0/chunk_ratio), y.times(1.0/chunk_ratio), z.times(1.0/chunk_ratio), searchradius*(1.0/chunk_ratio));
    Quasicrystal subblock_lattice = new Quasicrystal(initial_w.times(chunk_ratio), x.times(chunk_ratio), y.times(chunk_ratio), z.times(chunk_ratio), searchradius*(chunk_ratio));
    
    // Scale everything in chunk_lattice back up

    chunk_lattice.fivedeex = chunk_lattice.fivedeex.times(chunk_ratio);
    chunk_lattice.fivedeey = chunk_lattice.fivedeey.times(chunk_ratio);
    chunk_lattice.fivedeez = chunk_lattice.fivedeez.times(chunk_ratio);
    chunk_lattice.fivedeew = chunk_lattice.fivedeew.times(chunk_ratio);
    for (Rhomb rhomb : chunk_lattice.rhombs) {
      rhomb.center = rhomb.center.times(chunk_ratio);
      rhomb.corner1 = rhomb.corner1.times(chunk_ratio);
      rhomb.corner2 = rhomb.corner2.times(chunk_ratio);
      rhomb.corner3 = rhomb.corner3.times(chunk_ratio);
      rhomb.corner4 = rhomb.corner4.times(chunk_ratio);
    }
    for (Block b : chunk_lattice.blocks) {
      b.center = b.center.times(chunk_ratio);
    }
    
    // And everything in subblock_lattice down
    
    subblock_lattice.fivedeex = subblock_lattice.fivedeex.times(1.0/chunk_ratio);
    subblock_lattice.fivedeey = subblock_lattice.fivedeey.times(1.0/chunk_ratio);
    subblock_lattice.fivedeez = subblock_lattice.fivedeez.times(1.0/chunk_ratio);
    subblock_lattice.fivedeew = subblock_lattice.fivedeew.times(1.0/chunk_ratio);
    for (Rhomb rhomb : subblock_lattice.rhombs) {
      rhomb.center = rhomb.center.times(1.0/chunk_ratio);
      rhomb.corner1 = rhomb.corner1.times(1.0/chunk_ratio);
      rhomb.corner2 = rhomb.corner2.times(1.0/chunk_ratio);
      rhomb.corner3 = rhomb.corner3.times(1.0/chunk_ratio);
      rhomb.corner4 = rhomb.corner4.times(1.0/chunk_ratio);
    }
    for (Block b : subblock_lattice.blocks) {
      b.center = b.center.times(1.0/chunk_ratio);
    }

    classifyChunks(chunk_lattice,lattice);
    classifyChunks(lattice,subblock_lattice);
  }
}

void classifyChunks(Quasicrystal chunk_lattice, Quasicrystal lattice) {
  ArrayList<Chunk> decorated_chunks = new ArrayList<Chunk>();
  for (Block chunk : chunk_lattice.blocks) {
    boolean skipchunk = false;
    ArrayList<Point6D> decorations = new ArrayList<Point6D>();
    ArrayList<Point6D> corners = new ArrayList<Point6D>();
    for (Rhomb face : chunk.sides) {
      ArrayList<Point6D> iterate = new ArrayList<Point6D>();
      iterate.add(face.corner1); 
      iterate.add(face.corner2); 
      iterate.add(face.corner3); 
      iterate.add(face.corner4);
      for (Point6D c : iterate) {
        boolean found = false;
        for (Point6D p : corners) {
          if (max(p.minus(c).abs().point)<lattice.tolerance) {
            found = true;
            break;
          }
        }
        if (!found) {
          corners.add(c.copy());
        }
      }
    }
    // Collected 6D corners of chunk. Now we have bounds w/in which to collect corners of blocks.
    Point6D minp = corners.get(0).copy();
    Point6D maxp = corners.get(0).copy();
    for (Point6D c : corners) {
      for (int i = 0; i < 6; i++) {
        if (minp.point[i] > c.point[i]) minp.point[i] = c.point[i];
        if (maxp.point[i] < c.point[i]) maxp.point[i] = c.point[i];
      }
    }
    for (Block block : lattice.blocks) {
      ArrayList<Point6D> iterate = new ArrayList<Point6D>();
      iterate.add(block.center);
      boolean maybe_skipchunk = false;
      // Let's decorate with corners too. It's okay that we'll repeat them.
      for (Rhomb r : block.sides) {
        if (r.parents.size() != 2) {
          // This block is too close to the edge of space.
          // We need to skip the chunk if it turns out to be
          // inside it.
          maybe_skipchunk = true;
        }
        iterate.add(r.corner1);
        iterate.add(r.corner2);
        iterate.add(r.corner3);
        iterate.add(r.corner4);
      }
      if (skipchunk) break;
      for (Point6D p : iterate) {
        boolean inside_chunk = true;
        for (int i = 0; i < 6; i++) {
          if (p.point[i] < minp.point[i] || p.point[i] > maxp.point[i]) {
            inside_chunk = false;
            break;
          }
        }
        if (inside_chunk) {
          decorations.add(p.copy());
          if (maybe_skipchunk) {
            skipchunk = true;
            break;
          }
        }
      }
      for (int i = 0; i < decorations.size() - 1; i++) {
        for (int j = i+1; j < decorations.size(); j++) {
          if (max(decorations.get(i).minus(decorations.get(j)).abs().point) < lattice.tolerance) {
            decorations.remove(j);
            j--;
          }
        }
      }
    }
    if (skipchunk) continue;
    // now subtract minp from everything
    for (int i = 0; i < corners.size(); i++) corners.set(i, corners.get(i).minus(minp));
    for (int i = 0; i < decorations.size(); i++) decorations.set(i, decorations.get(i).minus(minp));
    Chunk decorated_chunk = new Chunk(chunk.center.copy());
    decorated_chunk.block_centers = decorations;
    decorated_chunk.corners = corners;
    decorated_chunks.add(decorated_chunk);
  }
  println("Number of chunks: "+decorated_chunks.size());
  ArrayList<Chunk> unique_chunks = new ArrayList<Chunk>();
  for (Chunk c : decorated_chunks) {
    Point6D nonzero = new Point6D(0, 0, 0, 0, 0, 0);
    int num_nonzero = 0;
    for (int i = 0; i < 6; i++) {
      for (Point6D p : c.corners) {
        if (p.point[i] != 0) {
          nonzero.point[i] = 1;
          num_nonzero += 1;
          break;
        }
      }
      if (nonzero.point[i] > 0) continue;
      for (Point6D p : c.block_centers) {
        if (p.point[i] != 0) {
          nonzero.point[i] = 1;
          num_nonzero += 1;
          break;
        }
      }
    }
    //TODO Remove this assertion
  assert num_nonzero == 3 : 
    "Oh, actually sometimes more than 3";
    for (int i = 0; i < num_nonzero; i++) {
      int zi = 0;
      while (nonzero.point[zi] > 0) zi++;
      int nzi = zi;
      while (nzi < 6 && nonzero.point[nzi] == 0) nzi++;
      if (nzi < 6) {
        for (Point6D p : c.corners) {
          p.point[zi] = p.point[nzi];
          p.point[nzi] = 0;
        }
        for (Point6D p : c.block_centers) {
          p.point[zi] = p.point[nzi];
          p.point[nzi] = 0;
        }
        nonzero.point[zi] = nonzero.point[nzi];
        nonzero.point[nzi] = 0;
      }
    }
    boolean found = false;
    for (int perm = 0; perm < 6; perm++) {
      for (Chunk uc : unique_chunks) {
        if (c.block_centers.size() == uc.block_centers.size()) {
          boolean corners_same = true;
          for (Point6D corner : c.corners) {
            boolean found_corner = false;
            for (Point6D uqcorner : uc.corners) {
              if (max(corner.minus(uqcorner).point)<lattice.tolerance) {
                found_corner = true;
                break;
              }
            }
            if (!found_corner) {
              corners_same = false;
              break;
            }
          }
          if (corners_same) {
            boolean decs_same = true;
            for (Point6D dec : c.block_centers) {
              boolean dec_found = false;
              for (Point6D uqdec : uc.block_centers) {
                if (max(dec.minus(uqdec).point)<lattice.tolerance) {
                  dec_found = true;
                  break;
                }
              }
              if (!dec_found) {
                decs_same = false;
                break;
              }
            }
            if (decs_same) {
              found = true;
              break;
            }
          }
        }
      }
      // Now permute for next loop-through
      if (perm%2 == 0) {
        // On even runs, permute first two values.
        for (Point6D p : c.corners) {
          float temp = p.point[0];
          p.point[0] = p.point[1];
          p.point[1] = temp;
        }
        for (Point6D p : c.block_centers) {
          float temp = p.point[0];
          p.point[0] = p.point[1];
          p.point[1] = temp;
        }
      } else {
        // On odd runs, permute 2nd with 3rd
        for (Point6D p : c.corners) {
          float temp = p.point[1];
          p.point[1] = p.point[2];
          p.point[2] = temp;
        }
        for (Point6D p : c.block_centers) {
          float temp = p.point[1];
          p.point[1] = p.point[2];
          p.point[2] = temp;
        }
      }
    }
    if (!found) unique_chunks.add(c);
  }
  println("Number of naively unique chunks: "+unique_chunks.size());
}

class Chunk extends Block {
  int level;
  ArrayList<Point6D> block_centers;
  ArrayList<Point6D> corners;

  public Chunk(Point6D p) {
    super(p);
    level = 0;
    block_centers = new ArrayList<Point6D>();
    corners = new ArrayList<Point6D>();
  }
}
