package cn.esri.pojo;

public class Taxi {

    private double logitude;

    private double latitude;

    public double getLogitude() {
        return logitude;
    }

    public void setLogitude(double logitude) {
        this.logitude = logitude;
    }

    public double getLatitude() {
        return latitude;
    }

    public void setLatitude(double latitude) {
        this.latitude = latitude;
    }

    @Override
    public String toString() {
        return "Taxi{" +
                "logitude=" + logitude +
                ", latitude=" + latitude +
                '}';
    }

    public Taxi(double logitude, double latitude) {
        this.logitude = logitude;
        this.latitude = latitude;
    }

    public Taxi() {
    }
}
