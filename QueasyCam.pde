/**
 * QueasyCam library, grabbed from https://github.com/jrc03c/queasycam.
 *
 * ##library.name##
 * ##library.sentence##
 * ##library.url##
 *
 * Copyright ##copyright## ##author##
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General
 * Public License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA  02111-1307  USA
 * 
 * @author      ##author##
 * @modified    ##date##
 * @version     ##library.prettyVersion## (##library.version##)
 */

//package queasycam;

import java.awt.MouseInfo;
import java.awt.Point;
import java.awt.Robot;
import java.awt.GraphicsEnvironment;
import java.util.HashMap;
import processing.core.*;
import processing.event.KeyEvent;

public class QueasyCam {
  public final static String VERSION = "##library.prettyVersion##";

  public boolean controllable;
  public float speed;
  public float sensitivity;
  public PVector position;
  public float pan;
  public float tilt;
  public PVector velocity;
  public float friction;

  private PApplet applet;
  private Robot robot;
  private PVector center;
  private PVector up;
  private PVector right;
  private PVector forward;
    private PVector target;
  private Point mouse;
  private Point prevMouse;
  private HashMap<Character, Boolean> keys;

  public QueasyCam(PApplet applet){
    this.applet = applet;
    applet.registerMethod("draw", this);
    applet.registerMethod("keyEvent", this);
    
    try {
      robot = new Robot();
    } catch (Exception e){}

    controllable = true;
    speed = 3f;
    sensitivity = 2f;
    position = new PVector(0f, 0f, 0f);
    up = new PVector(0f, 1f, 0f);
    right = new PVector(1f, 0f, 0f);
    forward = new PVector(0f, 0f, 1f);
    velocity = new PVector(0f, 0f, 0f);
    pan = 0f;
    tilt = 0f;
    friction = 0.75f;
    keys = new HashMap<Character, Boolean>();

    applet.perspective(PConstants.PI/3f, (float)applet.width/(float)applet.height, 0.01f, 1000f);
  }
    
    public QueasyCam(PApplet applet, float near, float far){
        this.applet = applet;
        applet.registerMethod("draw", this);
        applet.registerMethod("keyEvent", this);
        
        try {
            robot = new Robot();
        } catch (Exception e){}
        
        controllable = true;
        speed = 3f;
        sensitivity = 2f;
        position = new PVector(0f, 0f, 0f);
        up = new PVector(0f, 1f, 0f);
        right = new PVector(1f, 0f, 0f);
        forward = new PVector(0f, 0f, 1f);
        velocity = new PVector(0f, 0f, 0f);
        pan = 0f;
        tilt = 0f;
        friction = 0.75f;
        keys = new HashMap<Character, Boolean>();
        
        applet.perspective(PConstants.PI/3f, (float)applet.width/(float)applet.height, near, far);
    }

  public void draw(){
    if (!controllable) return;
    
    mouse = MouseInfo.getPointerInfo().getLocation();
    if (prevMouse == null) prevMouse = new Point(mouse.x, mouse.y);
    
    int w = GraphicsEnvironment.getLocalGraphicsEnvironment().getMaximumWindowBounds().width;
    int h = GraphicsEnvironment.getLocalGraphicsEnvironment().getMaximumWindowBounds().height;
    
    if (mouse.x < 1 && (mouse.x - prevMouse.x) < 0){
      robot.mouseMove(w-2, mouse.y);
      mouse.x = w-2;
      prevMouse.x = w-2;
    }
        
    if (mouse.x > w-2 && (mouse.x - prevMouse.x) > 0){
      robot.mouseMove(2, mouse.y);
      mouse.x = 2;
      prevMouse.x = 2;
    }
    
    if (mouse.y < 1 && (mouse.y - prevMouse.y) < 0){
      robot.mouseMove(mouse.x, h-2);
      mouse.y = h-2;
      prevMouse.y = h-2;
    }
    
    if (mouse.y > h-1 && (mouse.y - prevMouse.y) > 0){
      robot.mouseMove(mouse.x, 2);
      mouse.y = 2;
      prevMouse.y = 2;
    }
    
    pan += PApplet.map(mouse.x - prevMouse.x, 0, applet.width, 0, PConstants.TWO_PI) * sensitivity;
    tilt += PApplet.map(mouse.y - prevMouse.y, 0, applet.height, 0, PConstants.PI) * sensitivity;
    tilt = clamp(tilt, -PConstants.PI/2.01f, PConstants.PI/2.01f);
    
    if (tilt == PConstants.PI/2) tilt += 0.001f;

    forward = new PVector(PApplet.cos(pan), PApplet.tan(tilt), PApplet.sin(pan));
    forward.normalize();
    right = new PVector(PApplet.cos(pan - PConstants.PI/2), 0, PApplet.sin(pan - PConstants.PI/2));
        
        target = PVector.add(position, forward);
    
    prevMouse = new Point(mouse.x, mouse.y);
    
    if (keys.containsKey('a') && keys.get('a')) velocity.add(PVector.mult(right, speed));
    if (keys.containsKey('d') && keys.get('d')) velocity.sub(PVector.mult(right, speed));
    if (keys.containsKey('w') && keys.get('w')) velocity.add(PVector.mult(forward, speed));
    if (keys.containsKey('s') && keys.get('s')) velocity.sub(PVector.mult(forward, speed));
    if (keys.containsKey('q') && keys.get('q')) velocity.add(PVector.mult(up, speed));
    if (keys.containsKey('e') && keys.get('e')) velocity.sub(PVector.mult(up, speed));

    velocity.mult(friction);
    position.add(velocity);
    center = PVector.add(position, forward);
    applet.camera(position.x, position.y, position.z, center.x, center.y, center.z, up.x, up.y, up.z);
  }
  
  public void keyEvent(KeyEvent event){
    char key = event.getKey();
    
    switch (event.getAction()){
      case KeyEvent.PRESS: 
        keys.put(Character.toLowerCase(key), true);
        break;
      case KeyEvent.RELEASE:
        keys.put(Character.toLowerCase(key), false);
        break;
    }
  }
    
    public void beginHUD()
    {
        g.pushMatrix();
        g.hint(DISABLE_DEPTH_TEST);
        g.resetMatrix();
        g.applyMatrix(originalMatrix);
    }
    
    public void endHUD()
    {
        g.hint(ENABLE_DEPTH_TEST);
        g.popMatrix();
    }
  
  private float clamp(float x, float min, float max){
    if (x > max) return max;
    if (x < min) return min;
    return x;
  }
  
  public PVector getForward(){
    return forward;
  }
  
  public PVector getUp(){
    return up;
  }
  
  public PVector getRight(){
    return right;
  }
    
    public PVector getTarget(){
        return target;
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
