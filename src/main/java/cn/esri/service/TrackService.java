package cn.esri.service;

import net.sf.json.JSONArray;
import org.springframework.stereotype.Service;

import java.util.Date;

@Service
public interface TrackService {

    JSONArray getMilesAndCarrayingMiles(Date date);

}
