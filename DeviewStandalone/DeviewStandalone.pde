/* 

 Deviewing effect developped
 by Raphaël de Courville & Dimitar Ruszev
 for ART+COM (artcom.de)

 This effect was developped for
 the redesign of an interactive piece by 
 Joachim Sauter & Dirk Lüsebrink called 
 the “Zehrseher” (or “Deviewer” in English).
 The new version was shown at the exhibition 
 “Vertigo Of Reality” at ADK (Berlin) in 2014.
 
 More: http://artcom.de/de/blog/on-the-development-of-the-new-zerseher/

 The fabric simulation is based on:

 "Curtain" by Jared Counts, licensed under Creative Commons Attribution-Share Alike 3.0 and GNU GPL license.
 Work: http://www.openprocessing.org/sketch/20140 
 License: 
 http://creativecommons.org/licenses/by-sa/3.0/
 http://creativecommons.org/licenses/GPL/2.0/
  
*/

import java.util.List;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.Set;
import java.awt.Rectangle;
import gnu.trove.*;

// Render target
PGraphics myPG;

// Position of the focus (the mouse cursor is used here)
PVector previousFocus, currentFocus;

int incrementEvery = 500; // how many ms between each increment?
int lastIncrementTime = 0;

// TODO: make this generic
int sketchWidth  = 1920;
int sketchHeight = 1080;

// Starting length of the links 
// Should be a common factor of width and height
// For 1920 and 1200:  1, 2, 3, 4, 5, 6, 8, 10, 12, 15, 16, 20, 24, 30, 40, 48, 60, 80, 120, 240
float restingDistance = 20;

// Dimensions for our curtain. These are number of particles for each direction, not actual widths and heights
// the true width and height can be calculated by multiplying restingDistance by the curtain dimensions
int curtainWidth = int(sketchWidth/restingDistance);
int curtainHeight = int(sketchHeight/restingDistance);
int PARTICLE_COUNT = (curtainWidth + 1) * (curtainHeight + 1); 

//List<Particle> particles;
//Particle[][] particles = new Particle[curtainWidth + 1][curtainHeight + 1];
Particle[] particles = new Particle[PARTICLE_COUNT];

int yOffset = 0; // where will the curtain start on the y axis?

// every particle within this many pixels will be influenced by the cursor
float influenceSize = 60;
float maxInfluence = 50;
float minInfluence = 10;

// minimum distance for tearing (just removing links) 
// TODO: remove this
float tearSize = 15;

// we square the influenceSize and tearSize so we don't have to use squareRoot when comparing distances with this.
float influenceSizeSquared = influenceSize * influenceSize;
float tearSizeSquared = tearSize * tearSize;

float gravity = 0.0;

// We'll make the mesh stiffer going from the center out
float minStiffness = 0.08;
float maxStiffness = 0.5;

float influenceScalar = 0.5;

// These variables are used to keep track of how much time is elapsed between each frame
// they're used in the physics to maintain a certain level of accuracy and consistency
// this program should run the at the same rate whether it's running at 30 FPS or 300,000 FPS
long previousTime;
long currentTime;
// Delta means change. It's actually a triangular symbol, to label variables in equations
// some programmers like to call it elapsedTime, or changeInTime. It's all a matter of preference
// To keep the simulation accurate, we use a fixed time step.
int fixedDeltaTime = 15;
float fixedDeltaTimeSeconds = (float)fixedDeltaTime / 1000.0;

// the leftOverDeltaTime carries over change in time that isn't accounted for over to the next frame
int leftOverDeltaTime = 0;

// How many times are the constraints solved for per frame:
int constraintIterations = 2;

//boolean useTimeAdjustment = true;
boolean useTimeAdjustment = false;

PImage texture;

Fabric myFabric;

VertexData myPrevVertexData, myCurrVertexData, myTexData;

// What it takes to break the mesh
final float originalInnerResistanceFactor = 20; // in the center
final float originalOuterResistanceFactor = 64; // on the edges

// we want the resistance of the mesh to decrease over time
float targetInnerResistanceFactor   = 1;  // in the center
float targetOuterResistanceFactor   = 10; // on the edges
float resistanceFactorInc           = -0.5; // by how much

// Resistance values to be modified
float currentInnerResistanceFactor, currentOuterResistanceFactor;

void setup() {
  
  size(sketchWidth,sketchHeight,P3D); //<>//

  myPG = createGraphics(width,height,P3D);

  // texture = myCameraModel.getCurrentEyeImage();
  texture = loadImage("eye.png");

  // Initialize the focus
  currentFocus = new PVector(mouseX, mouseY);
  previousFocus = currentFocus;

  myPrevVertexData = new VertexDataArray((curtainWidth + 1), (curtainHeight + 1), 2);
  myCurrVertexData = new VertexDataArray((curtainWidth + 1), (curtainHeight + 1), 2);
  myTexData = new VertexDataArray((curtainWidth + 1), (curtainHeight + 1), 2);

  currentInnerResistanceFactor = originalInnerResistanceFactor;
  currentOuterResistanceFactor = originalOuterResistanceFactor;

  // create the curtain (do this last)
  createCurtain(texture); //<>//

}

void draw() {
 
  /******** Physics ********/
  // time related stuff
  currentTime = millis();
  // deltaTimeMS: change in time in milliseconds since last frame
  long deltaTimeMS = currentTime - previousTime;
  previousTime = currentTime; // reset previousTime
  // timeStepAmt will be how many of our fixedDeltaTime's can fit in the physics for this frame. 
  int timeStepAmt = (int)((float)(deltaTimeMS + leftOverDeltaTime) / (float)fixedDeltaTime);
  // Here we cap the timeStepAmt to prevent the iteration count from getting too high and exploding
  timeStepAmt = min(timeStepAmt, 5);
  
  leftOverDeltaTime += (int)deltaTimeMS - (timeStepAmt * fixedDeltaTime); // add to the leftOverDeltaTime.

  // Override timestep calculations

  if(!useTimeAdjustment) {
    timeStepAmt = 1;
  }

  // If the mouse is pressing, it's influence will be spread out over every iteration in equal parts.
  // This keeps the program from exploding from user interaction if the timeStepAmt gets too high.
  influenceScalar = 1.0 / timeStepAmt;

  if(millis() - lastIncrementTime > incrementEvery) {
    // Make the mesh less and less resistant
    currentInnerResistanceFactor = constrain(currentInnerResistanceFactor + resistanceFactorInc, min(originalInnerResistanceFactor, targetInnerResistanceFactor), max(originalInnerResistanceFactor, targetInnerResistanceFactor));
    currentOuterResistanceFactor = constrain(currentOuterResistanceFactor + resistanceFactorInc, min(originalOuterResistanceFactor, targetOuterResistanceFactor), max(originalOuterResistanceFactor, targetOuterResistanceFactor));
    lastIncrementTime = millis(); // reset the counter
  }

  // update physics
  for (int iteration = 1; iteration <= timeStepAmt; iteration++) {
    ///update tearDistance
    for (Particle particle : particles) {
      particle.setTearDistance(currentInnerResistanceFactor, currentOuterResistanceFactor);
    }

    // solve the constraints multiple times
    // the more it's solved, the more accurate.
    for (int acc = 0; acc < constraintIterations; acc++) {
      for (Particle particle : particles) {
        particle.solveConstraints();
      }
    }
    
    previousFocus = currentFocus;
    currentFocus = new PVector(mouseX,mouseY);

    // Make the influence stronger in the center
    float falloff = getCenterFalloff(currentFocus.x, currentFocus.y);
    float influence = lerp(maxInfluence,minInfluence,falloff);

    // update each particle's position  
    for (Particle particle : particles) {
      particle.updateInteractions(
        previousFocus,
        currentFocus,
        influenceSizeSquared,
        tearSizeSquared,
        influenceScalar,
        influence
      );
      particle.updatePhysics(fixedDeltaTimeSeconds, gravity);
    }
  }

  myFabric.update();

  /*  BEGIN DRAW  */

  myPG.beginDraw();
  myPG.background(0);
  
  myFabric.display(myPG);
  
  myPG.stroke(100);
  myPG.beginShape(LINES);

  for (Particle particle : particles) {
    particle.draw(myPG);
  }

  myPG.endShape();

  myPG.endDraw();

  /*  END DRAW  */

  image(myPG,0,0,width,height);

}

void createCurtain(PImage _texture) {
  // We use an ArrayList instead of an array so we could add or remove particles at will.
  // not that it isn't possible using an array, it's just more convenient this way
  // particles = new ArrayList<Particle>(PARTICLE_COUNT);
  
  // midWidth: amount to translate the curtain along x-axis for it to be centered
  // (curtainWidth * restingDistance) = curtain's pixel width
  int midWidth = (int) (width/2 - (curtainWidth * restingDistance)/2);

  int index = 0;
  for (int y = 0; y <= curtainHeight; y++) { // due to the way particles are attached, we need the y loop on the outside
    for (int x = 0; x <= curtainWidth; x++) { 

      PVector pos = new PVector(midWidth + x * restingDistance, y * restingDistance + yOffset);

      myCurrVertexData.x(x, y, pos.x);
      myCurrVertexData.y(x, y, pos.y);
      myPrevVertexData.x(x, y, pos.x);
      myPrevVertexData.y(x, y, pos.y);

      PVector texCoord = new PVector(float(x)/curtainWidth,float(y)/curtainHeight);

      myTexData.x(x, y, texCoord.x);
      myTexData.y(x, y, texCoord.y);

      Particle particle = new Particle(x, y, myPrevVertexData, myCurrVertexData, myTexData, curtainWidth + 1, curtainHeight + 1);
      
      // Fix the position of the border particles
      if (x == 0 || y == 0 || x == curtainWidth || y == curtainHeight){
        particle.pinTo(particle.getX(), particle.getY());
      }
      
      // give stronger links to particles further from the center
      float xPixels = (float)x*restingDistance; // initial position of the particle in screen coordinates
      float yPixels = (float)y*restingDistance; // initial position of the particle in screen coordinates
      float distanceLimit = 0.5;

      float falloff = getCenterFalloff(xPixels, yPixels);
      float stiffness = lerp(minStiffness, maxStiffness,falloff);
      float resistanceFactor = lerp(currentInnerResistanceFactor, currentOuterResistanceFactor, falloff);

      // attach to 
      // x - 1  and
      // y - 1  
      // particle attachTo parameters: Particle particle, float restingDistance, float stiffness
      if (x != 0) {
        particle.attachTo(particles[index-1], restingDistance, stiffness, resistanceFactor);
      }
      if (y != 0) {
        particle.attachTo(particles[index - (curtainWidth + 1)], restingDistance, stiffness, resistanceFactor);
      }
        
      // shearing, presumably. Attaching invisible links diagonally between points can give our cloth stiffness.
      // the stiffer these are, the more our cloth acts like jello. 
      if ((x != 0) && (y != 0)) {
        particle.attachTo(particles[index - (curtainWidth + 1) - 1], restingDistance * sqrt(2), stiffness/4, resistanceFactor);
      }
      if ((x != curtainWidth) && (y != 0)) {
        particle.attachTo(particles[index - (curtainWidth + 1) + 1], restingDistance * sqrt(2), stiffness*2, resistanceFactor);
      }
   
      // add to particle array
      particles[index] = particle;
      index++;

    }
  }

  index = 0;
  myFabric = new Fabric(_texture, PARTICLE_COUNT);
  for (int y = 0; y < curtainHeight; y++) { // due to the way particles are attached, we need the y loop on the outside
    for (int x = 0; x < curtainWidth; x++) {
      Quad q = new Quad(myFabric);
      q.addParticle(particles[index], 0);
      q.addParticle(particles[index + 1], 1);
      q.addParticle(particles[index + 1 + curtainWidth + 1], 2);
      q.addParticle(particles[index +     curtainWidth + 1], 3);
      index++;
    }
    index++;
  }
}

// 0.0: the point is at the center
// 1.0: the point is a the a distance of height/2 from the center
float getCenterFalloff(float theX, float theY){
  float xAdjusted = theX / width * height + (width-height)/2;
  float d = dist(width/2,height/2, xAdjusted, theY) / (height/2);
  d = constrain(d,0.0,1.0);
  return d;
}

void toggleGravity () {
  if (gravity != 0.0) {
    gravity = 0.0;
  }
  else {
    gravity = 392.0;
  }
}

PVector[] getTexCoordinates(PImage img, Rectangle rect) {
  int w = img.width;
  int h = img.height;

  float x0 = rect.x;
  float y0 = rect.y;
  float w0 = rect.width;
  float h0 = rect.height;

  PVector[] v = new PVector[4];
  v[0] = new PVector(x0, y0);
  v[1] = new PVector(x0 + w0, y0);
  v[2] = new PVector(x0 + w0, y0 + h0);
  v[3] = new PVector(x0, y0 + h0);

  PVector[] u  = new PVector[2];
  u[0] = new PVector();
  u[1] = new PVector(w, h);

  PVector[] st = new PVector[4];
  for (int i = 0; i < st.length; i++) {
    st[i] = getST(v[i], u[0], u[1]);
  }

  return st;
}

PVector getST(PVector p, PVector v0, PVector v1) {
  return new PVector((p.x - v0.x)/(v1.x - v0.x), (p.y - v0.y)/(v1.y - v0.y));
}

/*
void handleEvent(CCStateEvent theEvent) {
  super.handleEvent(theEvent);
  if (theEvent.id().equals(Events.Keyboard.toString())) {
    switch (((String)theEvent.parameter("key")).charAt(0)) {
      case 'r':
        currentInnerResistanceFactor = originalInnerResistanceFactor;
        currentOuterResistanceFactor = originalOuterResistanceFactor;
        createCurtain(texture);
        break;

      case 't':
        useTimeAdjustment = !useTimeAdjustment;
        break;

      case 'g':
        toggleGravity();
        break;
    }
  }
}
*/
