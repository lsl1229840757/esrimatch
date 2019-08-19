package cn.esri.utils;

import java.io.IOException;
import java.util.Collection;
import java.util.List;

import javax.servlet.http.HttpServletResponse;

import net.sf.json.JSONArray;
import net.sf.json.JSONObject;
import net.sf.json.JsonConfig;


/**
 *  JSON的帮助类
 */
public class JsonUtils<T> {


	public static JSONObject getJsonObjFromObj(Object obj,String[] excludes){
		JsonConfig jc = new JsonConfig();
		jc.setExcludes(excludes);
		JSONObject jb =  JSONObject.fromObject(obj,jc);
		return jb;
	}

	public JSONArray getJsonArrayFromList(List<T> objectList, String[] excludes){
		JSONArray jsonArray = new JSONArray();
		for(Object obj:objectList){
            JSONObject jsonObjFromObj = getJsonObjFromObj(obj, excludes);
            jsonArray.add(jsonObjFromObj);
        }
        return  jsonArray;
	}

}
