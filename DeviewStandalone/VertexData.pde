interface VertexData {
	float x(int i, int j);
	float y(int i, int j);
	void y(int i, int j, float newValue);
	void x(int i, int j, float newValue);
	//float z(int i, int j)
	//float z(int i, int j, float newValue)
	//preferably, do not use those
	/*
	float[] vec(int i, int j)
	float[] vec(int i, int j, float[] newValue)
	PVector vec(int i, int j)
	PVector vec(int i, int j, PVector newValue)
	*/
}

class VertexDataArray implements VertexData {
	int myNumComponents;
	int myVertexCountH, myVertexCountV;
	float[] myData;

	VertexDataArray(int theVertexCountH, int theVertexCountV, int theNumComponents) {
		myVertexCountH = theVertexCountH;
		myVertexCountV = theVertexCountV;
		myNumComponents = theNumComponents;
		myData = new float[myVertexCountH * myVertexCountV * theNumComponents];
	}

	float x(int i, int j) {
		return myData[(j * myVertexCountH + i) * myNumComponents];
	}

	float y(int i, int j) {
		return myData[(j * myVertexCountH + i) * myNumComponents + 1];
	}

	void x(int i, int j, float newValue) {
		myData[(j * myVertexCountH + i) * myNumComponents] = newValue;
	}

	void y(int i, int j, float newValue) {
		myData[(j * myVertexCountH + i) * myNumComponents + 1] = newValue;
	}

	float[] getData() {
		return myData;
	}

}