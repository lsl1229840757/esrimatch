package cn.esri.utils;

public class MathUtil {

    public static double getMaxInArray(double[] data){
        double max = Double.MIN_VALUE;
        for(int i = 0; i < data.length; i++){
            if(max >  data[i]){
                max = data[i];
            }
        }
        return max;
    }

}
