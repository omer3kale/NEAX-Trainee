public class Car {
    //Attribute/Eigenschaften
    private  String color;
    private String brand;
    private int horsePower;
    public int speed;


    public Car(){
        this.color = color;
        this.brand = brand;
        this.horsePower = horsePower;
    }

    //Methoden
    public void vinnn(int speed){
        System.out.println(speed);
    }

    public void vinnn(){
        System.out.println("VINNNTURIZM!");
    }

    public String getColor(){
     return color;
    }

    public void setColor(String color){
        this.color = color;
    }

}
