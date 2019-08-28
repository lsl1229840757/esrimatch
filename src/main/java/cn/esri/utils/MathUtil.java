package cn.esri.utils;

import java.util.ArrayList;
import java.util.List;

public class MathUtil {

    public static double getMaxInArray(double[] data){
        double max = Double.MIN_VALUE;
        for(int i = 0; i < data.length; i++){
            if(max <  data[i]){
                max = data[i];
            }
        }
        return max;
    }

    /**
     *
     * @param start 起始点
     * @param end 结束点
     * @param num 需要差多少个值
     * @return 返回差值后的list
     */
    public static List<Integer> linearFit(Integer start, Integer end, Integer num){

        int flag = 0;
        if(Math.random()>0.5){
            flag = 1;
        }else {
            flag = -1;
        }

        double delta =  (end - start + 0.0) / num;
        List<Integer> result = new ArrayList<>();
        for(int i=0; i<num; i++){
            result.add((int)(start+delta*i+Math.random()*delta*num*flag));
        }
        return result;
    }

    /**
     * 时间循环优先的预测
     * @param countArray1 开始时段，各个区域车辆数
     * @param countArray2 结束时段，各个区域车辆数
     * @param num 差值数目
     * @return
     */
    public static List<List<Integer>> linearFitTimeFirst(List<Integer> countArray1, List<Integer> countArray2, int num){
        List<List<Integer>> result = new ArrayList<>();
        List<List<Integer>> resultTransForm = new ArrayList<>();
        if(countArray1.size() != countArray2.size()){
            return result;
        }
        for(int i=0;i<countArray1.size();i++){
            List<Integer> tempt = linearFit(countArray1.get(i), countArray2.get(i), num);
            resultTransForm.add(tempt);
        }

        // 以列优先遍历
        for(int j=0;j<num;j++){
            List<Integer> resultTempt = new ArrayList<>();
            for(int i=0;i<resultTransForm.size();i++){
                resultTempt.add(resultTransForm.get(i).get(j));
            }
            result.add(resultTempt);
        }
        return result;
    }

}
