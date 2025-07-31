public class dimension {

    public static void main(String[]args){

        String[][][] firstAndLastNameNumber =  new String[7][2][2];

        firstAndLastNameNumber[0][0][1] = "Rafa";
        firstAndLastNameNumber[0][1][0] = "Silva";
        firstAndLastNameNumber[0][1][1] = "27";
        firstAndLastNameNumber[1][0][0] = "Ricardo";
        firstAndLastNameNumber[1][1][0]= "Quaresma";
        firstAndLastNameNumber[1][1][1] = "7";
        firstAndLastNameNumber[2][0][0] = "Pascal";
        firstAndLastNameNumber[2][1][0] = "Nouma";
        firstAndLastNameNumber[2][1][1] = "21";
        firstAndLastNameNumber[3][0][0] = "Burak";
        firstAndLastNameNumber[3][1][0]= "Yilmaz";
        firstAndLastNameNumber[3][1][1] = "71";
        firstAndLastNameNumber[4][0][0] = "Semih";
        firstAndLastNameNumber[4][1][0] = "Kilicsoy";
        firstAndLastNameNumber[4][1][1] = "90";
        firstAndLastNameNumber[5][0][0] = "Orkun";
        firstAndLastNameNumber[5][1][0] = "Kökcü";
        firstAndLastNameNumber[5][1][1] = "10";
        firstAndLastNameNumber[6][0][0] = "Sergen";
        firstAndLastNameNumber[6][1][0] = "Yalcin";
        firstAndLastNameNumber[6][1][1] = "10";

        //Äusere For-Schleife: Zeilenindex => b
        //Innere For-Schleife: Spaltenindex => j
        //Verschachtelte Schleife: Nummerindex => k

        for(int b = 0; b < firstAndLastNameNumber.length; b++){
            for(int j = 0; j < firstAndLastNameNumber[b].length; j++){
                for(int k = 0; k < firstAndLastNameNumber[j].length; k++){
System.out.print(firstAndLastNameNumber[b][j][k] + " ");
                }
                System.out.println();
            }
        }
    }
}
