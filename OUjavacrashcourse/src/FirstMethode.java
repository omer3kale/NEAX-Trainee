public class FirstMethode {
    public static void main(String[] args){

        System.out.println("Vor dem Methodenaufruf!");
        secondMethode(20, 20);
        System.out.println("Nach dem Methodenaufruf!");


    }

    public static void secondMethode(int number1, int number2){
        int x = 7; //number1
        int y = 33; //number2
        int result = x + y;
        System.out.println(result);
    }
}

