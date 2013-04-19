package edu.tum.cs.ias.knowrob.vis.items;

import javax.vecmath.Matrix4d;
import javax.vecmath.Vector3d;

import javax.vecmath.Vector3f;

import edu.tum.cs.ias.knowrob.vis.Canvas;

public class Platter extends Item {

	public Platter(float m00, float m01, float m02, float m03, float m10,
			float m11, float m12, float m13, float m20, float m21, float m22,
			float m23, float m30, float m31, float m32, float m33, float xdim,
			float ydim, float zdim) {
		
		super(m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31,
				m32, m33, xdim, ydim, zdim);
	}
	
	public Platter(Matrix4d pose, Vector3d dim){
		super(pose, dim);
	}
	
	@Override
	public void drawIt(Canvas c) {
		
		(new ConePrimitive(new Vector3f(0f, 0f, 0f),      new Vector3f(0f, 0f, 0.0165f), 0.066f)).draw(c); // lower part
		(new ConePrimitive(new Vector3f(0f, 0f, 0.0169f), new Vector3f(0f, 0f, 0.030f),  0.15f)).draw(c);	// upper part

	}

}
