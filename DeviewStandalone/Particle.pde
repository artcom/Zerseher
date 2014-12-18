// the Particle class.
class Particle {
  //PVector lastPosition; // for calculating position change (velocity)
  //PVector position;  

  float mass = 1;
  float damping = 20;

  // An ArrayList for links, so we can have as many links as we want to this particle :)
  Set<Link> links = new THashSet<Link>();
  Set<Link> linksToBeRemoved = new THashSet<Link>();
  
  boolean pinned = false;
  //PVector pinLocation = new PVector(0,0);

  //PVector texCoord = new PVector(0,0);
  
  final int myI, myJ;
  float pinLocationX, pinLocationY;
  VertexData prevVD, currVD, texData;

  final float normDist;

  // Particle constructor  
  Particle (int i, int j, VertexData thePrevVD, VertexData theCurrVD, VertexData theTexData, int theVertexCountHor, int theVertexCountVer) {
    myI = i;
    myJ = j;
    texData = theTexData;
    prevVD = thePrevVD;
    currVD = theCurrVD;
    normDist = constrain(sqrt(sq((float)i/theVertexCountHor - 0.5f) + sq((float)j/theVertexCountVer - 0.5f)) * 2f, 0f, 1f);
  }

  // The update function is used to update the physics of the particle.
  // motion is applied, and links are drawn here
  void updatePhysics (float timeStep, float gravity) { // timeStep should be in elapsed seconds (deltaTime)
    // gravity:
    // f(gravity) = m * g
    if (pinned) return;    
    /*
    PVector acceleration = new PVector(0, gravity);
    
    //Verlet Integration, WAS using http://archive.gamedev.net/reference/programming/features/verlet/ 
    //however, we're using the tradition Velocity Verlet integration, because our timestep is now constant.
    // velocity = position - lastPosition
    PVector velocity = PVector.sub(position, lastPosition);
    // apply damping: acceleration -= velocity * (damping/mass)
    acceleration.sub(PVector.mult(velocity,damping/mass)); 
    // newPosition = position + velocity + 0.5 * acceleration * deltaTime * deltaTime
    */
    float currX = getX();
    float currY = getY();
    float prevX = getPX();
    float prevY = getPY();


    float accX = 0       - (currX - prevX) * damping / mass;
    float accY = gravity - (currY - prevY) * damping / mass;

    float nextX = currX + (currX - prevX) + accX * 0.5 * timeStep * timeStep;
    float nextY = currY + (currY - prevY) + accY * 0.5 * timeStep * timeStep; 

    //PVector nextPos = PVector.add(PVector.add(position, velocity), PVector.mult(PVector.mult(acceleration, 0.5), timeStep * timeStep));
    
    // reset variables
    //lastPosition.set(position);
    //position.set(nextPos);
    setPX(currX);
    setPY(currY);
    setX(nextX);
    setY(nextY);
  }

  public void updateInteractions(PVector previousFocus, PVector currentFocus, float influenceSizeSquared, float tearSizeSquared, float influenceScalar, float maxInfluence) {
    // this is where our interaction comes in.
    // if (mousePressed) {
      if (pinned) return;
      float distanceSquared = distPointToSegmentSquared(previousFocus.x,previousFocus.y,currentFocus.x,currentFocus.y,this.getX(),this.getY());
      // if (mouseButton == LEFT) {
        if (distanceSquared < influenceSizeSquared) {
          // To change the velocity of our particle, we subtract that change from the lastPosition.
          // When the physics gets integrated (see updatePhysics()), the change is calculated
          // Here, the velocity is set equal to the cursor's velocity
          //lastPosition = PVector.sub(position, new PVector((currentFocus.x-previousFocus.x)*influenceScalar, (currentFocus.y-previousFocus.y)*influenceScalar));
          PVector delta = PVector.sub(currentFocus,previousFocus);
          delta.limit(maxInfluence); 
          float lastX = getX() - (delta.x)*influenceScalar;
          float lastY = getY() - (delta.y)*influenceScalar;
          setPX(lastX);
          setPY(lastY);
        }
  }

  void draw (PGraphics myPG) {
    // draw the links and points
    //stroke(0);
    //if (links.size() > 0) {
      for (Link currentLink : links) {
        currentLink.draw(myPG);
    //}
    //} else {
    //  myPG.point(position.x, position.y);
    }
  }
  /* Constraints */
  void solveConstraints () {
    /* Link Constraints */
    // Links make sure particles connected to this one is at a set distance away
    for (Link currentLink : links) {
      currentLink.constraintSolve();
    }
    
    //remove links marked for removal
    for (Link l : linksToBeRemoved) {
      links.remove(l);
    }
    linksToBeRemoved.clear();

    /* Boundary Constraints */
    // These if statements keep the particles within the screen
    float currX = getX();
    float currY = getY();

    /*
    if (position.y < 1) {
      position.y = 2 * (1) - position.y;
    }
    if (position.y > height-1) {
      position.y = 2 * (height - 1) - position.y;
    }
    if (position.x > width-1) {
      position.x = 2 * (width - 1) - position.x;
    }
    if (position.x < 1){
      position.x = 2 * (1) - position.x;
    }
    */

    if (currY < 1) {
      currY = 2 * (1) - currY;
    }
    if (currY > height-1) {
      currY = 2 * (height - 1) - currY;
    }
    if (currX > width-1) {
      currX = 2 * (width - 1) - currX;
    }
    if (currX < 1){
      currX = 2 * (1) - currX;
    }

    setX(currX);
    setY(currY);

    /* Other Constraints */
    // make sure the particle stays in its place if it's pinned
    if (pinned) {
      //position.set(pinLocation);
      setX(pinLocationX);
      setY(pinLocationY);
      return;
    }
  }
  
  // attachTo can be used to create links between this particle and other particles
  void attachTo (Particle P, float restingDist, float stiff, float tearFactor) {
    Link lnk = new Link(this, P, restingDist, stiff, tearFactor);
    links.add(lnk);
  }
  void removeLink (Link lnk) {
    linksToBeRemoved.add(lnk);
  }  
  
  void pinTo (float x, float y) {
    pinned = true;
    pinLocationX = x;
    pinLocationY = y;
  }

  /* replaced by getX() and getY()
  PVector getPosition() {
    return position;
  }
  */
  /*
  PVector getTexCoord(){
    return texCoord;
  }
  */

  float getS() {
    return getCoordinateX(texData);
  }

  float getT() {
    return getCoordinateY(texData);
  }

  // Credit to: http://www.codeguru.com/forum/showpost.php?p=1913101&postcount=16
  float distPointToSegmentSquared (float lineX1, float lineY1, float lineX2, float lineY2, float pointX, float pointY) {
    float vx = lineX1 - pointX;
    float vy = lineY1 - pointY;
    float ux = lineX2 - lineX1;
    float uy = lineY2 - lineY1;
    
    float len = ux*ux + uy*uy;
    float det = (-vx * ux) + (-vy * uy);
    if ((det < 0) || (det > len)) {
      ux = lineX2 - pointX;
      uy = lineY2 - pointY;
      return min(vx*vx+vy*vy, ux*ux+uy*uy);
    }
    
    det = ux*vy - uy*vx;
    return (det*det) / len;
  }

  void setTearDistance(float theInnerResistanceFactor, float theOuterResistanceFactor) {
    float theResistanceFactor = map(normDist, 0f, 1f, theInnerResistanceFactor, theOuterResistanceFactor);
    for (Link l : links) {
      l.setTearDistance(theResistanceFactor);
    }
  }

  float getCoordinateX(VertexData vd) {
    return vd.x(myI, myJ);
  }

  void setCoordinateX(VertexData vd, float theX) {
    vd.x(myI, myJ, theX);
  }

  float getCoordinateY(VertexData vd) {
    return vd.y(myI, myJ);
  }

  void setCoordinateY(VertexData vd, float theY) {
    vd.y(myI, myJ, theY);
  }

  float getX() {
    return getCoordinateX(currVD);
  }

  float getPX() {
    return getCoordinateX(prevVD);
  }

  void setX(float theX) {
    setCoordinateX(currVD, theX);
  }

  void setPX(float theX) {
    setCoordinateX(prevVD, theX);
  }

  float getY() {
    return getCoordinateY(currVD);
  }

  float getPY() {
    return getCoordinateY(prevVD);
  }

  void setY(float theY) {
    setCoordinateY(currVD, theY);
  }

  void setPY(float theY) {
    setCoordinateY(prevVD, theY);
  }

}
