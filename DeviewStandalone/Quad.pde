class Quad {
  
  Set<Link> links = new THashSet<Link>();
  Particle[] particles = new Particle[4];
  Fabric myFabric;

  Quad(Fabric f){
  	myFabric = f;
  	myFabric.addQuad(this);
  }

  void _addLinks(Set<Link> newLinks) {
  	for (Link l : newLinks) {
  		links.add(l);
  		l.addQuad(this);	
  	}
  }

  void delete(Link caller) {
  	for (Link l : links) {
  		if (!l.equals(caller)) {
  			l.removeQuad(this);
        l.setEdge(true);
  		}
  	}
	  myFabric.removeQuad(this);
  }

  void addParticle(Particle p, int i) {
  	particles[i] = p;
  	_addLinks(p.links);
  }

  Particle[] getParticles(){
    return particles;
  }

  void display(PGraphics myPG){
    for(Particle p : particles){
      //PVector pos = p.getPosition();
      //PVector texCoord  = p.getTexCoord();
      myPG.vertex(p.getX(), p.getY(), p.getS(), p.getT());
      //myPG.vertex(pos.x, pos.y, 0.1, 0.1);
      //LOGGER.info("texCoord=",texCoord);
    }
  }
}