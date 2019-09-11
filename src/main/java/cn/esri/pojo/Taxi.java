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

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (obj == null)
            return false;
        if (getClass() != obj.getClass())
            return false;
        Taxi other = (Taxi) obj;
        if (latitude != other.latitude)
            return false;
        if (logitude != other.logitude)
            return false;

        return true;
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + (int)latitude+(int)logitude;
        return result;
    }
}
