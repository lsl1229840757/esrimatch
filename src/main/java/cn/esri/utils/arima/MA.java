package cn.esri.utils.arima;

import java.util.Vector;


public class MA {

	double[] stdoriginalData={};
	int q;
	ARMAMath armamath=new ARMAMath();

	public MA(double [] stdoriginalData,int q)
	{
		this.stdoriginalData=stdoriginalData;
		this.q=q;
	}
	public Vector<double[]> MAmodel()
	{
		Vector<double[]> v=new Vector<double[]>();
		v.add(armamath.getMApara(armamath.autocorGrma(stdoriginalData,q), q));
		return v;
	}
		
	
}
