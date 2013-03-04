package edu.tum.cs.ias.knowrob.vis.items;

import javax.vecmath.Matrix4d;
import javax.vecmath.Vector3d;

import edu.tum.cs.ias.knowrob.vis.Canvas;

import javax.vecmath.Vector3f;

public class DrinkingGlass extends Item {


	public DrinkingGlass(float m00, float m01, float m02, float m03, float m10,
			float m11, float m12, float m13, float m20, float m21, float m22,
			float m23, float m30, float m31, float m32, float m33, float xdim,
			float ydim, float zdim) {
		
		super(m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31,
				m32, m33, xdim, ydim, zdim);
	}
	
	public DrinkingGlass(Matrix4d pose, Vector3d dim){
		super(pose, dim);
	}
	
	@Override
	public void drawIt(Canvas c) {
		
		(new ConePrimitive(new Vector3f(0f, 0f, 0f),    new Vector3f(0f, 0f, 0.005f), 0.04f)).draw(c); // foot
		(new ConePrimitive(new Vector3f(0f, 0f, 0f),    new Vector3f(0f, 0f, 0.05f),  0.005f)).draw(c);  // 
		(new ConePrimitive(new Vector3f(0f, 0f, 0.05f), new Vector3f(0f, 0f, 0.15f),  0.03f)).draw(c);  // glass
		
	}
}
