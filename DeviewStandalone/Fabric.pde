class Fabric {

	PImage tex;

	Set<Quad> quads;
	boolean updateFlag = false;

	Fabric(PImage texture, int particleCount) {
		quads = new THashSet<Quad>(particleCount);
		tex = texture;
	}

	void _updateModel() {
		//LOGGER.info("update model called.");
		//LOGGER.info("quads.size()=" + quads.size());
	}

	void update() {
		if (updateFlag) {
			_updateModel();
			updateFlag = false;
		}
	}

	void display(PGraphics myPG) {
		myPG.noStroke();
    	myPG.beginShape(QUADS);
    	myPG.textureMode(NORMAL);
	    myPG.texture(tex);

		for(Quad q : quads){
			q.display(myPG);
		}

		myPG.endShape();
	}

	void removeQuad(Quad q) {
		quads.remove(q);
		updateFlag = true;
	}

	void addQuad(Quad q) {
		quads.add(q);
		updateFlag = true;

	}

	PImage getTexture() {
	return tex;
	}
}