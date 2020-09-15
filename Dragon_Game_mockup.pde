//import pallav.Matrix.*; //<>// //<>// //<>// //<>// //<>// //<>//

/****************************************
 * Dragon Game Mockup by Daniel Demski.
 * 
 * Generates nonperiodic (quasicrystal) lattices in 3D
 * and allows the user to place and delete blocks within
 * the lattice. Change "r" inside "generate()" to add more
 * (or less) blocks.
 *
 * Thoughts on directions for this document: I want to settle on a 
 * chunking method which will work for terrain generation on the
 * golden rhombus grid. Once that's working, I can reimplement
 * in a more capable language to see how good I can get the 
 * performance. However, I think at that point it might be good
 * for the project to split rather than just move on. I want both
 * a game built around a single tesselation, and a more general
 * platform which presents voxel-building and terrain-generation
 * capabilities on a wide variety of 3D tesselations. Ideally,
 * it would be something others could contribute new tesselations
 * to, in order to explore a wide variety of them.
 *
 * Next step is to try "6D chunks", ie, a hierarchical cubic
 * structure in 6D where a voxel belongs to a chunk if a
 * 6-cube adjacent to the voxel (voxels are 3-facets of 6-cubes)
 * belongs to the chunk. The 6D chunks would simply have some
 * integer size, e.g. powers of 2 or 3. Voxel contents of a chunk
 * would approximate the shape of its intersection with the world-
 * plane, rather than a scaled-up shape from the tesselation (ie,
 * the dual of the set of such intersections; or, some choice of
 * 3-facets of these chunks). However the 3-facets of these chunks
 * (or, again, the dual of their intersections w/ world-plane) 
 * could still be useful for displaying low-detail stuff at a 
 * distance, and maybe for iterative terrain generation.
 *
 * Because the chunks are 6D, they are inherently fairly general
 * and should allow some other tesselations to work. Also, they
 * aren't reflecting a true self-similarity and so the valid 
 * chunk structures need to more or less be generated indefinitely;
 * which again is fairly general.
 *
 * TODO Write hierarchical chunk class capable of generating terrain
 * via inflation and deflation.
 * TODO Test hierarchical chunk class using simple hand-coded inflation/deflation templates (e.g. cubes).
 * TODO Make a subclass which can store the extra data (including world-plane position) for 6D chunks.
 * TODO Intelligently avoid generating new chunk-types when plane position falls within a (3D) range of validity for existing types.
 *
 * SCRATCH ALL THAT I finally found a paper with a substitution rule for this tiling.
 * There's a bit of a catch (some ambiguity in how d30s are filled in, as expected) but it's
 * a great starting point for working chunks.
 *
 * TODO Support for all Boyle/Steinhardt 2016 tilings
 * TODO Support for rhombic dodecahedron & other periodic tilings
 * TODO SCD tiling (Schmitt, Conway, Danzer)
 * TODO Danzer tiling (tetrahedral, octahedral)
 * TODO Dual of Danzer tiling (Aranda, Lasch, Bosia, 2007)
 * 
 *****************************************/
//import queasycam.*;
boolean test_assertions = true;
boolean picky_assertions = false;
boolean render_old_quasicrystal = false;

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
  for (int loopvar = 0; loopvar < 80; loopvar++) {
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
  // TODO Render in vectors fivedeex, fivedeey and fivedeez
  // from each lattice
  //stroke(0);
  //noFill();
  //beginShape();
  //vertex(0,0,0);

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

  if (render_old_quasicrystal) {
    chunkNetwork cn = new chunkNetwork(w, x, y, z);
  } else {
    CubeChunk first_chunk = new CubeChunk(new PVector(-0.5,-0.5,-0.5), 1);
  }

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

Matrix unitt(int i, int j) {
  /* Creates a matrix which will add the ith
   * coordinate to the jth
   */
  Matrix m = Matrix.identity(6);
  m.array[i][j] += 1;
  return m;
}

class chunkNetwork {
  ArrayList<Chunk> chunkTypes;

  public chunkNetwork(Point6D initial_w, Point6D x, Point6D y, Point6D z) {
    float searchradius = 13;// needs to be big enough to guarantee one fully-populated chunk
    // Normalize in order to make searchradius "accurate"
    x = x.normalized();
    y = y.normalized();
    z = z.normalized();
    println("Generating block lattice...");
    Quasicrystal lattice = new Quasicrystal(initial_w, x, y, z, searchradius);


    Matrix m = Matrix.Multiply(Matrix.Multiply(unitt(0, 3), unitt(1, 4)), unitt(2, 5));
    //Matrix m = Matrix.Multiply(Matrix.Multiply(unitt(0,1),unitt(1,2)),unitt(2,0));
    Matrix im = Matrix.inverse(m);

    //Quasicrystal lattice = new Quasicrystal(initial_w, x.plus(y), y.plus(z), z, searchradius);
    Point6D x_chunk = x.copy();
    Point6D y_chunk = y.copy();
    Point6D z_chunk = z.copy();
    Point6D w_chunk = initial_w.copy();
    x_chunk.point = Matrix.Multiply(Matrix.array(new float[][] {x_chunk.point}), m).array[0];
    y_chunk.point = Matrix.Multiply(Matrix.array(new float[][] {y_chunk.point}), m).array[0];
    z_chunk.point = Matrix.Multiply(Matrix.array(new float[][] {z_chunk.point}), m).array[0];
    w_chunk.point = Matrix.Multiply(Matrix.array(new float[][] {w_chunk.point}), m).array[0];
    println("Generating chunk lattice...");
    //Quasicrystal chunk_lattice = new Quasicrystal(initial_w.times(1.0/chunk_ratio), x.times(1.0/chunk_ratio), y.times(1.0/chunk_ratio), z.times(1.0/chunk_ratio), searchradius*(1.0/chunk_ratio));
    Quasicrystal chunk_lattice = new Quasicrystal(w_chunk, x_chunk, y_chunk, z_chunk, searchradius);

    /*x.point[0] = lattice.fivedeex.point[0] + lattice.fivedeex.point[1];
     y.point[0] = lattice.fivedeey.point[0] + lattice.fivedeey.point[1];
     z.point[0] = lattice.fivedeez.point[0] + lattice.fivedeez.point[1];
     initial_w.point[0] = lattice.fivedeew.point[0] + lattice.fivedeew.point[1];
     x.point[1] = lattice.fivedeex.point[1] + lattice.fivedeex.point[2];
     y.point[1] = lattice.fivedeey.point[1] + lattice.fivedeey.point[2];
     z.point[1] = lattice.fivedeez.point[1] + lattice.fivedeez.point[2];
     initial_w.point[0] = lattice.fivedeew.point[1] + lattice.fivedeew.point[2];
     x.point[2] = lattice.fivedeex.point[2] + lattice.fivedeex.point[0];
     y.point[2] = lattice.fivedeey.point[2] + lattice.fivedeey.point[0];
     z.point[2] = lattice.fivedeez.point[2] + lattice.fivedeez.point[0];
     initial_w.point[0] = lattice.fivedeew.point[2] + lattice.fivedeew.point[0];
     println("Generating lattice to classify blocks as if they were chunks...");
     //Quasicrystal subblock_lattice = new Quasicrystal(initial_w.times(chunk_ratio), x.times(chunk_ratio), y.times(chunk_ratio), z.times(chunk_ratio), searchradius*(chunk_ratio));
     Quasicrystal subblock_lattice = new Quasicrystal(initial_w, x, y, z, searchradius);*/

    // Scale everything in chunk_lattice back up
    //println(chunk_lattice.fivedee0.minus(lattice.fivedee0).point);
    //println(chunk_lattice.fivedee1.minus(lattice.fivedee1).point);
    //println(chunk_lattice.fivedee2.minus(lattice.fivedee2).point);

    Point6D test = chunk_lattice.fivedee0.copy();
    test.point = Matrix.Multiply(Matrix.array(new float[][] {test.point}), im).array[0];
    chunk_lattice.fivedee0.set(test);
    test = chunk_lattice.fivedee1.copy();
    test.point = Matrix.Multiply(Matrix.array(new float[][] {test.point}), im).array[0];
    chunk_lattice.fivedee1.set(test);
    test = chunk_lattice.fivedee2.copy();
    test.point = Matrix.Multiply(Matrix.array(new float[][] {test.point}), im).array[0];
    chunk_lattice.fivedee2.set(test);
    println();
    println(chunk_lattice.fivedee0.minus(lattice.fivedee0).point);
    println(chunk_lattice.fivedee1.minus(lattice.fivedee1).point);
    println(chunk_lattice.fivedee2.minus(lattice.fivedee2).point);

    chunk_lattice.fivedee0.set(lattice.fivedee0);
    chunk_lattice.fivedee1.set(lattice.fivedee1);
    chunk_lattice.fivedee2.set(lattice.fivedee2);
    chunk_lattice.fivedeex.set(lattice.fivedeex);
    chunk_lattice.fivedeey.set(lattice.fivedeey);
    chunk_lattice.fivedeez.set(lattice.fivedeez);
    chunk_lattice.fivedeew.set(lattice.fivedeew);

    for (Object o : chunk_lattice.rhombs) {
      Rhomb rhomb = (Rhomb) o;
      Point6D rc = rhomb.center.copy();
      rc.point = Matrix.Multiply(Matrix.array(new float[][] {rc.point}), im).array[0];
      rhomb.center.set(rc);
    }
    for (Block b : (Iterable<Block>)(chunk_lattice.blocks)) {
      Point6D bc = b.center.copy();
      bc.point = Matrix.Multiply(Matrix.array(new float[][] {bc.point}), im).array[0];
      b.center.set(bc);
    }
    for (Vertex v : (Iterable<Vertex>)(chunk_lattice.cells)) {
      Point6D vv = v.copy();
      vv.point = Matrix.Multiply(Matrix.array(new float[][] {vv.point}), im).array[0];
      v.set(vv);
    }

    /*chunk_lattice.fivedeex.set(chunk_lattice.fivedeex.times(chunk_ratio));
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
     }*/

    // And everything in subblock_lattice down

    /*subblock_lattice.fivedee0.set(lattice.fivedeex);
     subblock_lattice.fivedee1.set(lattice.fivedeey);
     subblock_lattice.fivedee2.set(lattice.fivedeez);
     subblock_lattice.fivedeex.set(lattice.fivedeex);
     subblock_lattice.fivedeey.set(lattice.fivedeey);
     subblock_lattice.fivedeez.set(lattice.fivedeez);
     subblock_lattice.fivedeew.set(lattice.fivedeew);
     
     for (Object o : subblock_lattice.rhombs) {
     Rhomb rhomb = (Rhomb) o;
     Point6D rc = rhomb.center.copy();
     rc.point[0] = 0.5*rc.point[0]+-0.5*rc.point[1]+0.5*rc.point[2];
     rc.point[1] = 0.5*rc.point[0]+0.5*rc.point[1]+-0.5*rc.point[2];
     rc.point[2] = -0.5*rc.point[0]+0.5*rc.point[1]+0.5*rc.point[2];
     rhomb.center.set(rc);
     }*/

    /*subblock_lattice.fivedeex.set(subblock_lattice.fivedeex.times(1.0/chunk_ratio));
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

    main_lattice = lattice;//subblock_lattice;
    main_chunk_lattice = chunk_lattice;//lattice;
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

    //println(str(chunk_lattice.blocks.list.size())+" chunks, "+str(lattice.blocks.list.size())+" blocks, "+str(subblock_lattice.blocks.list.size())+" sub-blocks found.");
    println("Classifying chunks...");
    ArrayList<Chunk> classif1 = classifyChunks3D(chunk_lattice, lattice);
    println(str(classif1.size())+" unique chunks found.");
    println("Classifying blocks as if they were chunks...");
    //ArrayList<Chunk> classif2 = classifyChunks3D(lattice, subblock_lattice);
    //println(str(classif2.size())+" unique blocks found.");

    for (Chunk c : classif1) {
      if (c.instances.size() > 1) {
        for (Chunk ci : c.instances) {
          // For each instance, we want to print what chunk types its blocks are.
          String types = str(classif1.indexOf(c));
          int block_count = 0;
          for (Block b : ci.blocks) {
            /*for (Chunk s : classif2) {
             for (Chunk si : s.instances) {
             if (max(si.center.minus(b.center).abs().point) < 0.01) {
             types = types+" "+classif2.indexOf(s);
             block_count += 1;
             }
             }
             }*/
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
            decorations.add(block.center.copy());
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
  Vertex v = new Vertex(p.x, p.y, p.z, 0, 0, 0);
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

// TODO Add some tests which try and enforce the overall logic here.
//      - I can't make known_types static so every instance needs to
//        point to the same single ArrayList.
//      - A properly implemented subclass XChunk needs to be paired with
//        some subclass XChunkType; and XChunk needs to extend HierarchicalChunk<XChunkType>
//        and XChunkType needs to extend HierarchicalChunkType<XChunk>.
//        If I just extend HierarchicalChunk and HierarchicalChunkType (without
//        arguments), the result is fairly nonsensical.
//      - Would be nice to have a test that some_chunk.get_superchunks() returns only chunks
//        which do in fact contain some_chunk. It would be easy to forget to add the chunk itself.
//      - There should be some test that get_neighbors() returns a set which actually fully encloses a chunk.
//        IE, diagonals and edges don't need covered, but faces do. But with 6D chunks for example, the
//        concept of enclosure should still be 3D; so this is a test that would need to be written at
//        various subclass levels. Could still force any subclasses to create such a test.

abstract class HierarchicalChunk<T extends HierarchicalChunkType> {
  int level;
  T type;
  ArrayList<T> known_types;
  ArrayList<Block> blocks;
  ArrayList<HierarchicalChunk> subchunks;
  ArrayList<HierarchicalChunk> superchunks;

  // Straightforwardly returns any chunks contained in this one, instantiating
  // any not yet instantiated.
  // Note, they may also be contained in others (e.g. if they occur at a boundary).
  abstract ArrayList<? extends HierarchicalChunk> get_subchunks();

  // Returns all direct superchunks currently instantiated, instantiating
  // at least one if there are none.
  // TODO What's the best convention here? At first I figured this function
  // shouldn't instantiate any new superchunks, since being able to
  // provide new neighbors is more fundamental. Then I switched to, instantiate
  // at least one. I'm unsure if we can require it to instantiate them all;
  // in cases where the overlap at chunk boundaries is unpredictable, we
  // need information which might be hard to get.
  abstract ArrayList<? extends HierarchicalChunk> get_superchunks();

  // Returns neighbors on all sides, instantiating superchunks as
  // necessary. Note that if applied naively, this process may not
  // terminate, for example if a lattice of chunks doesn't actually
  // cover the entire space or if the theoretically complete lattice
  // which does cover the space isn't finitely connected. (For example,
  // a corner-centered hierarchy of nested cubes will contain axes accross 
  // which no chunk spans. But if it's really desired, this get_neighbors()
  // function can deal with that; there's no requirement that all neighbors
  // share some one superchunk.)
  // The potential issues multiply if the chunks are passing around data such
  // as terrain generation parameters. Neighboring chunks not connected by 
  // the hierarchy of superchunks, or just not connected by currently 
  // instantiated elements of that hierarchy, would need to coordinate via
  // some other pathway than the superchunks (or risk producing a sharp boundary
  // in the terrain).
  // TODO Realistically I want to optimize and ask for neighbors on a
  // certain side or vertex, rather than ever calling this function.
  // Is there a way to capture that here in the abstract class? Maybe
  // what I should do is just always ask for neighbors on a chunk of the
  // appropriate scale - replace "side or vertex" with sub-chunks.
  abstract ArrayList<? extends HierarchicalChunk> get_neighbors();
}

abstract class HierarchicalChunkType<C extends HierarchicalChunk> {
  /* The potenial difference between this class and HierarchicalChunk is
   * that in some cases we will need to store awkward types of abstraction
   * data. Two HierarchicalChunks with type equal to the same HierarchicalChunkType
   * will (I think) always have the same layout of sub-chunks, and quite possibly
   * also always the same layout of sub-sub-chunks. However, the HierarchicalChunks
   * also can come with some extra data which can differ up to tolerances. Any
   * subclass of HierarchicalChunkType needs to define the equivalence class on
   * that extra data for itself.
   * 
   */
  public abstract class InnerPositionedHierarchicalChunkType extends PositionedHierarchicalChunkType<C> {
    InnerPositionedHierarchicalChunkType() {
      type = HierarchicalChunkType.this;
    }

    // A constructor taking a subclass of HierarchicalChunkType needs to be implemented,
    // which is the reason this is abstract. How to code that properly? :/

    boolean isMyType(C c) {
      return HierarchicalChunkType.this.isMyType(c);
    }

    boolean sameSubchunkLayout(C c) {
      return HierarchicalChunkType.this.sameSubchunkLayout(c);
    }
  }
  ArrayList<InnerPositionedHierarchicalChunkType> subchunks;

  abstract boolean isMyType(C chunk);

  abstract boolean sameSubchunkLayout(C chunk);
}

abstract class PositionedHierarchicalChunkType<C extends HierarchicalChunk> extends HierarchicalChunkType<C> {
  /* This might be a really weird type of abstraction to implement, but I'm just going
   * to go with it. The idea is that any instance of HierarchicalChunkType is going to
   * have an inner class which extends PositionedHierarchicalChunkType. Instances of 
   * the inner class will know their Type to be that of their parent object. Eugh, I
   * can't really explain it properly.
   */

  Point6D pos;
  HierarchicalChunkType type;
}

// HierarchicalChunk Subclass Checklist:
//   Make the core subclass, XChunk; extend HierarchicalChunk<XChunkType>
//   Make the type class XChunkType; extend HierarchicalChunkType<XChunk>
//   Make the known_types list which gets handed to each XChunk instance in their constructor
//   Make the inner class, InnerPositionedXChunk

abstract class HierarchicalChunk3D<C extends HierarchicalChunkType> extends HierarchicalChunk<C> {
  /* 3D chunks have a literal 3D containment relationship with their
   * constituent blocks and sub-chunks. 
   */
  PVector pos;
}

abstract class HierarchicalChunk6D extends HierarchicalChunk {
  /* 6D chunks only have a literal containment relationship in 6D;
   * it doesn't work out in 3D.
   */
  Point6D pos;
}

ArrayList<CubeChunkType> known_cube_types = new ArrayList<CubeChunkType>();

class CubeChunk extends HierarchicalChunk3D<CubeChunkType> {
  ArrayList<CubeChunk> subchunks;
  ArrayList<CubeChunk> superchunks;
  ArrayList<CubeChunkType> known_types;


  public CubeChunk(PVector position, int h_level) {
    level = h_level;
    pos = position;
    known_types = known_cube_types;
    if (known_types.size() == 0) {
      // Set up known_types
      known_types.add(new CubeChunkType());
    }
    type = known_types.get(0);
  }

  public ArrayList<CubeChunk> get_subchunks() {
    // If we are level 0, we contain no chunks, and just
    // correspond to a block.
    if (level == 0) return null;
    if (subchunks == null) {
      long scale = Math.round(Math.pow(5.0, (double)(level - 1)));
      subchunks = new ArrayList<CubeChunk>();
      // Casting to <? extends PositionedHierarchicalChunkType> is odd; probably these chunks should be manufactured 
      // within a more knowledgeable scope.
      for (PositionedHierarchicalChunkType t: (Iterable<? extends PositionedHierarchicalChunkType>)type.subchunks) {
        subchunks.add(new CubeChunk(new PVector(t.pos.point[0]*scale+pos.x, t.pos.point[1]*scale+pos.y, t.pos.point[2]*scale+pos.z), level - 1));
      }
    }
    return subchunks;
  }

  public ArrayList<CubeChunk> get_superchunks() {
    if (superchunks == null) {
      superchunks = new ArrayList<CubeChunk>();
      // We need to calculate the position of the new chunk from our own.
      // Position is interpreted as the lowest-coordinate corner; ie, voxel
      // around origin has position (-.5, -.5, -.5).
      long scale = Math.round(Math.pow(5.0, (double)(level + 1)));
      Point6D origin_chunk_pos = new Point6D(-scale/2, -scale/2, -scale/2, 0, 0, 0);
      Point6D our_pos = new Point6D(pos.x, pos.y, pos.z, 0, 0, 0);
      Point6D chunk_scale_pos = our_pos.plus(origin_chunk_pos).times(1.0/scale);
      Point6D new_chunk_pos = new Point6D(floor(chunk_scale_pos.point[0]), floor(chunk_scale_pos.point[1]), 
        floor(chunk_scale_pos.point[2]), 0, 0, 0).times(scale).plus(origin_chunk_pos);
      CubeChunk superchunk = new CubeChunk(new PVector(new_chunk_pos.point[0], new_chunk_pos.point[1], new_chunk_pos.point[2]), level + 1);
      superchunks.add(superchunk);
      // Gotta add ourselves to the superchunk's subchunks. Since we test the nullity
      // of the subchunks list to see if we need to generate, that means adding all
      // subchunks to it.
      ArrayList<CubeChunk> new_relatives = superchunk.get_subchunks();
      for (CubeChunk c: new_relatives) {
        if (PVector.sub(pos, c.pos).mag() < 0.5) {
          superchunk.subchunks.remove(c);
          superchunk.subchunks.add(this);
          break;
        }
      }
      assert (superchunk.subchunks.contains(this)): "Failed to place chunk in its superchunk";
    }
    return superchunks;
  }

  public ArrayList<CubeChunk> get_neighbors() {
    /* I thought cubes would be dead simple, but this is actually a rather odd case. We can't just
     * keep asking for superchunks, since with a corner-centered lattice, there is no superchunk which
     * reaches over any axis. So if the current chunk has any face with a zero-coordinate, we need to 
     * return a chunk which is not associated to it via any shared superchunk. Creating an orphaned
     * chunk like this is risky; the chunk itself might actually already exist, or some distant 
     * superchunk or subchunk of it; we want to make sure everything gets connected properly.
     * 
     * TODO For now I'm solving this by making the lattice cube-centered. But at some point it would
     * be a good exercise to make a corner-centered cubic lattice work, and make terrain generation
     * which works within it. Might find some (pretty literal) edge cases which affect the overall
     * structure.
     */



    ArrayList<CubeChunk> neighbors = new ArrayList<CubeChunk>();
    long scale = Math.round(Math.pow(5.0, (double)(level)));
    CubeChunk superchunk = get_superchunks().get(0);
    ArrayList<CubeChunk> siblings = superchunk.get_subchunks();

    // Look for chunk-siblings which are adjacent to us.
    ArrayList<CubeChunk> adjacent = checkAdjacent(siblings);
    for (CubeChunk a: adjacent) neighbors.add(a);

    if (neighbors.size() != 6) {
      // Now we do a recursive search upwards into superchunks. Don't want this to instantiate too much
      // more than it needs to. However, we also don't want to be too stingy, or else we'll just end up
      // doing these searches a lot more. Also... we could literally just instantiate any missing neighbors,
      // but we want to avoid any need to search through non-hierarchically and see if chunks are
      // already instantiated.
      // ... But technically in a cubic grid, searching based on chunk coordinates should be easy and
      // should probably be done in favor of the present method.
      ArrayList<CubeChunk> super_neighbors = superchunk.get_neighbors();
      // We must be adjacent to one or more of these. Any we're adjacent to also holds
      // a neighboring chunk.
      for (CubeChunk scn : super_neighbors) {
        PVector scn_max = PVector.add(scn.pos, new PVector(scale, scale, scale));
        PVector our_max = PVector.add(scn.pos, new PVector(scale, scale, scale));
        PVector scn_min = scn.pos;
        PVector our_min = pos;
        if (abs(scn_max.x - our_min.x) < 0.5 || abs(scn_min.x - our_max.x) < 0.5) {
          // Since this is a neighbor of superchunk, our other dimensions must fall
          // within its other dimenions. TODO add all the other triangle inequalities here
          assert (abs(our_min.y - scn_min.y) < abs(scn_min.y - scn_max.y)) : 
          "Impossible chunk neighbor relationship (in y)";
          assert (abs(our_min.z - scn_min.z) < abs(scn_min.z - scn_max.z)) : 
          "Impossible chunk neighbor relationship (in z)";
          adjacent = checkAdjacent(scn.get_subchunks());
          for (CubeChunk a : adjacent) neighbors.add(a);
        }
        if (abs(scn_max.y - our_min.y) < 0.5 || abs(scn_min.y - our_max.y) < 0.5) {
          assert (abs(our_min.x - scn_min.x) < abs(scn_min.x - scn_max.x)) : 
          "Impossible chunk neighbor relationship (in y)";
          assert (abs(our_min.z - scn_min.z) < abs(scn_min.z - scn_max.z)) : 
          "Impossible chunk neighbor relationship (in z)";
          adjacent = checkAdjacent(scn.get_subchunks());
          for (CubeChunk a : adjacent) neighbors.add(a);
        }
        if (abs(scn_max.z - our_min.z) < 0.5 || abs(scn_min.z - our_max.z) < 0.5) {
          assert (abs(our_min.x - scn_min.x) < abs(scn_min.x - scn_max.x)) : 
          "Impossible chunk neighbor relationship (in y)";
          assert (abs(our_min.y - scn_min.y) < abs(scn_min.y - scn_max.y)) : 
          "Impossible chunk neighbor relationship (in z)";
          adjacent = checkAdjacent(scn.get_subchunks());
          for (CubeChunk a : adjacent) neighbors.add(a);
        }
      }
      // Now we should have 6 neighbors unless the lattice is basically broken.
      assert (neighbors.size() == 6): "Unable to produce 6 neighbors";
    }

    return neighbors;
  }

  ArrayList<CubeChunk> checkAdjacent(ArrayList<CubeChunk> siblings) {
    // Given a list of chunks (assumed to be of the same level as us), returns those which
    // are orthogonally adjacent to us.
    ArrayList<CubeChunk> neighbors = new ArrayList<CubeChunk>();

    for (CubeChunk s : siblings) {
      PVector relative_position = PVector.sub(pos, s.pos);
      relative_position.x = round(relative_position.x);
      relative_position.y = round(relative_position.y);
      relative_position.z = round(relative_position.z);
      // We're looking for relative positions of (-1,0,0), (1,0,0), (0,-1,0), (0,1,0), (0,0,-1), or (0,0,1).
      // For non-cube shapes, a list like this would still be sufficient; and the list could generally be
      // provided by the relevant subclass of HierarchicalChunkType. However, if one instance of 
      // HierarchicalChunkType represents various rotations of the same pattern, the proper list would
      // depend on the rotation.
      if (relative_position.x == 1.0 && relative_position.y == 0.0 && relative_position.z == 0.0 ||
        relative_position.x == -1.0 && relative_position.y == 0.0 && relative_position.z == 0.0 ||
        relative_position.x == 0.0 && relative_position.y == 1.0 && relative_position.z == 0.0 ||
        relative_position.x == 0.0 && relative_position.y == -1.0 && relative_position.z == 0.0 ||
        relative_position.x == 0.0 && relative_position.y == 0.0 && relative_position.z == 1.0 ||
        relative_position.x == 0.0 && relative_position.y == 0.0 && relative_position.z == -1.0)
      {
        neighbors.add(s);
      }
    }
    return neighbors;
  }

  // TODO For a cubic lattice, I can keep subchunks in an array and provide methods for obtaining the chunk
  // at particular coordinates. Do that and make the get_neighbors function use it.
}

class CubeChunkType extends HierarchicalChunkType<CubeChunk> {

  class PositionedCubeChunkType extends InnerPositionedHierarchicalChunkType {
    public PositionedCubeChunkType(CubeChunkType h) {
      // Hoping this works like I think it does
      h.super();
      assert(type == CubeChunkType.this);
    }
  }

  public CubeChunkType() {
    // There's only one chunk type in a cubic lattice. We'll do 5x5x5 chunks
    for (int i = 0; i < 5; i++) for (int j = 0; j < 5; j++) for (int k = 0; k < 5; k++) {
      PositionedCubeChunkType subchunk = new PositionedCubeChunkType(this);
      subchunk.pos = new Point6D(i, j, k, 0, 0, 0);
      subchunks.add(subchunk);
    }
  }

  boolean isMyType(CubeChunk c) {
    return true;
  }

  boolean sameSubchunkLayout(CubeChunk c) {
    return true;
  }
}

//class DanzerChunk extends HierarchicalChunk3D {
//  
//}

//class P3D extends HierarchicalChunk3D {
//  
//}

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
