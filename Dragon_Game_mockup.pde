/**************************************** //<>//
 * Dragon Game Mockup by Daniel Demski.
 * 
 * Generates nonperiodic (quasicrystal) lattices in 3D
 * and allows the user to place and delete blocks within
 * the lattice. Change "r" inside "generate()" to add more
 * (or less) blocks.
 * 
 *****************************************/
//import queasycam.*;
boolean test_assertions = true;
boolean picky_assertions = false;

float driftspeed = 1;

// The phi cubed chunk_ratio looks promising: out of 4118 chunks, ended up with
// 33 unique. BUT they had no child blocks, which is very confusing. I think my
// distance cutoff was too low when searching for overlapping points. So the 
// low number of uniques is just because of that.
float chunk_ratio = ((1+sqrt(5))/2);//((1+sqrt(5))/2)*((1+sqrt(5))/2)*((1+sqrt(5))/2);//2.0;
boolean skip_classif = true;

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

Quasicrystal main_lattice;
Quasicrystal main_chunk_lattice;

void setup() {
  size(displayWidth, displayHeight, P3D);
  smooth(3);
  background(100);
  //camera(width/2.0,height/2.0,(height/2.0) / tan(PI*30.0 / 180.0), width/2.0, height/2.0, 0, 0, 1, 0);
  //frustum(10, -10, -10*float(displayHeight)/displayWidth, 10*float(displayHeight)/displayWidth, 10, 1000000);
  originalMatrix = ((PGraphicsOpenGL)this.g).camera;
  cam = new QueasyCam(this);
  cam.speed = 0.06;
  cam.sensitivity = 0.18;
  processing.core.PApplet.class.getClassLoader().setClassAssertionStatus(processing.core.PApplet.class.getName(), test_assertions);
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
  for (Object o : main_lattice.cells) {
    Vertex v = (Vertex)(o);
    v.location_3D = new PVector(v.minus(main_lattice.fivedeew).dot(main_lattice.fivedee0), v.minus(main_lattice.fivedeew).dot(main_lattice.fivedee1), v.minus(main_lattice.fivedeew).dot(main_lattice.fivedee2));
  }
  for (Object o : main_lattice.rhombs) {
    Rhomb r = (Rhomb)(o);
    r.center_3D = new PVector(r.center.minus(main_lattice.fivedeew).dot(main_lattice.fivedee0), r.center.minus(main_lattice.fivedeew).dot(main_lattice.fivedee1), r.center.minus(main_lattice.fivedeew).dot(main_lattice.fivedee2));
  }
  if (test_assertions) {
    for (Block block : (Iterable<Block>)(main_lattice.blocks)) {
      for (Rhomb face : block.sides) {
        assert main_lattice.rhombs.list.contains(face): 
        "unregistered rhomb as face";
        assert main_lattice.cells.list.contains(face.corner1): 
        "unregistered vertex as corner";
        assert face.corner1.location_3D != null :
        "Supposedly-registered vertex didn't get a 3D location";
      }
    }
  }
  int selection;
  for (int loopvar = 0; loopvar < 100; loopvar++) {
    selection = floor(random(main_lattice.blocks.size()));
    main_lattice.blocks.list.get(selection).value = ceil(random(0, 20));
  }
  for (Object o : main_chunk_lattice.cells) {
    Vertex v = (Vertex)(o);
    v.location_3D = new PVector(v.minus(main_chunk_lattice.fivedeew).dot(main_chunk_lattice.fivedee0), v.minus(main_chunk_lattice.fivedeew).dot(main_chunk_lattice.fivedee1), v.minus(main_chunk_lattice.fivedeew).dot(main_chunk_lattice.fivedee2));
  }
  for (Object o : main_chunk_lattice.rhombs) {
    Rhomb r = (Rhomb)(o);
    r.center_3D = new PVector(r.center.minus(main_chunk_lattice.fivedeew).dot(main_chunk_lattice.fivedee0), r.center.minus(main_chunk_lattice.fivedeew).dot(main_chunk_lattice.fivedee1), r.center.minus(main_chunk_lattice.fivedeew).dot(main_chunk_lattice.fivedee2));
  }
  for (int loopvar = 0; loopvar < 4; loopvar++) {
    selection = floor(random(main_chunk_lattice.blocks.size()));
    main_chunk_lattice.blocks.list.get(selection).value = ceil(random(0, 20));
  }


  playSetup = true;
}

void render() {
  if (!playSetup) {
    setupRender();
  }
  background(0, 100, 0);
  ArrayList<Rhomb> pointedAt = new ArrayList<Rhomb>();
  for (Block block : (Iterable<Block>)(main_lattice.blocks)) {
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
          vertex(face.corner1.location_3D.x, face.corner1.location_3D.y, face.corner1.location_3D.z);
          vertex(face.corner2.location_3D.x, face.corner2.location_3D.y, face.corner2.location_3D.z);
          vertex(face.corner4.location_3D.x, face.corner4.location_3D.y, face.corner4.location_3D.z);
          vertex(face.corner3.location_3D.x, face.corner3.location_3D.y, face.corner3.location_3D.z);
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
        vertex(face.corner1.location_3D.x, face.corner1.location_3D.y, face.corner1.location_3D.z);
        vertex(face.corner2.location_3D.x, face.corner2.location_3D.y, face.corner2.location_3D.z);
        vertex(face.corner4.location_3D.x, face.corner4.location_3D.y, face.corner4.location_3D.z);
        vertex(face.corner3.location_3D.x, face.corner3.location_3D.y, face.corner3.location_3D.z);
        endShape(CLOSE);
      }
      stroke(0, 255, 0);
      fill(255-(255-block.value*25)*0.8, 255-(255-block.value*10)*0.8, 255-block.value*25*0.8);
      beginShape();
      vertex(closest.corner1.location_3D.x, closest.corner1.location_3D.y, closest.corner1.location_3D.z);
      vertex(closest.corner2.location_3D.x, closest.corner2.location_3D.y, closest.corner2.location_3D.z);
      vertex(closest.corner4.location_3D.x, closest.corner4.location_3D.y, closest.corner4.location_3D.z);
      vertex(closest.corner3.location_3D.x, closest.corner3.location_3D.y, closest.corner3.location_3D.z);
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
      vertex(closest.corner1.location_3D.x, closest.corner1.location_3D.y, closest.corner1.location_3D.z);
      vertex(closest.corner2.location_3D.x, closest.corner2.location_3D.y, closest.corner2.location_3D.z);
      vertex(closest.corner4.location_3D.x, closest.corner4.location_3D.y, closest.corner4.location_3D.z);
      vertex(closest.corner3.location_3D.x, closest.corner3.location_3D.y, closest.corner3.location_3D.z);
      endShape(CLOSE);
    }
  }
  for (Block b : (Iterable<Block>)(main_chunk_lattice.blocks)) {
    if (b.value > 0) {
      for (Rhomb r : b.sides) {
        noFill();
        stroke(255, 0, 255);
        beginShape();
        vertex(r.corner1.location_3D.x, r.corner1.location_3D.y, r.corner1.location_3D.z);
        vertex(r.corner2.location_3D.x, r.corner2.location_3D.y, r.corner2.location_3D.z);
        vertex(r.corner4.location_3D.x, r.corner4.location_3D.y, r.corner4.location_3D.z);
        vertex(r.corner3.location_3D.x, r.corner3.location_3D.y, r.corner3.location_3D.z);
        endShape(CLOSE);
      }
    }
  }
  drawCrosshair();
}

boolean cameraPoint(Rhomb face) {
  // Use camera as origin
  PVector c1 = face.corner1.location_3D.copy().sub(cam.position);
  PVector c2 = face.corner2.location_3D.copy().sub(cam.position);
  PVector c3 = face.corner3.location_3D.copy().sub(cam.position);
  PVector c4 = face.corner4.location_3D.copy().sub(cam.position);
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

  // Idea: Rather than implementing the Steinhardt algorithm I could 
  // Penrose
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
  //float rad = 12;//12;
  //float chunk_ratio = 2;

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
    float searchradius = 12;// needs to be big enough to guarantee one fully-populated chunk
    // Normalize in order to make searchradius "accurate"
    x = x.normalized();
    y = y.normalized();
    z = z.normalized();
    println("Generating block lattice...");
    Quasicrystal lattice = new Quasicrystal(initial_w, x, y, z, searchradius);
    //Quasicrystal lattice = new Quasicrystal(initial_w, x.plus(y), y.plus(z), z, searchradius);
    println("Generating chunk lattice...");
    Quasicrystal chunk_lattice = new Quasicrystal(initial_w.times(1.0/chunk_ratio), x.times(1.0/chunk_ratio), y.times(1.0/chunk_ratio), z.times(1.0/chunk_ratio), searchradius*(1.0/chunk_ratio));
    //Quasicrystal chunk_lattice = new Quasicrystal(initial_w, x.plus(y), y, z, searchradius);
    println("Generating lattice to classify blocks as if they were chunks...");
    Quasicrystal subblock_lattice = new Quasicrystal(initial_w.times(chunk_ratio), x.times(chunk_ratio), y.times(chunk_ratio), z.times(chunk_ratio), searchradius*(chunk_ratio));
    //Quasicrystal subblock_lattice = new Quasicrystal(initial_w, x, y, z, searchradius);
    
    // Scale everything in chunk_lattice back up

    chunk_lattice.fivedeex.set(chunk_lattice.fivedeex.times(chunk_ratio));
    chunk_lattice.fivedeey.set(chunk_lattice.fivedeey.times(chunk_ratio));
    chunk_lattice.fivedeez.set(chunk_lattice.fivedeez.times(chunk_ratio));
    chunk_lattice.fivedeew.set(chunk_lattice.fivedeew.times(chunk_ratio));
    // TODO Why do I have to cast here? Fix it so that I don't
    for (Object o : chunk_lattice.rhombs) {
      Rhomb rhomb = (Rhomb)o;
      rhomb.center.set(rhomb.center.times(chunk_ratio));
      //rhomb.corner1.set(rhomb.corner1.times(chunk_ratio));
      //rhomb.corner2.set(rhomb.corner2.times(chunk_ratio));
      //rhomb.corner3.set(rhomb.corner3.times(chunk_ratio));
      //rhomb.corner4.set(rhomb.corner4.times(chunk_ratio));
    }
    for (Block b : (Iterable<Block>)(chunk_lattice.blocks)) {
      b.center.set(b.center.times(chunk_ratio));
    }
    for (Vertex v : (Iterable<Vertex>)(chunk_lattice.cells)) {
      v.set(v.times(chunk_ratio));
    }

    // And everything in subblock_lattice down

    subblock_lattice.fivedeex.set(subblock_lattice.fivedeex.times(1.0/chunk_ratio));
    subblock_lattice.fivedeey.set(subblock_lattice.fivedeey.times(1.0/chunk_ratio));
    subblock_lattice.fivedeez.set(subblock_lattice.fivedeez.times(1.0/chunk_ratio));
    subblock_lattice.fivedeew.set(subblock_lattice.fivedeew.times(1.0/chunk_ratio));
    // TODO Here, I'm changing the coordinates of something inside RhombStore.
    // This makes RhombStore make mistakes later. Ought to create a legit way
    // to do this.
    for (Object o : subblock_lattice.rhombs) {
      Rhomb rhomb = (Rhomb)o;
      rhomb.center.set(rhomb.center.times(1.0/chunk_ratio));
      //rhomb.corner1.set(rhomb.corner1.times(1.0/chunk_ratio));
      //rhomb.corner2.set(rhomb.corner2.times(1.0/chunk_ratio));
      //rhomb.corner3.set(rhomb.corner3.times(1.0/chunk_ratio));
      //rhomb.corner4.set(rhomb.corner4.times(1.0/chunk_ratio));
    }
    for (Block b : (Iterable<Block>)(subblock_lattice.blocks)) {
      b.center.set(b.center.times(1.0/chunk_ratio));
    }
    for (Vertex v : (Iterable<Vertex>)(subblock_lattice.cells)) {
      v.set(v.times(1.0/chunk_ratio));
    }//*/

    main_lattice = subblock_lattice;
    main_chunk_lattice = lattice;
    if (skip_classif) {
      return;
    }
    
    // Not the right place for this, but gotta get 3D coordinates for the chunk lattice.
  for (Object o : chunk_lattice.cells) {
    Vertex v = (Vertex)(o);
    v.location_3D = new PVector(v.minus(chunk_lattice.fivedeew).dot(chunk_lattice.fivedee0), v.minus(chunk_lattice.fivedeew).dot(chunk_lattice.fivedee1), v.minus(chunk_lattice.fivedeew).dot(chunk_lattice.fivedee2));
  }
  for (Object o : chunk_lattice.rhombs) {
    Rhomb r = (Rhomb)(o);
    r.center_3D = new PVector(r.center.minus(chunk_lattice.fivedeew).dot(chunk_lattice.fivedee0), r.center.minus(chunk_lattice.fivedeew).dot(chunk_lattice.fivedee1), r.center.minus(chunk_lattice.fivedeew).dot(chunk_lattice.fivedee2));
  }

    println(str(chunk_lattice.blocks.list.size())+" chunks, "+str(lattice.blocks.list.size())+" blocks, "+str(subblock_lattice.blocks.list.size())+" sub-blocks found.");
    println("Classifying chunks...");
    ArrayList<Chunk> classif1 = classifyChunks3D(chunk_lattice, lattice);
    println(str(classif1.size())+" unique chunks found.");
    println("Classifying blocks as if they were chunks...");
    ArrayList<Chunk> classif2 = classifyChunks3D(lattice, subblock_lattice);
    println(str(classif2.size())+" unique blocks found.");

    for (Chunk c : classif1) {
      if (c.instances.size() > 1) {
        for (Chunk ci : c.instances) {
          // For each instance, we want to print what chunk types its blocks are.
          String types = str(classif1.indexOf(c));
          int block_count = 0;
          for (Block b : ci.blocks) {
            for (Chunk s : classif2) {
              for (Chunk si : s.instances) {
                if (max(si.center.minus(b.center).abs().point) < 0.01) {
                  types = types+" "+classif2.indexOf(s);
                  block_count += 1;
                }
              }
            }
          }
          if (block_count > 0)
            println(types);
        }
      }
    }
  }
}

ArrayList<Chunk> classifyChunks(Quasicrystal chunk_lattice, Quasicrystal lattice) {
  ArrayList<Chunk> decorated_chunks = new ArrayList<Chunk>();
  int progress_count = 0;
  float last_progress_report = 0;
  for (Block chunk : (Iterable<Block>)(chunk_lattice.blocks)) {
    progress_count++;
    if (float(progress_count)/chunk_lattice.blocks.list.size()-last_progress_report > 0.105) {
      println("Decorating: "+100*float(progress_count)/chunk_lattice.blocks.list.size()+"% complete");
      last_progress_report = float(progress_count)/chunk_lattice.blocks.list.size();
    }
    // TODO This loop is apparently the slow part
    boolean skipchunk = false;
    PointStore decorations = new PointStore(lattice.tolerance);
    //ArrayList<Point6D> corners = new ArrayList<Point6D>();
    VertexStore corner_store = new VertexStore(lattice.tolerance);
    Chunk decorated_chunk = new Chunk(chunk.center.copy());
    for (Rhomb face : chunk.sides) {
      corner_store.add(face.corner1); 
      corner_store.add(face.corner2); 
      corner_store.add(face.corner3); 
      corner_store.add(face.corner4);
    }
    // Collected 6D corners of chunk. Now we have bounds w/in which to collect corners of blocks.
    Point6D minp = corner_store.list.get(0).copy();
    Point6D maxp = corner_store.list.get(0).copy();
    for (Point6D c : (Iterable<Point6D>)(corner_store)) {
      for (int i = 0; i < 6; i++) {
        if (minp.point[i] > c.point[i]) minp.point[i] = c.point[i];
        if (maxp.point[i] < c.point[i]) maxp.point[i] = c.point[i];
      }
    }
    for (Block block : (Iterable<Block>)(lattice.blocks)) {
      // Is the block anywhere near the chunk?
      // TODO Measure whether this is helping or hurting. Do it better?
      // Maybe manhatten distance is actually more relevant?
      float dist = 0;//block.center.minus(chunk.center).length();
      if (dist < chunk_ratio*1.5*sqrt(6)) {// TODO is this cutoff ok?
        PointStore iterate = new PointStore(lattice.tolerance); //<>//
        //iterate.add(block.center);
        boolean maybe_skipchunk = false;
        // Let's decorate with corners too. It's okay that we'll repeat them.
        for (Rhomb r : block.sides) {
          if (r.parents.size() < 2) {
            // This block is too close to the edge of space.
            // We need to skip the chunk if it turns out to be
            // inside it.
            maybe_skipchunk = true;
          } else if (r.parents.size() > 2) {
          assert 0 == 1 : 
            "Rhombus with too many parents";
          }
          iterate.add(r.corner1);
          iterate.add(r.corner2);
          iterate.add(r.corner3);
          iterate.add(r.corner4);
          iterate.add(r.center);
        }
        if (skipchunk) break;
        boolean addblock = false;
        for (Point6D p : (Iterable<Point6D>)(iterate)) {
          boolean inside_chunk = true;
          for (int i = 0; i < 6; i++) {
            if (p.point[i] - minp.point[i] < -lattice.tolerance || p.point[i] - maxp.point[i] > lattice.tolerance) {
              inside_chunk = false;
              break;
            }
          }
          if (inside_chunk) {
            decorations.add(p.copy());
            // Also add block's center, even though it may be outside chunk
            // TODO Adding this many decorations seems to greatly slow things down. maybe.
            // Fix?
            decorations.add(block.center.copy()); //<>//
            addblock = true;
            if (maybe_skipchunk) {
              skipchunk = true;
              break;
            }
          }
        }
        if (addblock) decorated_chunk.blocks.add(block);
        /*for (int i = 0; i < decorations.size() - 1; i++) {
         for (int j = i+1; j < decorations.size(); j++) {
         if (max(decorations.get(i).minus(decorations.get(j)).abs().point) < lattice.tolerance) {
         decorations.remove(j);
         j--;
         }
         }
         }*/
      }
    }
    if (skipchunk) continue;
    // now subtract minp from everything
    ArrayList<Point6D> corners = new ArrayList<Point6D>();
    for (Point6D p : (Iterable<Point6D>)(corner_store)) corners.add(p);
    for (int i = 0; i < corners.size(); i++) corners.set(i, corners.get(i).minus(minp));
    for (int i = 0; i < decorations.list.size(); i++) decorations.list.set(i, decorations.list.get(i).minus(minp));
    for (Point6D p : decorations.list) {
      decorated_chunk.block_centers.add(p);
    }
    decorated_chunk.corners = corners;
    decorated_chunks.add(decorated_chunk);
  }
  println("Decoration stage completed. Classifying "+decorated_chunks.size()+" chunks.");
  ArrayList<Chunk> unique_chunks = new ArrayList<Chunk>();
  FakeChunkStore chunk_hash = new FakeChunkStore();
  for (Chunk c : decorated_chunks) {
    boolean found = false;
    ArrayList<Chunk> hash_matches = chunk_hash.getAllSimilar(c);
    for (Chunk uc : hash_matches) {
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
          for (Point6D dec : (Iterable<Point6D>)(c.block_centers)) {
            boolean dec_found = uc.block_centers.contains(dec);
            /*for (Point6D uqdec : uc.block_centers) {
             if (max(dec.minus(uqdec).point)<lattice.tolerance) {
             dec_found = true;
             break;
             }
             }*/
            if (!dec_found) {
              decs_same = false;
              break;
            }
          }
          if (decs_same) {
            found = true;
            uc.instances.add(c);
            break;
          }
        }
      }
    }
    if (!found) {
      c.instances.add(c);
      unique_chunks.add(c);
      chunk_hash.add(c);
    }
  }
  return unique_chunks;
}

ArrayList<Chunk> classifyChunks3D(Quasicrystal chunk_lattice, Quasicrystal lattice) {
  if (!playSetup) setupRender();
  ArrayList<Chunk> decorated_chunks = new ArrayList<Chunk>();
  int progress_count = 0;
  float last_progress_report = 0;
  for (Block chunk : (Iterable<Block>)(chunk_lattice.blocks)) {
    progress_count++;
    if (float(progress_count)/chunk_lattice.blocks.list.size()-last_progress_report > 0.105) {
      println("Decorating: "+100*float(progress_count)/chunk_lattice.blocks.list.size()+"% complete");
      last_progress_report = float(progress_count)/chunk_lattice.blocks.list.size();
    }
    // TODO This loop is apparently the slow part
    boolean skipchunk = false;
    PointStore decorations = new PointStore(lattice.tolerance);
    //ArrayList<Point6D> corners = new ArrayList<Point6D>();
    VertexStore corner_store = new VertexStore(lattice.tolerance);
    Chunk decorated_chunk = new Chunk(chunk.center.copy());
    for (Rhomb face : chunk.sides) {
      corner_store.add(threedee(face.corner1.location_3D)); 
      corner_store.add(threedee(face.corner2.location_3D)); 
      corner_store.add(threedee(face.corner3.location_3D)); 
      corner_store.add(threedee(face.corner4.location_3D));
    }
    // Collected 6D corners of chunk. Now we have bounds w/in which to collect corners of blocks.
    Point6D minp = corner_store.list.get(0).copy();
    Point6D maxp = corner_store.list.get(0).copy();
    for (Point6D c : (Iterable<Point6D>)(corner_store)) {
      for (int i = 0; i < 6; i++) {
        if (minp.point[i] > c.point[i]) minp.point[i] = c.point[i];
        if (maxp.point[i] < c.point[i]) maxp.point[i] = c.point[i];
      }
    }
    for (Block block : (Iterable<Block>)(lattice.blocks)) {
      // Is the block anywhere near the chunk?
      // TODO Measure whether this is helping or hurting. Do it better?
      // Maybe manhatten distance is actually more relevant?
      float dist = 0;//block.center.minus(chunk.center).length();
      if (dist < chunk_ratio*1.5*sqrt(6)) {// TODO is this cutoff ok?
        PointStore iterate = new PointStore(lattice.tolerance);
        //iterate.add(block.center);
        boolean maybe_skipchunk = false;
        // Let's decorate with corners too. It's okay that we'll repeat them.
        for (Rhomb r : block.sides) {
          if (r.parents.size() < 2) {
            // This block is too close to the edge of space.
            // We need to skip the chunk if it turns out to be
            // inside it.
            maybe_skipchunk = true;
          } else if (r.parents.size() > 2) {
          assert 0 == 1 : 
            "Rhombus with too many parents";
          }
          iterate.add(threedee(r.corner1.location_3D));
          iterate.add(threedee(r.corner2.location_3D));
          iterate.add(threedee(r.corner3.location_3D));
          iterate.add(threedee(r.corner4.location_3D));
          iterate.add(threedee(r.center_3D));
        }
        if (skipchunk) break;
        boolean addblock = false;
        for (Point6D p : (Iterable<Point6D>)(iterate)) {
          boolean inside_chunk = true;
          for (int i = 0; i < 3; i++) {
            if (p.point[i] - minp.point[i] < -lattice.tolerance || p.point[i] - maxp.point[i] > lattice.tolerance) {
              inside_chunk = false;
              break;
            }
          }
          if (inside_chunk) {
            decorations.add(p.copy());
            // Also add block's center, even though it may be outside chunk
            // TODO Adding this many decorations seems to greatly slow things down. maybe.
            // Fix?
            //decorations.add(block.center.copy());
            addblock = true;
            if (maybe_skipchunk) {
              skipchunk = true;
              break;
            }
          }
        }
        if (addblock) decorated_chunk.blocks.add(block);
        /*for (int i = 0; i < decorations.size() - 1; i++) {
         for (int j = i+1; j < decorations.size(); j++) {
         if (max(decorations.get(i).minus(decorations.get(j)).abs().point) < lattice.tolerance) {
         decorations.remove(j);
         j--;
         }
         }
         }*/
      }
    }
    if (skipchunk) continue;
    // now subtract minp from everything
    ArrayList<Point6D> corners = new ArrayList<Point6D>();
    for (Point6D p : (Iterable<Point6D>)(corner_store)) corners.add(p);
    for (int i = 0; i < corners.size(); i++) corners.set(i, corners.get(i).minus(minp));
    for (int i = 0; i < decorations.list.size(); i++) decorations.list.set(i, decorations.list.get(i).minus(minp));
    for (Point6D p : decorations.list) {
      decorated_chunk.block_centers.add(p);
    }
    decorated_chunk.corners = corners;
    decorated_chunks.add(decorated_chunk);
  }
  println("Decoration stage completed. Classifying "+decorated_chunks.size()+" chunks.");
  ArrayList<Chunk> unique_chunks = new ArrayList<Chunk>();
  FakeChunkStore chunk_hash = new FakeChunkStore();
  for (Chunk c : decorated_chunks) {
    boolean found = false;
    ArrayList<Chunk> hash_matches = chunk_hash.getAllSimilar(c);
    for (Chunk uc : hash_matches) {
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
          for (Point6D dec : (Iterable<Point6D>)(c.block_centers)) {
            boolean dec_found = uc.block_centers.contains(dec);
            /*for (Point6D uqdec : uc.block_centers) {
             if (max(dec.minus(uqdec).point)<lattice.tolerance) {
             dec_found = true;
             break;
             }
             }*/
            if (!dec_found) {
              decs_same = false;
              break;
            }
          }
          if (decs_same) {
            found = true;
            uc.instances.add(c);
            break;
          }
        }
      }
    }
    if (!found) {
      c.instances.add(c);
      unique_chunks.add(c);
      chunk_hash.add(c);
    }
  }
  return unique_chunks;
}

// Cheesy conversion function
Vertex threedee(PVector p) {
  Vertex v = new Vertex(p.x,p.y,p.z,0,0,0);
  v.location_3D = p;
  return v;
}

class Chunk extends Block {
  int level;
  int type;
  PointStore block_centers;
  ArrayList<Block> blocks;
  ArrayList<Chunk> instances;
  ArrayList<Point6D> corners;

  public Chunk(Point6D p) {
    super(p);
    level = 0;
    block_centers = new PointStore(0.01);
    corners = new ArrayList<Point6D>();
    blocks = new ArrayList<Block>();
    instances = new ArrayList<Chunk>();
  }
}

class FakeChunkStore extends Point6DStore<Chunk> {
  // Do not store chunks in this!! It's just being used
  // to try and speed up my checking for duplicates elsewhere.
  public FakeChunkStore() {
    super(0.01);
  }

  Point6D location(Chunk c) {
    Point6D loc = new Point6D(0, 0, 0, 0, 0, 0);
    for (Point6D p : (Iterable<Point6D>)(c.block_centers)) {
      loc = loc.plus(p.times(1.6180339887498948482));
    }
    for (Point6D p : c.corners) {
      loc = loc.plus(p);
    }
    return loc;
  }

  // Making this public so that we can force "duplicate" additions
  void definitelyAdd(Point6D key, Chunk value) {
    for (int i = 0; i < 6; i++) {
      ArrayList<Chunk> list_i = (ArrayList<Chunk>)(storage[i].get(key.point[i]));
      if (list_i != null) {
        list_i.add(value);
      } else {
        ArrayList<Chunk> initial_list_i = new ArrayList<Chunk>();
        initial_list_i.add(value);
        storage[i].put(key.point[i], initial_list_i);
      }
    }
    list.add(value);
  }

  ArrayList<Chunk> getAll(Point6D key) {
    // This altered "get" will return all matches rather than the first (and theoretically only) match.
    ArrayList<Chunk> matches = new ArrayList<Chunk>();
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
      // Item not present in storage.
      return matches;
    }
    int i = hitsize.indexOf(min(new int[]{hitsize.get(0), hitsize.get(1), hitsize.get(2), hitsize.get(3), hitsize.get(4), hitsize.get(5)}));
    for (Float k : hits[i]) {
      ArrayList<Chunk> values = (ArrayList<Chunk>)storage[i].get(k);
      for (Chunk fetched : values) {
        if (equals(key, location(fetched))) {
          matches.add(fetched);
        }
      }
    }
    return(matches);
  }

  ArrayList<Chunk> getAllSimilar(Chunk c) {
    return getAll(location(c));
  }
}
