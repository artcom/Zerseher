// The Link class is used for handling constraints between particles.
class Link {
  float restingDistance;
  float stiffness;
  float tearDistance;

  // is the link adjacent to a dead quad?
  boolean isEdge = false;
  
  Particle p1;
  Particle p2;
  
  // the scalars are how much "tug" the particles have on each other
  // this takes into account masses and stiffness, and are set in the Link constructor
  float scalarP1;
  float scalarP2;

  // if you want this link to be invisible, set this to false
  boolean drawThis = false;
  
  Set<Quad> quads = new THashSet<Quad>(2);

  Link (Particle theFirstParticle, Particle theSecondParticle, float theRestingDistance, float theStiffness, float theTearFactor) {
    p1 = theFirstParticle; // when you set one object to another, it's pretty much a reference. 
    p2 = theSecondParticle; // Anything that'll happen to p1 or p2 in here will happen to the paticles in our array
    
    restingDistance = theRestingDistance;
    stiffness = theStiffness;
    setTearDistance(theTearFactor);

    // although there are no differences in masses for the curtain, 
    // this opens up possibilities in the future for if we were to have a fabric with particles of different weights
    float im1 = 1 / p1.mass; // inverse mass quantities
    float im2 = 1 / p2.mass;
    scalarP1 = (im1 / (im1 + im2)) * stiffness;
    scalarP2 = (im2 / (im1 + im2)) * stiffness;
  }
  
  void constraintSolve() {
    // calculate the distance between the two particles
    //PVector delta = PVector.sub(p1.position, p2.position);
    float delta_x = p1.getX() - p2.getX();
    float delta_y = p1.getY() - p2.getY();
    //float d = delta.mag();
    float d = sqrt(sq(delta_x) + sq(delta_y));
    float difference = (restingDistance - d) / d;

    // P1.position += delta * scalarP1 * difference
    // P2.position -= delta * scalarP2 * difference
    if (!p1.pinned) {
      //p1.position.add(PVector.mult(delta, scalarP1 * difference));
      p1.setX(p1.getX() + delta_x * scalarP1 * difference);
      p1.setY(p1.getY() + delta_y * scalarP1 * difference);
    }

    if (!p2.pinned) {
      //p2.position.sub(PVector.mult(delta, scalarP2 * difference));
      p2.setX(p2.getX() - delta_x * scalarP2 * difference);
      p2.setY(p2.getY() - delta_y * scalarP2 * difference);
    }
        
    if (d > tearDistance) { 
      delete(p1);
    }    
  }

  void setTearDistance(float theResistanceFactor) {
    tearDistance = theResistanceFactor * restingDistance;
  }

  void delete(Particle p1) {
    // if the distance is more than curtainTearSensitivity, the cloth tears
    // it would probably be better if force was calculated, but this works
    p1.removeLink(this);
    for (Quad q : quads) {
      q.delete(this);
    }
    quads.clear();
    setEdge(true);    
  }

  void draw(PGraphics myPG) {
    if (!drawThis) return;

    myPG.vertex(p1.getX(), p1.getY());
    myPG.vertex(p2.getX(), p2.getY());
  }

  void addQuad(Quad q) {
    quads.add(q);
  }

  void removeQuad(Quad q) {
    quads.remove(q);
    //LOGGER.info("removing quad");
  }

  void setEdge(boolean b) {
    isEdge = b;
    drawThis = b;
  }
}